if not set -q fetch_logo_type
    set -g fetch_logo_type kitty
end

if test $(pgrep -u $USER -x kitty | wc -l) -ge 2
    set -g no_fetch
end

spotify-lyrics completion fish | source

alias gduu "sudo gdu -i /media/Alpha -i /media/Beta -i /media/Gamma -i /.snapshots -i /home/.snapshots /"
