> some sample scripts and personal notes regarding VVenC usage.
>
> Scripts below use `vvencapp` for better control over encoding parameters. However, `libvvenc` in ffmpeg can be used as well and is generally recommonded ~~for better quality of life~~.

## VBR with 2 passes

```bash
#!/bin/bash

set -euo pipefail

# path = directory of this script
path="$(dirname "$0")"
# name = identifier of the script and its outputs
name="$(basename "$0" .sh)"
# io paths
input="$1"
output="${path}/${name}.266"
# slice options
slice_start=510
slice_duration=30
slice_arg=()
#slice_arg=(-ss "$slice_start" -t "$slice_duration")
# video properties
size=1920x1080
frame_rate="24000/1001" # 23.976
pix_fmt="yuv420p"
# VMAF threads (should leave some for 266 decoding)
vmaf_threads=$(($(nproc) / 2))
# mailto address, leave empty to use desktop notifications instead.
mailto=""
# encoder params
params=(
	--y4m 1
	--preset fast -b 3000k --passes 2 --rcstatsfile stats.json -rs 4
	--profile main_10 --tier high --threads 2 --qpa 0
)

mail_error() {
    local subject="$name: Error occurred"
    local body="An error occurred on line $1 while executing the script $0."
	if [ -n "$mailto" ]; then
		echo "$body" | mail -s "$subject" "$mailto"
	else
		notify-send "$subject" "$body"
	fi
}

mail_success() {
    local subject="$name: Completed successfully"
    local body
    body=$(printf "VMAF: %s\nSize in bytes: %s\n" \
				 "$(jq '.pooled_metrics.vmaf' "${path}/${name}.vmaf.json")" \
				 "$(stat -c%s "$output")")
    if [ -n "$mailto" ]; then
		echo "$body" | mail -s "$subject" "$mailto"
	else
		notify-send "$subject" "$body"
	fi
}

trap 'mail_error $LINENO' ERR

decode() {
	ffmpeg -hide_banner -nostdin \
		-hwaccel auto -r "$frame_rate" "${slice_arg[@]}" -i "$1" \
		-pix_fmt "$pix_fmt" -f yuv4mpegpipe - 2>/dev/null
}

pass1() {
	vvencapp -i "$1" "${params[@]}" --pass 1 -o /dev/null
}

pass2() {
	vvencapp -i "$1" "${params[@]}" --pass 2 -o "$2"
}

calc_vmaf() {
	ffmpeg -hide_banner -nostdin \
	-hwaccel auto -r "$frame_rate" "${slice_arg[@]}" -i "$1" \
	-r "$frame_rate" -i "$2" \
	-filter_complex "[0:v][1:v]libvmaf=log_fmt=json:log_path=${path}/${name}.vmaf.json:n_threads=$vmaf_threads" \
	-f null -
}

decode "$input" | pass1 "-"
decode "$input" | pass2 "-" "$output"
calc_vmaf "$input" "$output"

mail_success
```

- script explained:
  - `input="$1"`: The source video file is passed as the first argument to the script.

  - `slice_start` and `slice_duration`: Define the start time and duration of the video slice to be processed. Uncomment the `slice_arg` line to enable slicing.

  - `mailto=""` requires capability to send emails from command line, i.e. a **MTA** (Mail Transfer Agent) must be installed and configured in the system. Leave empty to use notify-send to send desktop notifications instead.

- encoder parameters explained:
  - `-b 3000k`: Target bitrate. The output bitrate could be significantly different (commonly 1/2 to 1/3 lower than target).

  - `-rs 4` or `--refreshsec 4`: Intra period/refresh in seconds. Higher for better compression, lower for better seeking.

  - `--profile main_10`: 10-bit Main profile. Change to `main` for 8-bit encoding.

  - `--tier high`: High tier for better quality at higher bitrates.

  - `--threads 2`: Generally fewer threads yield better encoding quality yet slower speed. The maximum number of parallel frames is determined automatically according to frame size, and might be lower than the thread count specified here.

  - `--qpa 0`: Disable "perceptually motivated QP adaptation", do so if you care about quality metrics or compress with archival purposes.

  - `-q` or `--qp` will be ignored in VBR mode even if specified.

## CQP

```bash
#!/bin/bash

set -euo pipefail

# path = directory of this script
path="$(dirname "$0")"
# name = identifier of the script and its outputs
name="$(basename "$0" .sh)"
# io paths
input="$1"
output="${path}/${name}.266"
# slice options
slice_start=510
#slice_arg=(-ss "$slice_start" -t "$slice_duration")
slice_duration=30
slice_arg=()
# video properties
size=1920x1080
frame_rate="24000/1001" # 23.976
pix_fmt="yuv420p"
# VMAF threads (should leave some for 266 decoding)
vmaf_threads=$(($(nproc) / 2))
# mailto address
mailto=""
# encoder params
params=(
    --y4m 1
	--preset fast -q 16 -rs 4
	--profile main_10 --tier high --qpa 0
)

mail_error() {
    local subject="$name: Error occurred"
    local body="An error occurred on line $1 while executing the script $0."
	if [ -n "$mailto" ]; then
		echo "$body" | mail -s "$subject" "$mailto"
	else
		notify-send "$subject" "$body"
	fi
}

mail_success() {
    local subject="$name: Completed successfully"
    local body
    body=$(printf "VMAF: %s\nSize in bytes: %s\n" \
				  "$(jq '.pooled_metrics.vmaf' "${path}/${name}.vmaf.json")" \
				  "$(stat -c%s "$output")")
    if [ -n "$mailto" ]; then
		echo "$body" | mail -s "$subject" "$mailto"
	else
		notify-send "$subject" "$body"
	fi
}

trap 'mail_error $LINENO' ERR

decode() {
	ffmpeg -hide_banner -nostdin \
		-hwaccel auto -r "$frame_rate" "${slice_arg[@]}" -i "$1" \
		-pix_fmt "$pix_fmt" -f yuv4mpegpipe - 2>/dev/null
}

encode() {
	vvencapp -i "$1" "${params[@]}" -o "$2"
}

calc_vmaf() {
	ffmpeg -hide_banner -nostdin \
	-hwaccel auto -r "$frame_rate" "${slice_arg[@]}" -i "$1" \
	-r "$frame_rate" -i "$2" \
	-filter_complex "[0:v][1:v]libvmaf=log_fmt=json:log_path=${path}/${name}.vmaf.json:n_threads=$vmaf_threads" \
	-f null -
}

decode "$input" | encode "-" "$output"
calc_vmaf "$input" "$output"

mail_success
```

- script explained:

  same as above.

- encoder parameters explained:
  - `-q 16`: Quantization Parameter, lower qp means better quality, larger file size and slower encoding speed.

  - `-rs 4 --profile main_10 --tier high --qpa 0`: Same as above.

  - `--fga 0`: Disable "film grain analysis" (default disabled). fga in current version of VVenC (1.13.1) is kinda buggy and may lead to crashes in CQP mode. Enable with caution.

  - `--maxrate` or `-m` can be used to set a maximum bitrate. However, `--qpa 1` is required for this to take effect. With these two parameters enabled, this certain pattern of rc theoretically becomes **CQF** (Constant Quality Factor) and behaves noticeably differently comparing to CQP.

## References

- [Usage - fraunhoferhhi/vvenc Wiki](https://github.com/fraunhoferhhi/vvenc/wiki/Usage)
