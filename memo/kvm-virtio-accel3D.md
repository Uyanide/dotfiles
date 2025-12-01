这是一个关于 **Linux (Arch) 宿主机** + **Linux (Gentoo) 客户机** 在 KVM/QEMU 环境下启用 **Virtio-GPU 3D 加速** 遇到黑屏问题的**非完整**排查与解决记录。

## What

- **环境**：Host: Arch Linux (Kernel 6.x) | Guest: Gentoo Linux | QEMU v10.x。

- **配置**：使用 virtio-vga 或 virtio-gpu 显卡，配合 SPICE 协议。

  ```xml
  <video>
    <model type="virtio" heads="1" primary="yes">
        <acceleration accel3d="yes"/>
    </model>
  </video>

  <graphics type="spice">
    <listen type="none"/>
    <image compression="off"/>
    <gl enable="yes" rendernode="/dev/dri/by-path/pci-0000:00:02.0-render"/>
  </graphics>
  ```

- **现象**：

  - 虚拟机启动后黑屏，无法进入图形界面。
  - SSH 连接正常，系统内核正常运行。
  - SPICE 窗口内能看到鼠标光标（表示连接建立），但无画面。
  - 关键日志 (`/var/log/libvirt/qemu/xxx.log`)：

    ```log
    warning: console: no gl-unblock within one second
    warning: spice: no gl-draw-done within one second
    ```

## Why

初步分析为 OpenGL 渲染死锁，可能由以下因素叠加导致：

1. 权限不足：QEMU 进程无法访问宿主机的 **/dev/dri/\*** 设备。

2. XML 配置缺失：未显式开启 virtio 设备的 3D 加速位。

3. 渲染管线冲突：SPICE 直接处理 GL 上下文容易发生阻塞，尤其是当 Guest 从 VGA 模式切换到 GL 模式时。

## How

### 1. 确认权限

QEMU 运行用户（通常是 `libvirt-qemu`）必须有权访问 GPU 渲染节点。

```bash
# 检查组
groups libvirt-qemu

# 如果没有 'render' 组，将加之
sudo gpasswd -a libvirt-qemu render

# 重启
sudo systemctl restart libvirtd
```

### 2. EGL-Headless 分离渲染

这是解决黑屏死锁最稳妥的方案。通过引入 `egl-headless`，将 OpenGL 渲染（在后台 GPU 完成）与 SPICE 显示传输（在前台完成）解耦。

1. **显卡部分** (`<video>`)：必须显式开启 `accel3d`。

```xml
<video>
  <model type="virtio" heads="1" primary="yes">
    <acceleration accel3d="yes"/>
  </model>
    ...
</video>
```

2. **图形部分** (`<graphics>`)：移除 `<gl>` 节点，改为使用 `egl-headless`。

```xml
<graphics type="egl-headless">
  <gl rendernode="/dev/dri/by-path/pci-0000:00:02.0-render"/>
</graphics>

<graphics type="spice">
  <listen type="none"/>
  <image compression="off"/>
</graphics>
```

### 3. 客户机配置 （Gentoo）

在 Gentoo Guest 内部，确保驱动栈完整。

1. **Portage 配置** ( 或其他位置)：

   - `/etc/portage/make.conf`

     ```conf
     VIDEO_CARDS="virtgl"
     ```

   - 或 `/etc/portage/package.use/00video_cards`

     ```conf
     */* VIDEO_CARDS: virtgl
     ```

2. **安装必要软件包**：

   ```sh
   emerge --ask --changed-use media-libs/mesa
   ```

3. **内核配置**： 需开启 DRM 和 Virtio GPU 支持。

### 4. 重启
