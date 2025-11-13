> from [linux-surface wiki](https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup)

### Setting your clock to localtime to fix dual-boot time skew

Windows stores the hardware clock as localtime, whereas Linux and other OS-es typically use UTC. When dual-booting this can
cause the time to skew. The easiest way to fix this is by configuring Linux to use localtime:

```bash
sudo timedatectl set-local-rtc 1
```
```bash
sudo hwclock --systohc --localtime
```
