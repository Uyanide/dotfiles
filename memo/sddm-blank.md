## What

> kernel: `Linux 6.17.7-5-cachyos`
> nvidia-driver: `cachyos-v3/nvidia-open-dkms 580.105.08-3`
> sddm: `cachyos-v3/sddm 0.21.0-8`

SDDM shows a blank screen (only with mouse cursor and tty cursor) after booting into graphical target, but starts normally after restarting the SDDM service.

## Why

SDDM starts before the NVIDIA driver is fully initialized, causing the greeter to fail to display properly.

<details>
<summary>evidence</summary>

- Logs after booting (many unrelated lines omitted):

```log
...(maybe unrelated lines)...
systemd[1]: Started Simple Desktop Display Manager.
kernel: NVRM: testIfDsmSubFunctionEnabled: GPS ACPI DSM called before _acpiDsmSupportedFuncCacheInit subfunction = 11.
kernel: bridge: filtering via arp/ip/ip6tables is no longer available by default. Update your scripts to load br_netfilter if you need this.
sddm[878]: Initializing...
sddm[878]: Starting...
sddm[878]: Logind interface found
sddm[878]: Adding new display...
sddm[878]: Loaded empty theme configuration
sddm[878]: Xauthority path: "/run/sddm/xauth_yQfUmV"
sddm[878]: Using VT 2
sddm[878]: Display server starting...
sddm[878]: Writing cookie to "/run/sddm/xauth_yQfUmV"
sddm[878]: Running: /usr/bin/X -nolisten tcp -background none -seat seat0 vt2 -auth /run/sddm/xauth_yQfUmV -noreset -displayfd 16
systemd[1]: Starting Authorization Manager...
kernel: nvidia-modeset: WARNING: GPU:0: Unable to read EDID for display device DP-4
kernel: nvidia-modeset: WARNING: GPU:0: Unable to read EDID for display device DP-4
systemd[1]: Started Authorization Manager.
kernel: [drm] Initialized nvidia-drm 0.0.0 for 0000:01:00.0 on minor 0
systemd[1]: Started Power Profiles daemon.
systemd[1]: Reached target Graphical Interface.
kernel: nvidia 0000:01:00.0: [drm] Cannot find any crtc or sizes
systemd[1]: Startup finished in 5.795s (firmware) + 7.387s (loader) + 1.169s (kernel) + 2.477s (initrd) + 3.421s (userspace) = 20.251s.
systemd[1]: Starting Load/Save Screen Backlight Brightness of backlight:nvidia_0...
systemd[1]: Finished Load/Save Screen Backlight Brightness of backlight:nvidia_0.
sddm[878]: Setting default cursor
sddm[878]: Running display setup script  "/usr/share/sddm/scripts/Xsetup"
sddm[878]: Display server started.
sddm[878]: Socket server starting...
sddm[878]: Socket server started.
sddm[878]: Loading theme configuration from "/usr/share/sddm/themes/sugar-candy/theme.conf"
sddm[878]: Greeter starting...
sddm-helper[1006]: [PAM] Starting...
sddm-helper[1006]: [PAM] Authenticating...
sddm-helper[1006]: [PAM] returning.
sddm-helper[1006]: pam_unix(sddm-greeter:session): session opened for user sddm(uid=950) by (uid=0)
systemd[1]: Created slice User Slice of UID 950.
systemd[1]: Starting User Runtime Directory /run/user/950...
systemd-logind[773]: New session 'c1' of user 'sddm' with class 'greeter' and type 'x11'.
systemd[1]: Finished User Runtime Directory /run/user/950.
systemd[1]: Starting User Manager for UID 950...
(systemd)[1015]: pam_warn(systemd-user:setcred): function=[pam_sm_setcred] flags=0x8002 service=[systemd-user] terminal=[] user=[sddm] ruser=[<unknown>] rhost=[<unknown>]
(systemd)[1015]: pam_unix(systemd-user:session): session opened for user sddm(uid=950) by sddm(uid=0)
systemd-logind[773]: New session '1' of user 'sddm' with class 'manager-early' and type 'unspecified'.
systemd[1015]: Queued start job for default target Main User Target.
systemd[1015]: Created slice User Application Slice.
systemd[1015]: Startup finished in 139ms.
systemd[1]: Started User Manager for UID 950.
systemd[1]: Started Session c1 of User sddm.
sddm-helper[1006]: Writing cookie to "/tmp/xauth_FfqCDd"
sddm-helper[1006]: Starting X11 session: "" "/usr/bin/sddm-greeter --socket /tmp/sddm-:0-HQDlHk --theme /usr/share/sddm/themes/sugar-candy"
sddm[878]: Greeter session started successfully
...(maybe unrelated lines)...
```

Although the greeter session started successfully, it is not able to display anything due to `nvidia 0000:01:00.0: [drm] Cannot find any crtc or sizes`, resulting in a blank screen.

- Logs after restarting sddm.service:

```log
...(maybe unrelated lines)...
systemd[1]: Started Simple Desktop Display Manager.
sudo[1123]: pam_unix(sudo:session): session closed for user root
sddm[1150]: Initializing...
sddm[1150]: Starting...
sddm[1150]: Logind interface found
sddm[1150]: Adding new display...
sddm[1150]: Loaded empty theme configuration
sddm[1150]: Xauthority path: "/run/sddm/xauth_XyLFOm"
sddm[1150]: Using VT 1
sddm[1150]: Display server starting...
sddm[1150]: Writing cookie to "/run/sddm/xauth_XyLFOm"
sddm[1150]: Running: /usr/bin/X -nolisten tcp -background none -seat seat0 vt1 -auth /run/sddm/xauth_XyLFOm -noreset -displayfd 16
sddm[1150]: Setting default cursor
sddm[1150]: Running display setup script  "/usr/share/sddm/scripts/Xsetup"
sddm[1150]: Display server started.
sddm[1150]: Socket server starting...
sddm[1150]: Socket server started.
sddm[1150]: Loading theme configuration from "/usr/share/sddm/themes/sugar-candy/theme.conf"
sddm[1150]: Greeter starting...
sddm-helper[1217]: [PAM] Starting...
sddm-helper[1217]: [PAM] Authenticating...
sddm-helper[1217]: [PAM] returning.
sddm-helper[1217]: pam_unix(sddm-greeter:session): session opened for user sddm(uid=950) by (uid=0)
systemd-logind[773]: New session 'c2' of user 'sddm' with class 'greeter' and type 'x11'.
systemd[1]: Started Session c2 of User sddm.
sddm-helper[1217]: Writing cookie to "/tmp/xauth_Qghqzs"
sddm-helper[1217]: Starting X11 session: "" "/usr/bin/sddm-greeter --socket /tmp/sddm-:0-YHEwdP --theme /usr/share/sddm/themes/sugar-candy"
sddm[1150]: Greeter session started successfully
...(maybe unrelated lines)...
```

</details>

## How

The key is to avoid the timing race between nvidia init and sddm start. There are multiple ways to achieve this, two for example:

### Early KMS:

As described in [Hyprland WIKI](https://wiki.hypr.land/Nvidia/#early-kms-modeset-and-fbdev), this ensures that the NVIDIA driver is loaded in the initramfs and is ready before SDDM starts.

1.  enable `modset` in kernel parameters (e.g. in `/etc/default/grub`):

```
GRUB_CMDLINE_LINUX_DEFAULT="... nvidia-drm.modeset=1 ..."
```

and update grub:

```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

2. specify early loaded modules in `/etc/mkinitcpio.conf`:

```
MODULES=(... nvidia nvidia_modeset nvidia_uvm nvidia_drm ...)
```

and regenerate initramfs:

```sh
sudo mkinitcpio -P
```

3. reboot

### Delay starting SDDM:

`sudo systemctl edit sddm.service`

```ini
[Service]
ExecStartPre=/bin/sleep 2
```

should also do the trick, but less elegant.
