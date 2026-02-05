记录一些在安装 LFS 时踩的一些坑和其他值得一提的事情。

> [!IMPORTANT]
>
> 本文中的 LFS 仅指代 12.4 SysV 版本

## LFS

以下内容按照对应章节划分：

- [2.6. Setting the $LFS Variable and the Umask](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/aboutlfs.html)

  `$LFS` 变量很重要！建议写到 Host 的 `/root/.bash_profile` 或 `/etc/profile.d/...` 或类似作用的配置文件里防止忘记设置。

- [2.7. Mounting the New Partition](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/mounting.html)

  可以用一个小脚本挂载分区。对于指定分区的方式，推荐使用文件系统 UUID 而非诸如 `/dev/sdc1` 这样的绝对路径：

  ```bash
  #!/bin/bash

  [ -z "$LFS" ] && exit 1

  set -euo pipefail

  # 替换为实际的 UUID
  UUID_EFI="{ESP_UUID}"
  UUID_BOOT="{BOOT_UUID}"
  UUID_LFS="{ROOT_UUID}"
  UUID_HOME="{HOME_UUID}"

  ensure_device() {
      local uuid="$1"
      local path="/dev/disk/by-uuid/$uuid"
      if [ ! -e "$path" ]; then
          echo "Device with UUID $uuid not found at $path" >&2
          exit 1
      fi
      echo "$path"
  }

  mkdir_p() {
      local d="$1"
      if [ ! -d "$d" ]; then
          mkdir -p "$d"
      fi
  }

  mkdir_p "$LFS"

  DEV_LFS="$(ensure_device "$UUID_LFS")"
  DEV_BOOT="$(ensure_device "$UUID_BOOT")"
  DEV_EFI="$(ensure_device "$UUID_EFI")"
  DEV_HOME="$(ensure_device "$UUID_HOME")"

  mount "$DEV_LFS" "$LFS"

  mkdir_p "$LFS/boot"
  mount "$DEV_BOOT" "$LFS/boot"

  mkdir_p "$LFS/boot/efi"
  mount "$DEV_EFI" "$LFS/boot/efi"

  mkdir_p "$LFS/home"
  mount "$DEV_HOME" "$LFS/home"
  ```

- [3. Packages and Patches](https://www.linuxfromscratch.org/lfs/view/stable/chapter03/chapter03.html)

  强烈建议通过镜像站下载打包好的所有源代码和 patch，否则某些源服务器的下载速度即便在非受限的网络环境也很感人。

- [4.5. About SBUs](https://www.linuxfromscratch.org/lfs/view/stable/chapter04/aboutsbus.html)

  SBU 只提供大概的预期耗时范围，误差是很大的，尤其对于 BLFS 书中的一些编译时间很长的包（如 Qt，Firefox）来说。

- [5. Compiling a Cross-Toolchain](https://www.linuxfromscratch.org/lfs/view/stable/chapter05/chapter05.html)

  从这一章开始将会手动编译大量的包，其中有不少操作是重复的，例如 `tar -xf`，`cd`，`rm -rf` 等，为此可以写一个小脚本节省时间：

  ```bash
  #!/bin/bash

  set -euo pipefail

  [ -z "${1:-}" ] && {
      echo "Usage: $0 <tarball>"
      exit 1
  }

  tarball=$(realpath "$1")

  dir=$(tar -tf "$tarball" | sed -e 's/^\.\///' | cut -d/ -f1 | sort -u)

  if [ "$(echo "$dir" | wc -l)" -ne 1 ]; then
      echo "Error: Tarball must contain a single top-level directory."
      exit 1
  fi

  cleanup() {
      echo "Cleaning up..."
      cd ..
      if [[ -z "$dir" || "$dir" == "/" || "$dir" == "." ]]; then
          echo "Error: Unsafe directory for cleanup: $dir"
          exit 1
      fi
      rm -rf "$dir"
  }

  trap cleanup EXIT INT TERM
  tar -xvf "$tarball"

  if [ ! -d "$dir" ]; then
      echo "Error: Failed to extract directory: $dir"
      exit 1
  fi

  cd "$dir"

  echo "Spawning shell. Type 'exit' to finish and cleanup."

  bash
  ```

  它的作用是解压一个只含有一个顶层目录的 tarball，cd 进入解压后得到的目录，生成一个 shell，并在这个 shell 退出时清理先前解压得到的文件。

  另外还有对于在 LFS 与 BLFS 中编译包的一些通用建议：
  1. 通常来说，应该（或者说请务必）在编译和安装一个包后完全删除它的目录，仅有少数例外：
     - linux（保留构建树可以缩短重新构建耗时，或至少保留 config 便于复原配置）
     - blfs-bootscripts（在 BLFS 中）

     注意一些需要多次编译的包，例如 gcc，也应该在每次编译与安装后完全删除目录。

  2. 通常来说，建议将所有相关的 tarball 和 patch 下载在同一个目录中，并且将 tarball 也解压在这个目录中。如果目录层级与该默认情况不一致的话必须修改 LFS 书中提供的命令中对应的相对路径。

  3. 如果和我一样使用 UEFI 引导，那么大概率将会在 [8.64. GRUB-2.12](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/grub.html) 第一次接触 BLFS。和 LFS 不同，BLFS 中大多数包都是可选的，一个包可能会依赖其他包，这些依赖分为三个层级：
     - Required
     - Recommended
     - Optional

       其中 `Required` 是必要的依赖；`Recommended` 通常建议当成 `Required` 看待，除非明确知道对应包的用途和不安装它的影响；`Optional` 酌情安装，很多时候是文档相关的依赖。

       更多关于安装 UEFI 版 GRUB 的话题将会在之后的章节中讨论。

  4. 如果想要的包在 LFS 和 BLFS 包中都没有，例如 fish、libglvnd、flatpak 等，不妨先检查 [GLFS](https://www.linuxfromscratch.org/glfs/) 和 [SLFS](https://www.linuxfromscratch.org/slfs/) 或同系列的其他书中是否有涉及，如果有的话将节约很多学习和试错成本。

- [7.4. Entering the Chroot Environment](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/chroot.html)

  如果想要使用 `arch-install-scripts` 提供的 `arch-chroot` 脚本偷懒，则必须确保环境变量的清洗与重新设置，至少应确保 `PATH`, `MAKEFLAGS` 和 `TESTSUITEFLAGS` 被正确设置：

  ```bash
  arch-chroot "$LFS" /usr/bin/env -i \
      HOME=/root \
      TERM="$TERM" \
      PS1='(lfs chroot) \u:\w\$ ' \
      PATH=/usr/local/bin:/usr/bin:/usr/sbin \
      MAKEFLAGS="-j$(nproc)" \
      TESTSUITEFLAGS="-j$(nproc)" \
      /bin/bash --login
  ```

  或者完全按照 LFS 书中的 chroot 步骤编写一个小脚本：

  ```bash
  #!/bin/bash

  [ -z "$LFS" ] && exit 1

  # mount virtual file systems

  mkdir -pv $LFS/{dev,proc,sys,run}

  mount -v --bind /dev $LFS/dev

  mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
  mount -vt proc proc $LFS/proc
  mount -vt sysfs sysfs $LFS/sys
  mount -vt tmpfs tmpfs $LFS/run

  if [ -h $LFS/dev/shm ]; then
      install -v -d -m 1777 $LFS$(realpath /dev/shm)
  else
      mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
  fi

  # cleanup (defer)

  cleanup() {
      echo "Cleaning up..."
      mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
      umount $LFS/dev/pts
      umount $LFS/{sys,proc,run,dev}
  }
  trap cleanup EXIT INT TERM

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

  它的作用是自动挂载一系列虚拟文件系统，同时在退出 chroot 时自动清理。

- [8.64. GRUB-2.12](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/grub.html)

  对于 UEFI 引导的系统，此时需要跳转 BLFS 安装 GRUB。为避免过早地陷入依赖地狱，建议仅按照顺序安装以下包：
  1. [efivar-39](https://www.linuxfromscratch.org/blfs/view/12.4/postlfs/efivar.html)
  2. [Popt-1.19](https://www.linuxfromscratch.org/blfs/view/12.4/general/popt.html)
  3. [efibootmgr-18](https://www.linuxfromscratch.org/blfs/view/12.4/postlfs/efibootmgr.html)
  4. [GRUB-2.12 for EFI](https://www.linuxfromscratch.org/blfs/view/12.4/postlfs/grub-efi.html)

  这对于引导系统来说已经足够用了。如果需要的话可以之后再补上文档等其他附加依赖重新构建安装。

- [10.2. Creating the /etc/fstab File](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/fstab.html)

  可以使用 `arch-install-scripts` 提供的 `genfstab` 偷懒。

> [!IMPORTANT]
>
> 不同于常见的发行版，LFS 需要在 `/etc/fstab` 中指定一系列虚拟文件系统，如果不这样做的话会导致无法启动。

- [10.3. Linux-6.16.1](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/kernel.html)

  内核配置是整本 LFS 书中最具有挑战的环节。对此我可以总结出几点建议：
  - 复刻并裁剪现有配置

    如果将要使用正在构建的 LFS 系统的机器和 Host 完全相同，并且内核版本相同或相近，可以将 Host 现在运行的内核的配置文件搬过来，同时仅启用当前 Host 加载的内核模块，这将极大地减小配置难度和缩短构建耗时：

    在 Host 上运行：

    ```bash
    # 进入内核源码目录
    cd /path/to/lfs/sources/linux-6.16.1

    # 导出当前内核配置（如果 Host 有 /proc/config.gz）
    zcat /proc/config.gz > .config
    ```

    在 chroot 环境中运行：

    ```bash
    # 进入内核源码目录
    cd /path/to/lfs/sources/linux-6.16.1

    # 裁剪配置
    make localmodconfig
    ```

    如果内核版本不一致，会在 `make localmodconfig` 时出现很多交互选项，建议全部保持默认，或使用 `make olddefconfig` 来自动处理。

    对此需要特别注意，大多数成熟发行版的内核都是在有 initramfs 的前提下配置、编译和使用的，而在 LFS 中直到 BLFS 才会涉及到 initramfs。因跨度过大，不建议直接从这里跳到 BLFS 中配置 initramfs。因此需要针对这点手动做一些调整，否则可能无法启动。具体修改方向在之后会提到。

    在此之后，仍建议（或者说请务必）按照 LFS 书中的指示检查和调整配置选项。

  - 参考 Host 的内核配置

    即使不打算直接使用 Host 的内核配置，Host 加载的内核模块也能为 LFS 内核的配置提供很好的参考，例如当一个门类下有很多并列且可选的选项时，可以优先启用 Host 当前加载的模块对应的选项。

  - BLFS 要求的内核配置

    除 LFS 书中列出的内核配置选项外，BLFS 中单独列出了所有涉及的包需要的内核配置选项，建议在配置内核时参考 [BLFS Index of Kernel Settings](https://www.linuxfromscratch.org/blfs/view/12.4/longindex.html#kernel-config-index) 一节，确保启用了所有必要的选项，否则后续可能需要多次重新编译内核。

  - 对于 NVIDIA

    如果之后会安装闭源的 NVIDIA 驱动程序，则不建议在内核中启用 nouveau 驱动，因为这会导致闭源驱动无法正常工作，后续禁用 nouveau 将会是额外的工作量。

  - `<*>` or `<M>`

    对于大多数选项，建议选择模块化（M）而非内置（\*）。这将显著减少内核体积，并且提高灵活性。但在**没有配置 initramfs**（这将在 BLFS 中涉及），有几种情况例外，例如：
    - 存储总线和控制器驱动，如 `CONFIG_BLK_DEV_NVME`；
    - RootFS 所需驱动，如 `CONFIG_EXT4_FS`，`CONFIG_BTRFS_FS`；
    - 如果全盘加密，输入密码（显然）需要键盘或其他输入设备的驱动；
    - 基础显示驱动，如 `CONFIG_VT`，`CONFIG_VT_CONSOLE` 等。

    总之，在挂载 RootFS 之前需要的，以及挂载 RootFS 需要的驱动需要内置。

    也有在**没有 initramfs** 的情况下必须模块化的情况，例如：
    - 需要外部固件支持的驱动程序（如 `i915`），除非使用 initramfs 或通过 `CONFIG_EXTRA_FIRMWARE` 将固件也内置到内核中。

- [10.4. Using GRUB to Set Up the Boot Process](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/grub.html)

  强烈建议使用 PARTUUID 替代传统的 `/dev/sdXN` 设备路径以及 `(hdM,N)` 来指定 `/boot` 分区和根分区。如果已经配置 initramfs，则也可以使用文件系统 UUID 来指定根分区。

  另外，如果将外置存储设备（如 USB 硬盘）上的分区作为 RootFS ，建议在 GRUB 配置中添加 `rootdelay=10` 或 `rootwait` 参数以防止启动时找不到 RootFS 。

> [!NOTE]
>
> UUID 和 PARTUUID 可以通过 `lsblk -o NAME,FSTYPE,UUID,PARTUUID` 查看。

## BLFS

绝大多数的建议都已在 LFS 部分提及，这里只做少数补充：

- 阅读顺序

  BLFS 并不像 LFS 那样有线性的章节顺序，但仍建议先顺序阅读直到 [After LFS Configuration Issues](https://www.linuxfromscratch.org/blfs/view/stable/postlfs/config.html) 章节**结束**再按自己的需要安装各种包。

- `su: must be run from a terminal`
  1. What?

     这通常发生在 chroot 后使用 `su` 切换到普通用户，再使用 `su` 试图切换回 root 时。

  2. Why?

     LFS 书中 [7.3. Preparing Virtual Kernel File Systems](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/kernfs.html) 中的 `mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts` 命令将 `/dev/pts` 挂载为全新的 `devpts` 文件系统，导致 tty 上下文丢失，从而无法使用 `su`。

  3. How?

     一个简单的解决方案是使用 `script` 命令重新分配一个伪终端：

     ```bash
     script /dev/null
     ```

     之后就可以正常使用 `su` 了。

- [About Firmware](https://www.linuxfromscratch.org/blfs/view/stable/postlfs/firmware.html)

  一个偷懒的方法是把 Host 的 `/lib/firmware` 目录复制到 LFS 的对应目录下：

  ```bash
  cp -av /lib/firmware $LFS/lib/
  ```

  其中 `-a` 选项会保留符号链接和文件权限等信息。

- [Mesa-25.1.8](https://www.linuxfromscratch.org/blfs/view/stable/x/mesa.html)

  此处记录使用 Intel iGPU（i915）和 NVIDIA dGPU（NVIDIA 专有驱动）的混合显卡系统时的配置方法：

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

  其中：
  - `-D gallium-drivers=iris,llvmpipe`：
    - 不包含 NVIDIA 相关的参数，因为 NVIDIA 专有驱动自带完整的 OpenGL 实现，不需要 Mesa 提供；
    - `iris` 用于现代 Intel 显卡。对于较新（Gen 8 及更新）的硬件，`crocus`（适用于 Gen 4 到 Gen 7.5）和 `i915`（更老）用户态 OpenGL 驱动已被废弃，不应再使用。注意此处的 `i915` 用户态驱动和内核中的 `i915` 模块是不同的东西；
    - 启用 `llvmpipe` 用于 OpenGL 上下文中的软件渲染以防万一。
  - `-D vulkan-drivers=intel,swrast`：
    - 不用管 NVIDIA，原因同上；
    - 启用 Intel iGPU 的 Vulkan 支持；
    - 启用 Vulkan 上下文中的软件渲染驱动“软件光栅化器” `swrast` 以防万一。注意这里的 `swrast` 实际指 `lavapipe`，和被废弃的 gallium `swrast` 驱动是不同的东西。
  - `-D glvnd=enabled`：启用 GLVND 支持以便和 NVIDIA 专有驱动兼容。libglvnd 需要[在 GLFS 书中安装](https://glfs-book.github.io/glfs/shareddeps/libglvnd.html)。

  > 虽然 GLFS 中的 libglvnd 章节在开头处提到了 `If you've come here from the BLFS Mesa page, ...`，但实际上 BLFS 中的 Mesa 章节并没有提到 libglvnd 和除 nouveau 外与 NVIDIA 相关的话题。算个小坑？大概。

- [Qt-6.9.2](https://www.linuxfromscratch.org/blfs/view/stable/x/qt6.html)

  此版本的 Qt 的 geoclue2 模块在特定条件下构建时可能会出现错误，日志的一部分如下：

  <details>
  <summary>错误日志</summary>

  ```log
  [10697/11095] Linking CXX shared mo...s/position/libqtposition_geoclue2.so

  FAILED: [code=1] qtbase/plugins/position/libqtposition_geoclue2.so

  : && /usr/bin/c++ -fPIC -DNDEBUG -O2  -shared -Wl,--no-undefined -Wl,--version-script,/home/kolkas/qtbuild/qt-everywhere-src-6.9.2/qtpositioning/src/plugins/position/geoclue2/QGeoPositionInfoSourceFactoryGeoclue2Plugin.version -Wl,-z,relro,-z,now -Wl,--enable-new-dtags  -o qtbase/plugins/position/libqtposition_geoclue2.so qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/client_interface.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/location_interface.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/manager_interface.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/geocluetypes.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosourcefactory_geoclue2.cpp.o  -Wl,-rpath,/home/kolkas/qtbuild/qt-everywhere-src-6.9.2/qtbase/lib:  qtbase/lib/libQt6DBus.so.6.9.2  qtbase/lib/libQt6Positioning.so.6.9.2  qtbase/lib/libQt6Core.so.6.9.2 && :

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o:(.data.rel.ro+0x160): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::staticMetaObject'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:(.data.rel.ro+0x120): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o:(.data.rel.ro+0xc0): multiple definition of `OrgFreedesktopGeoClue2LocationInterface::staticMetaObject'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:(.data.rel.ro+0x80): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o:(.data.rel.ro+0x40): multiple definition of `OrgFreedesktopGeoClue2ManagerInterface::staticMetaObject'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:(.data.rel.ro+0x0): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ClientInterface::metaObject() const':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x30): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::metaObject() const'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x0): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2LocationInterface::metaObject() const':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x50): multiple definition of `OrgFreedesktopGeoClue2LocationInterface::metaObject() const'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x20): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ManagerInterface::metaObject() const':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x70): multiple definition of `OrgFreedesktopGeoClue2ManagerInterface::metaObject() const'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x40): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ClientInterface::LocationUpdated(QDBusObjectPath const&, QDBusObjectPath const&)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0xb0): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::LocationUpdated(QDBusObjectPath const&, QDBusObjectPath const&)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x60): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ClientInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x2af0): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0xc0): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2LocationInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x3440): multiple definition of `OrgFreedesktopGeoClue2LocationInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0xb60): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ManagerInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4140): multiple definition of `OrgFreedesktopGeoClue2ManagerInterface::qt_static_metacall(QObject*, QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1000): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ClientInterface::qt_metacast(char const*)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4bc0): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::qt_metacast(char const*)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1a80): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2LocationInterface::qt_metacast(char const*)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4c20): multiple definition of `OrgFreedesktopGeoClue2LocationInterface::qt_metacast(char const*)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1ae0): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ManagerInterface::qt_metacast(char const*)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4c80): multiple definition of `OrgFreedesktopGeoClue2ManagerInterface::qt_metacast(char const*)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1b40): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ClientInterface::qt_metacall(QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4ce0): multiple definition of `OrgFreedesktopGeoClue2ClientInterface::qt_metacall(QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1ba0): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2LocationInterface::qt_metacall(QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4dc0): multiple definition of `OrgFreedesktopGeoClue2LocationInterface::qt_metacall(QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1c80): first defined here

  /usr/bin/ld: qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/qgeopositioninfosource_geoclue2.cpp.o: in function `OrgFreedesktopGeoClue2ManagerInterface::qt_metacall(QMetaObject::Call, int, void**)':

  qgeopositioninfosource_geoclue2.cpp:(.text+0x4e10): multiple definition of `OrgFreedesktopGeoClue2ManagerInterface::qt_metacall(QMetaObject::Call, int, void**)'; qtpositioning/src/plugins/position/geoclue2/CMakeFiles/QGeoPositionInfoSourceFactoryGeoclue2Plugin.dir/QGeoPositionInfoSourceFactoryGeoclue2Plugin_autogen/mocs_compilation.cpp.o:mocs_compilation.cpp:(.text+0x1cd0): first defined here

  collect2: error: ld returned 1 exit status

  [10716/11095] Building CXX object q...hell.dir/qwaylandqtshellchrome.cpp.o

  ninja: build stopped: subcommand failed.
  ```

  </details>

  原因是源文件显式 include 了多余的 moc 文件，和自动生成的相同作用的代码冲突，导致重复定义。出问题的源文件有两个，可以通过以下命令修复：

  ```bash
  sed -i -E 's|\s*#include "moc_.*|// &|g' qtpositioning/src/plugins/position/geoclue2/qgeopositioninfosourcefactory_geoclue2.cpp qtpositioning/src/plugins/position/geoclue2/qgeopositioninfosource_geoclue2.cpp
  ```

## References

- [Welcome - Linux From Scratch](https://www.linuxfromscratch.org/)

- [Linux From Scratch - Version 12.4 ](https://www.linuxfromscratch.org/lfs/view/stable/)

- [Linux From Scratch - 版本 12.4-中文翻译版](https://lfs.xry111.site/zh_CN/12.4/)

- [Beyond Linux® From Scratch (System V Edition) - Version 12.4](https://www.linuxfromscratch.org/blfs/view/stable/)

- [meson.build - Mesa/mesa](https://gitlab.freedesktop.org/mesa/mesa/-/blob/main/meson.build)

- [Intel - Gentoo wiki](https://wiki.gentoo.org/wiki/Intel)

- [LFS btw](https://io.uyani.de/s/dg7FbrQefPf8sJq)
