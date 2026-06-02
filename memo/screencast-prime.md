走 DMA-BUF 零拷贝导入的消费端 (如 OBS 和浏览器录屏), 其渲染 GPU 必须能导入合成器分配的缓冲区. 最省心的方法是让这些应用和 WM 用同一块 GPU 渲染. 跨 GPU 时可能因为无法导入而捕获失败. 另外, wf-recorder 会根据合成器的渲染设备自动决定分配 buffer 的位置且消费端是编码器而不是某张卡上的渲染上下文所以不受影响.

例如, 如果指定

```kdl
debug {
    render-drm-device "/dev/dri/renderD128"
}
```

且 `renderD128` 表示 Intel 显卡, 那么当设置有

```bash
__NV_PRIME_RENDER_OFFLOAD="1"
__GLX_VENDOR_LIBRARY_NAME="nvidia"
```

环境变量时启动 obs 就会无法捕获屏幕.
