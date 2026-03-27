记录一些在安装 LFS 时踩的一些坑和其他值得一提的事情.

> [!IMPORTANT]
>
> 本文中的 LFS 仅指代 12.4 SysV 和 13.0 Systemd 版本.

> [!IMPORTANT]
>
> 部分链接可能会随 LFS 更新而过时, 请以 LFS 官方文档为准.

## 总览

### 耗时

除去受硬件性能影响的编译耗时, 构建可以启动的 LFS 系统的耗时大约为数小时. 其实还是蛮快的, 毕竟需要处理的软件包只有百个以内.

然而, 如果想要构建可以日常使用的 LFS 系统, 包括桌面环境, 网络支持, 以及一些常用工具和应用的话, 那么耗时将会大幅增加, 可能需要数十小时. 最终需要处理的包的数量会达到数百个, 横跨 BLFS, GLFS, SLFS 等多本书, 也包括一些书中没有但确实需要的包 (如 go 官方工具链, dracut 等). 如果自身不够熟练且不巧遇到很多问题的话, 上百小时也是有可能的.

### 自动化

LFS 官方有提供一套名叫 [ALFS](https://www.linuxfromscratch.org/alfs/) 的自动化构建脚本, 但我没有使用过, 因此不做讨论.

不过, 我自己也有一套半自动构建 BLFS 包的脚本, 确实帮我节省了很多时间, 大致思路是这样的:

1. **获取书的源码.** 可以是完整的 HTML 文件包, 如 [BLFS 下载界面](https://www.linuxfromscratch.org/blfs/download.html)提供的; 也可以是更纯粹的 XML 源码, 如 [BLFS 仓库镜像](https://github.com/lfs-book/blfs).
2. **拆分包名.** 大体上可以将每一个文件视作一个包, 但也有的文件是同一类包的组合, 如 [Python Modules](https://www.linuxfromscratch.org/blfs/view/stable-systemd/general/python-modules.html) 和 [Perl Modules](https://www.linuxfromscratch.org/blfs/view/stable-systemd/general/perl-modules.html), 对于这些文件需要特殊处理.
3. **用户选择包.** 选择一个包开始配置.
4. **解析包的信息.** 可以分为几个部分:
   - **依赖关系.** 解析 Required, Recommended, Optional 三个类别的依赖; 随后判断每个依赖的安装来源, 书中是否有涉及; 最后需要根据包名定位对应依赖所在的文件.
   - **构建命令.** 解析代码块并区分命令类型, 如是否可选, 是否需要 root.
   - **安装的文件.** 可作为补充信息, 也可以用来判断某个包是否已经安装过.
5. **交互式配置.** 需要让用户确认是否安装, 需要跟随哪些依赖, 以及每个代码块是否执行, 是否以 root 执行, 是否需要修改等等. 这也是我认为 BLFS 从根本上无法完全自动化构建的原因 - 可选项实在太多了, 脚本难以替用户做所有决定.
6. **递归解析依赖.** 根据解析出的依赖关系, 递归地解析其他包. 对于可能出现的循环依赖需要特殊处理; 已配置的包也需要记录以防重复安装.
7. **生成构建脚本.** 根据所有配置好的包生成用于构建的单个 shell 脚本. 生成的脚本包含下载命令, 解压命令, 以及书中涉及的和用户配置的各种命令等等. 之所以不直接安装而是生成脚本, 一是允许用户再细调各种操作, 二是分离配置和构建过程, 二者甚至不需要在同一台机器上运行, 同时也能降低配置错误造成的风险.
8. **运行.** 只需要将上一步的产物拿到 LFS 环境中运行即可. 如果遇到错误, 可以在脚本中删除已成功安装的包, 调整后重新运行. 这么做还有一个好处, 就是可以在耗时的构建操作进行的同时配置下一个 (或一批) 要安装的软件包. 异步构建? 大致可以这么理解 :)

因为我的~~屎山~~代码实在太丑陋所以这里没有任何链接, 但只要有一定经验相信实现起来也不怎么困难.

### NVIDIA

是的, 在 LFS 中使用 NVIDIA 专有驱动是完全可能的, 并且并不会遇到太大的阻碍. NVIDIA 专有驱动的安装指引在 [GLFS 中](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/drivers-NVIDIA.html)有详细说明. 但其依赖众多, 其中包括很多 BLFS 和 GLFS 中的软件包. 因此不必心急, 可以先按需安装 BLFS 中的其他包, 等到需要 [Mesa](https://www.linuxfromscratch.org/blfs/view/stable-systemd/x/mesa.html) 作为依赖时再去 GLFS 中安装 NVIDIA 驱动, 这将会轻松不少.

更多详细内容将会在后文对应章节中涉及.

### 辅助工具

#### targo

如果计划手动编译软件包, 有不少操作将会重复的, 例如 `tar -xf`, `cd`, `rm -rf` 等, 为此可以写一个小脚本节省时间:

```bash
#!/bin/bash

set -euo pipefail

[ -z "${1:-}" ] && { echo "Usage: $0 <tarball>"; exit 1; }

tarball=$(realpath "$1")
top_dir=$(tar -tf "$tarball" | sed -e 's/^\.\///' -e '/^pax_global_header$/d' \
    | cut -d/ -f1 | sort -u)

if [ "$(echo "$top_dir" | wc -l)" -ne 1 ]; then
    echo "Error: Tarball must contain a single top-level directory."
    exit 1
fi

if [[ -z "$top_dir" || "$top_dir" == "." || "$top_dir" == ".." || "$top_dir" == /* ]]; then
    echo "Error: Unsafe top-level directory name: '$top_dir'"
    exit 1
fi

extract_dir="$(pwd)/$top_dir"

cleanup() {
    echo "Cleaning up '$extract_dir'..."
    rm -rf "$extract_dir"
}
trap cleanup EXIT

tar -xf "$tarball"

if [ ! -d "$extract_dir" ]; then
    echo "Error: Expected directory not found: '$extract_dir'"
    exit 1
fi

echo "Spawning shell in '$top_dir'. Type 'exit' to finish and cleanup."
cd "$extract_dir"
bash
```

它的作用是解压一个只含有一个顶层目录的 tarball, cd 进入解压后得到的目录, 生成一个 shell, 并在这个 shell 退出时清理先前解压得到的文件.

#### xgo

除上文的 [targo](#targo) 外, [本仓库](https://github.com/Uyanide/dotfiles) 中还有一个功能更丰富的版本 [xgo](https://github.com/Uyanide/dotfiles/blob/main/config/scripts/.local/scripts/xgo), 使用 Python 编写, 适合在 BLFS 中使用.

更多小脚本将会在后文对应章节中涉及.

### 通用建议

#### tmpfs

先在目标位置挂载 tmpfs 再解压文件. 编译期间会进行高频的硬盘 IO, 将此过程放到内存上可以减少硬盘损耗, 也可以稍稍加速. 不过有几点需要注意:

- 部分包(不在少数)的部分测试会依赖文件系统特性. 如 [Python-3.14.3](https://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter08/Python.html) 的 `test_file` 测试, 如果构建目录为 tmpfs, 则会因为缓冲区大小与预期不符而出现 `AssertionError` 断言错误, 而缓冲区大小由底层文件系统的块大小决定, 因此 tmpfs 的环境差异会导致测试失败.

- OOM. 多核编译本就需要耗费大量内存, 例如 [Gentoo 手册](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage)中建议为每个 job 预留至少 2 GiB 内存, 而复杂的包的构建目录体积也会随着构建过程膨胀, 二者共同作用更显内存紧张. 倘若真的触及上限, 如果有 swap 则会使用到硬盘, 这和使用 tmpfs 最初的目的相背; 如果触发 OOM Killer 更是会直接导致编译失败. 因此编译大包时还是建议老老实实用硬盘.

- tmpfs 的环境差异也会导致少数包在 configure 阶段就出现问题. 这属于少数特例, 不过多说明~~主要是忘了具体是哪个包了:/~~

#### 其他

1. 通常来说, 应该 (或者说请务必) 在编译和安装一个包后完全删除它的目录, 仅有少数例外:
   - linux (保留构建树可以缩短重新构建耗时, 或至少保留 `.config` 便于复原配置)
   - blfs-bootscripts (对于 blfs-sysv)
   - blfs-systemd-units (对于 blfs-systemd)

   注意一些需要多次编译的包, 例如 gcc, 也应该在每次编译与安装后完全删除目录.

2. 通常来说, 建议将所有相关的 tarball 和 patch 下载在同一个目录中, 并且将 tarball 也解压在这个目录中. 如果目录层级与该默认情况不一致的话必须修改 LFS 书中提供的命令中对应的相对路径.

3. 如果和我一样使用 UEFI 引导, 那么大概率将会在安装 GRUB 时第一次接触 BLFS. 和 LFS 不同, BLFS 中大多数包都是可选的, 具体安装什么由依赖关系决定. 一个包可能会依赖其他包, 这些依赖分为三个层级:
   - **Required** 是必要的依赖;
   - **Recommended** 通常建议当成 Required 看待, 因为书中大多数情况会假设读者会装这些包, 如果决定不装必须明确其功能与影响, 也可能需要相应地调整书中给出的命令, 不能无脑 CV;
   - **Optional**: 酌情安装, 很多时候是文档或测试相关的依赖.

4. 如果想要的包在 LFS 和 BLFS 包中都没有, 例如 fish、libglvnd、flatpak 等, 不妨先检查 [GLFS](https://www.linuxfromscratch.org/glfs/) 和 [SLFS](https://www.linuxfromscratch.org/slfs/) 或同系列的其他书中是否有涉及, 如果有的话将节约很多学习和试错成本.

   另外也可以看其他发行版是怎么打包这些软件的, 例如 [Archlinux 官方构建仓库](https://gitlab.archlinux.org/archlinux/packaging/packages)中的 PKGBUILD 能为构建流程提供很多参考.

5. 或许反直觉的一点是, LFS 书实在写得太优秀了, 几乎涵盖了所有可能会遇到的问题, 因此如果只是对着一个个代码块无脑复制, 粘贴, 运行, 可能并不会学到太多有用的东西, 而只是白白浪费了时间; 同时, 最终得到的极有可能是一个标准到可以用一个预先编写的通用脚本完整构建的 "制式" Linux 系统. 所以, 如果真的打算学点东西而不只是得到一个可用的 Linux 系统的话, 思考和耐心缺一不可. 否则为什么要想不开折磨自己呢, 数百个成熟的发行版, 总有一个已经能满足需求 :)

## LFS

以下内容按照对应章节划分:

### 2.6. Setting the $LFS Variable and the Umask

`$LFS` 变量很重要! 建议写到 Host 的 `/root/.bash_profile` 或 `/etc/profile.d/...` 或类似作用的配置文件里防止忘记设置.

### 3. Packages and Patches

强烈建议通过镜像站下载打包好的所有源代码和 patch, 否则某些源服务器的下载速度即便在非受限的网络环境也很感人.

### 4.5. About SBUs

SBU 只提供大概的预期耗时范围, 误差是很大的, 尤其对于 BLFS 书中的一些编译时间很长的包 (如 Qt, WebKitGtk, Firefox) 来说.

### 7.4. Entering the Chroot Environment

完全按照 LFS 书中的 chroot 步骤编写一个小脚本:

```bash
#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run as root." && exit 1

[ -z "$LFS" ] && exit 1

set -euo pipefail

# mount virtual file systems

mkdir -pv "$LFS"/{dev,proc,sys,run}

mountpoint -q "$LFS"/dev || mount -v --bind /dev "$LFS"/dev

mountpoint -q "$LFS"/dev/pts || mount -vt devpts devpts -o gid=5,mode=0620 "$LFS"/dev/pts
mountpoint -q "$LFS"/proc || mount -vt proc proc "$LFS"/proc
mountpoint -q "$LFS"/sys || mount -vt sysfs sysfs "$LFS"/sys
mountpoint -q "$LFS"/run || mount -vt tmpfs tmpfs "$LFS"/run

if [ -h "$LFS"/dev/shm ]; then
    install -v -d -m 1777 "${LFS}$(realpath /dev/shm)"
else
    mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS"/dev/shm
fi

# cleanup (defer)

cleanup() {
    echo "Cleaning up..."
    mountpoint -q "$LFS"/dev/shm && umount "$LFS"/dev/shm || true
    umount "$LFS"/dev/pts || true
    umount "$LFS"/{sys,proc,run,dev} || true
}
trap cleanup EXIT

# chroot

chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/local/bin:/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

它的作用是自动挂载一系列虚拟文件系统, 并在退出 chroot 时自动清理.

自动挂载, 自动chroot, 自动清理, 如果手动安装过 archlinux 或 Gentoo 的话可能会很快联想到 arch-install-scripts 提供的 `arch-chroot` 脚本. 但此处并不推荐用此方法偷懒, 原因有三:

- `arch-chroot` 挂载 `/dev` 的方式为 `mount -t devtmpfs` 而非 `mount --bind`, 这会导致 `/dev/fd` 等核心软链接消失从而诱发很多问题, 例如交叉编译的工具链完全不可用.

- 默认 offline mode 不会像 LFS 书里那样用 env -i 构造最小环境, 这会对环境隔离造成影响. 同时 `arch-chroot` 也没有设置 `MAKEFLAGS`, `TESTSUITEFLAGS` 等环境变量, chroot后需要在别处设置.

- `arch-chroot` 会将 Host 的 `/run` 通过绑定的方式挂载, 这也会对环境隔离造成影响.

另外再多说一嘴, 将 `$LFS/dev/pts` 挂载为全新的 devpts 会导致 TTY 上下文丢失, 进而导致非 root 用户执行 su 时遇到 `su: must be run from a terminal` 错误. 有两个解决方向:

- 使用 `mount --bind` 挂载 `$LFS/dev/pts` 从而保留 TTY 上下文.

- 在 chroot 后使用 `script` 命令或 `tmux` 等终端复用器重新创建 TTY 上下文.

### 8.66. GRUB

对于 UEFI 引导的系统, 此时需要跳转 BLFS 安装 GRUB. 为避免~~过早地~~陷入依赖地狱, 建议仅按照顺序安装以下包:

1. efivar
2. Popt
3. efibootmgr
4. GRUB for EFI

这对于引导系统来说已经足够用了. 如果需要的话可以之后再补上文档等其他附加依赖重新构建安装.

### 10.2. Creating the /etc/fstab File

可以使用 `arch-install-scripts` 提供的 `genfstab` 生成 `/etc/fstab` 作为起点, 但仍需手动检查.

> [!IMPORTANT]
>
> SysV 版本的 LFS 需要在 `/etc/fstab` 中指定一系列虚拟文件系统, 如果不这样做的话这些目录将不会自动挂载, 导致无法启动.

### 10.3. Linux

> Building the linux kernel for the first time is one of the most challenging tasks in LFS.

确实如此. 对此我可以总结出几点建议:

- initramfs

  LFS 本书并未涉及这部分内容, 而现代成熟发行版几乎无一例外都使用 initramfs 进行引导. 有无 initramfs 对内核配置的影响是巨大的, 例如:
  - 挂载 RootFS 所需驱动如 `CONFIG_EXT4_FS`, `CONFIG_BTRFS_FS` 在没有 initramfs 时必须全部内置, 否则即使 Bootloader 认识 RootFS, 内核也不认识;

  - 在 RootFS 可用之前就请求固件的内核模块在没有 initramfs 时需要编译为模块或将固件也嵌入到内核中.

  如果不急于验收的话可以暂时搁置 LFS 本书的后续章节, 先推进 BLFS 直到 [About Initramfs](https://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/initramfs.html) 了解相关内容后再回来构建内核. 不过我其实更推荐使用 [Dracut](https://github.com/dracut-ng/dracut-ng/) 构建 initramfs, 比起 BLFS 书中的脚本要省心不少.

- 内核版本

  内核版本其实并没有那么重要. 更新内核版本几乎不会对系统造成什么兼容性问题 (除了树外模块如 NVIDIA 专有驱动, 之后会细说). 使用和 Host 相同版本的驱动可以很方便地复用配置, 当前 Host 加载的模块信息也能为内核配置提供参考.

- 复刻并裁剪现有配置

  如果将要使用正在构建的 LFS 系统的机器和 Host 完全相同, 并且内核版本相同或相近, 可以将 Host 现在运行的内核的配置文件搬过来, 同时根据当前 Host 加载的内核模块进行裁剪, 这将极大地减小配置难度以及缩短构建耗时.

  在 Host 上运行:

  ```bash
  # 进入内核源码目录
  cd /path/to/lfs/sources/linux-x.x.x

  # 导出当前内核配置 (如果 Host 有 /proc/config.gz)
  zcat /proc/config.gz > .config
  ```

  在 chroot 环境中运行:

  ```bash
  # 进入内核源码目录
  cd /path/to/lfs/sources/linux-x.x.x

  # 裁剪配置
  make localmodconfig
  ```

  如果内核版本不一致, `make localmodconfig` 时会出现一些交互选项, 建议全部保持默认, 或使用 `make olddefconfig` 来自动处理.

  在此之后, 仍建议 (或者说请务必) 按照 LFS 书中的指示检查和调整配置选项.

- NVIDIA

  如果计划安装 NVIDIA 专有驱动:
  - 禁用 nouveau. 除非显卡型号过于老旧, 否则不推荐使用内核中的 nouveau 驱动, 对应配置选项如 `CONFIG_DRM_NOUVEAU` `CONFIG_FB_NVIDIA` 等可留空. [GLFS NVIDIA-590.48.01 页面页脚](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/nvidia.html)有提到

    > NVIDIA's kernel modules will fail to compile with TTY support unless a graphics driver is included in the kernel. Nouveau is used here, though alternate graphics drivers may also work.

    但我并未遇到此问题, 留待后续验证.

  - 树外模块高度依赖内核版本, 例如 NVIDIA-590.48.01 在 Linux-6.19.6 环境下无法编译, 这主要是由于 Linux 内核不稳定的内部 API. 解决方法很粗暴, 等 NVIDIA 更新适配新内核, 或者自己打补丁. 补丁可以在其他发行版的软件包构建仓库中找到, 例如 Archlinux 的 [nvidia-utils](https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-utils) 仓库.

### 10.4. Using GRUB to Set Up the Boot Process

有两处需要指定分区:

- 通过 `root=` 参数传递给内核的 RootFS 分区位置. 强烈建议使用 PARTUUID 而非 `/dev/sdXN` 这类不稳定的设备路径. 如果已经配置 initramfs, 则也可以使用文件系统 UUID 指定根分区.

- 使用 `search` 指定的 `/boot` 所在分区位置. 强烈建议使用文件系统 UUID 即 `--fs-uuid` 而非 `(hdM, N)` 这类易受磁盘枚举顺序影响的设备记法.

> [!NOTE]
>
> UUID 和 PARTUUID 可以通过 `lsblk -o NAME,FSTYPE,UUID,PARTUUID` 查看.

> [!NOTE]
>
> 如果将外置存储设备 (如 USB 硬盘) 上的分区作为 RootFS , 建议在 GRUB 配置中添加 `rootdelay=10` 或 `rootwait` 等内核参数以防止启动时找不到 RootFS.

## BLFS

绝大多数的建议都已在 LFS 部分提及, 这里只做少数补充:

### 阅读顺序

BLFS 并不像 LFS 那样有线性的章节顺序, 但仍建议先顺序阅读直到 After LFS Configuration Issues 章节**结束**再按自己的需要安装各种包.

### About Firmware

一个偷懒的方法是把 Host 的 `/lib/firmware` 目录复制到 LFS 的对应目录下:

```bash
cp -av /lib/firmware/ "$LFS"/lib/firmware
```

其中 `-a` 选项会保留符号链接和文件权限等信息. 也可用 `rsync -a` 实现相同的效果.

### Mesa

如果计划安装 NVIDIA 专有驱动, 则建议先去 [GLFS](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/drivers-nvidia.html) 安装完成后再去 [GLFS 中的 Mesa 页面](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/mesa.html) 继续安装, 或者至少应先安装 [libglvnd](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/libglvnd.html) 再安装 Mesa. 这么做的原因在 [GLFS 相关页面](https://www.linuxfromscratch.org/glfs/view/stable/shareddeps/aboutgl.html) 有详细说明.

此处记录我使用 Intel iGPU (i915) 和 NVIDIA dGPU (NVIDIA 专有驱动) 的混合显卡系统时的 Mesa 构建参数:

```
meson setup build                   \
  --prefix=$XORG_PREFIX             \
  --buildtype=release               \
  -D platforms=x11,wayland          \
  -D gallium-drivers=iris,llvmpipe  \
  -D vulkan-drivers=intel,swrast    \
  -D valgrind=disabled              \
  -D video-codecs=all               \
  -D libunwind=disabled             \
  -D glvnd=enabled
```

其中:

- `-D gallium-drivers=iris,llvmpipe`:
  - `iris` 用于较新的 (Gen 8 及更新) Intel 显卡. 与之对应的有 `crocus` (适用于 Gen 4 到 Gen 7.5) 和 `i915` (更老). 注意此处的 `i915` 用户态驱动和内核中的 `i915` 模块是不同的东西；
  - 启用 `llvmpipe` 用于 OpenGL 上下文中的软件渲染以防万一.
- `-D vulkan-drivers=intel,swrast`:
  - 启用 Intel iGPU 的 Vulkan 支持；
  - 启用 Vulkan 上下文中的软件渲染驱动“软件光栅化器” `swrast` 以防万一. 注意这里的 `swrast` 实际指 `lavapipe`, 和被废弃的 gallium `swrast` 驱动是不同的东西.
- `-D glvnd=enabled`: 启用 GLVND 支持.

## LFS btw

<details>
<summary>🤓</summary>

<figure>
  <img src="https://io.uyani.de/s/dg7FbrQefPf8sJq/preview" alt="SysV btw" />
  <figcaption>一周目 (LFS-12.4-SysV)</figcaption>
</figure>

<figure>
  <img src="https://io.uyani.de/s/kt4rQkNXJWd9yik/preview" alt="Systemd btw" />
  <figcaption>二周目 (LFS-13.0-Systemd)</figcaption>
</figure>

</details>
