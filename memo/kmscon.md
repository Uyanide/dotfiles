> 鬼知道这有什么意义，但是在 tty 里用 monospace 和 cjk 字体真的很酷

## 安装

AUR - `kmscon`

## 启用

```sh
sudo ln -s '/usr/lib/systemd/system/kmsconvt@.service' '/etc/systemd/system/autovt@.service'
```

以及保留 tty1 为 getty：

```sh
sudo systemctl enable getty@tty1.service
```

理由：

- kmscon 中通过命令行启动图形 session 会遇到问题。
- 通常 tty1 用于运行图形界面，不需要 kmscon 提供的各种特性。

## 修改默认配置

```sh
sudo systemctl edit autovt@.service
```

然后添加以下内容：

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/kmscon --vt=%I --seats=seat0 --no-switchvt
```

解释：

- 默认的 `ExecStart` 携带的参数会覆盖所有配置文件中的对应项，需要先清空。
- 保留默认参数 `--login` 前的部分，因为我看不出不这么做的理由。

然后就可以在 `/etc/kmscon/kmscon.conf` 添加自定义的配置了。

例如：

```conf
login=/bin/login -p -f kolkas
font-name=MesloLGM Nerd Font Mono, Maple Mono NF CN
font-size=14
```

其中：

- `login=/bin/login -p -f kolkas` 指定自动登录用户。
- `font-name` 和 `font-size` 用于设置字体和大小。

### 关于自动登录的补充说明

如果想让 kmscon 在自动登录的同时启动非登陆 shell (例如 fish)，可以将配置改为：

```conf
login=/usr/bin/su - kolkas -s /usr/local/bin/fish-login-wrapper
```

其中 `fish-login-wrapper` 内容为：

```sh
#!/bin/bash

if [ -f /etc/profile ]; then
    source /etc/profile
fi

if [ -f ~/.bash_profile ]; then
    source ~/.bash_profile
fi

# 设置环境变量以供后续脚本检测
export IS_KMSCON=1

# 设定 fastfetch 的 logo 类型为 logo (config/shell/.config/fish/post.d/fetch.fish 会读取该变量)
export fetch_logo_type=logo

exec /usr/bin/fish
```

如果不需要读取 profile 文件而直接将 fish 作为登陆 shell，可以将配置改为：

```conf
login=/usr/bin/su - kolkas -s /usr/bin/fish --login
```

### 关于字体的补充说明

- kmscon 上 2 字符宽的 nerd font 图标会被裁剪至 1 字符宽。可以使用带有 Mono 后缀的 Meslo 系字体作为首选字体，它的图标字符只有 1 字符宽。

- [Archwiki - KMSCON](https://wiki.archlinux.org/title/KMSCON) 上提供了另一种更改字体的方法，即修改 fontconfig 配置，具体做法为在 monospace 字体族中前置添加字体。但这会影响所有使用 fontconfig 和 monospace 字体族的程序，个人认为并非首选。

## 检测当前终端是否为 kmscon

kmscon 中 `$TERM` 将会是 `xterm-256color`，不具区分度，需要另寻他路。

> [!NOTE]
>
> 不建议在缺少对应 terminfo 的情况下直接在 `kmscon.conf` 中配置 `term=kmscon`，但确实也是一种可行的做法。

> [!IMPORTANT]
>
> 以下代码片段适用于 fish shell。

检测所有祖先进程中是否有 kmscon：

```sh
function is_kmscon
    set -l pid %self
    while test $pid -gt 1
        set -l info (ps -o ppid=,comm= -p $pid | string trim)
        set -l ppid (echo $info | awk '{print $1}')
        set -l name (echo $info | awk '{print $2}')

        if string match -q "kmscon" $name
            return 0
        end
        set pid $ppid
    end
    return 1
end

if is_kmscon
    # 在 kmscon 中
end
```

或如果配置了 [环境变量](#关于自动登录的补充说明)：

```sh
if test -n "$IS_KMSCON"
    # 在 kmscon 中
end
```
