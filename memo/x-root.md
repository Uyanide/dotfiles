有时候会遇到一些需要提权运行的 GUI 应用显示不了窗口的情况，
例如 Gtk 报错：`cannot open display: :1`。
这有可能是 root 用户无权访问 X 显示服务导致的。运行

```bash
xhost +SI:localuser:root
```

可以允许本机的 root 用户访问 X 显示服务，或许可以解决问题。
