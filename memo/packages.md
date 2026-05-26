set -o pipefail
awk '
/^<!-- update-full-list:start$/ { grab=1; next }
/^update-full-list:end -->$/ { exit }
grab
' "$0" \
| bash -s -- "$0"
exit $?

<!-- update-full-list:start

set -euo pipefail

script_path="$(readlink -f -- "$1")"
tmp_file="$(mktemp -- "${script_path}.XXXXXX")"
trap 'rm -f -- "$tmp_file"' EXIT
pkgs="$(yay -Qeq | LC_ALL=C sort)"

awk -v pkgs="$pkgs" '
$0 == "## Full list" {
	print
	in_header = 1
	next
}
in_header && $0 == "```" {
	print
	print pkgs
	in_header = 0
	in_block = 1
	next
}
in_header { print; next }
in_block {
	if ($0 == "```") {
		print
		in_block = 0
	}
	next
}
{ print }
END {
	if (in_header || in_block) {
		print "ERROR: Full list section is malformed (missing closing ```)" > "/dev/stderr"
		exit 1
	}
}
' "$script_path" > "$tmp_file"

mv -- "$tmp_file" "$script_path"
echo "Updated Full list in: $script_path"

update-full-list:end -->

> [!NOTE]
> The gibberish above is **NOT** meant to be copy-pasted into the terminal. It is a script that updates the [Full list](#full-list) section below, and should be run as:
>
> ```bash
> bash /path/to/dotfiles/memo/packages.md
> ```

## Notes

|           |                              |
| --------- | ---------------------------- |
| alass     | Subtitle sync; used in mpv   |
| axel      | CLI download accelerator     |
| figlet    | Draw large letters           |
| foliate   | GTK eBook reader             |
| gearlever | AppImage manager             |
| gping     | Ping with better looking TUI |
| jp2a      | JPEG to ASCII                |
| nethogs   | Network top                  |
| picard    | Music tagger (MusicBrainz)   |
| toilet    | Better FIGlet                |
| wev       | Debug wayland events         |
| yad       | Fork of zenity               |
| zenity    | Display dialog boxes via cli |

## Some useful commands

Show packages sorted by size, with a preview of their info:

```bash
expac -H M '%m\t%n' \
| sort -hr \
| fzf --delimiter='\t' --with-nth=1,2 --multi \
		--preview 'yay -Qi {2}' \
		--preview-window='right,70%,wrap'
```

Update the list below:

```bash
bash /path/to/dotfiles/memo/packages.md
```

## Full list

```
7zip
aarch64-linux-gnu-gcc
alacritty
alass
arch-install-scripts
archiso
archlinux-contrib
archlinuxcn-keyring
ark
av1an
awww
axel
azure-cli
base
base-devel
bash-completion
bat
bc
bind
blueman
bluez-tools
bluez-utils
bootconfig
bpf
bpftrace
bridge-utils
brightnessctl
bsd-games
btop
btrfs-assistant
btrfs-progs
busybox
cachyos-keyring
cachyos-mirrorlist
cachyos-rate-mirrors
cachyos-v3-mirrorlist
cachyos-v4-mirrorlist
catppuccin-gtk-theme-mocha
cava
cbonsai
chafa
chaotic-keyring
chaotic-mirrorlist
chromium
chwd
claude-code
cli11
cloc
cmake
cmatrix-git
composer
compsize
corectrl
cowfortune
cpptrace
cpu-x
cpupower
cuda
curl
cython
deno
devtools
digital
dnsmasq
docker
docker-compose
dolphin
dotnet-sdk
doxygen
drm-info
dwarfs
ed
efibootmgr
elisa
ethtool
euphonica-git
eww
expac
extra-cmake-modules
eza
fastfetch
fcitx5
fcitx5-chinese-addons
fcitx5-configtool
fcitx5-gtk
fcitx5-mozc
fcitx5-pinyin-moegirl
fcitx5-pinyin-zhwiki
fcitx5-qt
fd
fdkaac
ffmpeg-full
ffms2
ffnvcodec-headers
ffvship
figlet
filelight
fish
fisher
flatpak
flutter-bin
fnm
foliate
font-manager
fontforge
foot
frei0r-plugins
fssimu2
fuzzel
fzf
gamemode
gdb
gdu
gearlever
geoclue
geoipupdate
ghostty
gifski
gimp
git
git-filter-repo
git-sizer
github-cli
glaze
gnome-keyring
gnome-text-editor
go
gpac
gping
gradia
gradle
grim
grub
grub-btrfs
gst-plugins-bad
gucharmap
gvfs-smb
gwenview
handbrake
helix
hmcl
htop
hwinfo
hyperfine
hyperv
hypridle
hyprlock
hyprpicker
hyprpolkitagent
hyprsunset
hyprutils
imagemagick
inetutils
intel-gpu-tools
intel-media-sdk
intel-speed-select
intel-ucode
inxi
iperf3
jdk-openjdk
jdk17-openjdk
jdk21-graalvm-ee-bin
jetbrains-toolbox
jp2a
jujutsu
kalk
kate
kcalendarcore
kcolorchooser
kcontacts
kcpuid
kdav
kdenlive
kdiskmark
kdoctools
kid3
kitty
kmscon
konsole
kpeople
kplotting
krdc
ktexttemplate
kvantum
lazygit
lib32-nvidia-utils
lib32-opencl-nvidia
lib32-vulkan-icd-loader
lib32-vulkan-intel
libc++
libdbusmenu-lxqt
libguestfs
libreoffice-still-zh-cn
libspng
libva-intel-driver
libva-nvidia-driver
libva-utils
libvips
libvirt
lightdm
linux-cachyos
linux-cachyos-headers
linux-firmware
linuxqq
llama.cpp-cuda-git
lldb
llmfit-bin
localsend
lolcat
lua-socket
luarocks
lutris
lzip
magiskboot-bin
man-db
man-pages
mangohud
matugen
mesa
meson
mkvtoolnix-cli
modprobed-db
moonlight-qt
moreutils
mpc
mpd
mpd-mpris
mpv-full
mpv-mpris
msedit
namcap
nasm
nautilus
nautilus-share
nethogs
network-manager-applet
networkmanager
networkmanager-openvpn
nfs-utils
niri
nmap
nordvpn-bin
noto-fonts-cjk
nvidia-container-toolkit
nvidia-open-dkms
nvidia-prime
nvidia-settings
nvidia-utils
nvme-cli
nvtop
nwg-look
oavif-git
obs-studio
obsidian
okular
opam
openbsd-netcat
opencl-headers
opencl-nvidia
openlist-bin
openssh
os-prober
pacman-contrib
pacman-utils
pamixer
pandoc-bin
papirus-icon-theme
perf
perl-file-homedir
perl-image-exiftool
perl-yaml-tiny
php
picard
pipes.c
pipewire-alsa
plasma-meta
polkit-gnome
power-profiles-daemon
protonplus
pwvucontrol
pyside6
python-adblock
python-aiohttp
python-argcomplete
python-chardet
python-colorthief
python-darkdetect
python-fonttools
python-huggingface-hub
python-lxml
python-opencv-cuda
python-pygments
python-pyqt6
python-pytest
python-pytz
python-virtualenv
python-watchdog
python-yaml
qbittorrent-enhanced
qdiskinfo
qemu-full
qemu-user-static
qemu-user-static-binfmt
qt5-graphicaleffects
qt5-quickcontrols
qt5-quickcontrols2
qt5-wayland
qt6-3d
qt6-datavis3d
qt6-doc
qt6-examples
qt6-graphs
qt6-grpc
qt6-httpserver
qt6-languageserver
qt6-lottie
qt6-networkauth
qt6-quick3dphysics
qt6-quickeffectmaker
qt6-remoteobjects
qt6-scxml
qt6-serialbus
qt6ct
qtcreator
qtrvsim
quickshell-git
qutebrowser
rclone
reflector
resources
riscv64-linux-gnu-binutils
riscv64-linux-gnu-gcc
rsync
ruff
rustdesk
rustup
scnlib
scrcpy
sd
seahorse
shellcheck-bin
sl
slurp
snapper
solaar
spicetify-cli
spicetify-marketplace-bin
spike
spotify
squashfs-tools-ng
sshfs
starship
steam
stow
sudo
sunshine
sushi
svt-av1-hdr-git
sysbench
systemc2.3.4
tailscale
tcpdump
telegram-desktop
terminus-font
texlive-basic
texlive-bibtexextra
texlive-binextra
texlive-context
texlive-fontsextra
texlive-fontsrecommended
texlive-fontutils
texlive-formatsextra
texlive-games
texlive-humanities
texlive-latex
texlive-latexextra
texlive-latexrecommended
texlive-luatex
texlive-mathscience
texlive-metapost
texlive-music
texlive-pictures
texlive-plaingeneric
texlive-pstricks
texlive-publishers
texlive-xetex
thunderbird
tigervnc
tk
tmon
tmux
toilet
tombi
trash-cli
tree
ttf-comic-shanns-nerd
ttf-jetbrains-mono-nerd
ttf-lxgw-wenkai
ttf-lxgw-wenkai-tc
ttf-maplemono-nf-cn
ttf-meslo-nerd
ttf-noto-sans-cjk-vf
ttf-symbola
tty-clock
turbostat
unarchiver
unrar
usbip
uv
valgrind
vapoursynth-plugin-vship-cuda-git
ventoy-bin
vesktop-bin
vicinae
vim
virt-install
virt-manager
visual-studio-code-bin
vk-hdr-layer-kwin6-git
vlc
vulkan-extra-layers
vulkan-extra-tools
vulkan-gfxstream
vulkan-headers
vulkan-intel
vulkan-mesa-implicit-layers
vulkan-mesa-layers
vulkan-swrast
vvenc
wallreel
waydroid
waydroid-helper
waypaper
wev
wezterm
wf-recorder-git
wget
whisper.cpp-model-large-v3-turbo
wine
winetricks
wireshark-qt
wl-clipboard
wl-mirror
wlogout
wlsunset
words
wqy-bitmapfont
wqy-microhei
wqy-zenhei
x86_energy_perf_policy
xclip
xdg-desktop-portal-gnome
xdg-desktop-portal-gtk
xone-dkms
xorg-bdftopcf
xorg-font-util
xorg-iceauth
xorg-mkfontscale
xorg-server-devel
xorg-server-xephyr
xorg-server-xnest
xorg-server-xvfb
xorg-sessreg
xorg-smproxy
xorg-x11perf
xorg-xbacklight
xorg-xcmsdb
xorg-xcursorgen
xorg-xdriinfo
xorg-xev
xorg-xgamma
xorg-xhost
xorg-xinit
xorg-xinput
xorg-xkbevd
xorg-xkbutils
xorg-xkill
xorg-xlsatoms
xorg-xlsclients
xorg-xpr
xorg-xrefresh
xorg-xsetroot
xorg-xvinfo
xorg-xwininfo
xpadneo-dkms
xwayland-satellite
yad
yay
yay-debug
yazi
yt-dlp
zellij
zen-browser-bin
zenity
zig
zig0.15-bin
zoxide
zram-generator
zsh
zsh-antidote
```
