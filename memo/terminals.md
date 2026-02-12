一些关于终端模拟器(Terminal Emulator)的话题, 持续补充中...

> 我日常 99% 的时间都在 Wayland (剩下 0.9% 在 Windows, 0.1% 对着 TTY 发呆), 所以本篇内容**完全不会**考虑 X11 环境.

## Index

- [Index](#index)
- [基本原理](#基本原理)
  - [TTY / PTY](#tty--pty)
  - [Shell](#shell)
  - [终端模拟器](#终端模拟器)
  - [控制序列](#控制序列)
- [图像协议](#图像协议)
  - [各终端支持情况](#各终端支持情况)
  - [使用方法](#使用方法)
  - [检测方法](#检测方法)
    - [基本模式](#基本模式)
    - [KGP](#kgp)
    - [Sixel](#sixel)
    - [ITerm](#iterm)
    - [3 in 1](#3-in-1)
    - [快速检测](#快速检测)
  - [显示效果](#显示效果)
  - [性能测试](#性能测试)
- [默认 Shell](#默认-shell)
  - [一些概念](#一些概念)
  - [最佳实践](#最佳实践)
- [GPU 加速](#gpu-加速)
- [一些特殊者](#一些特殊者)
  - [Ghostty](#ghostty)
  - [Kmscon](#kmscon)
- [References](#references)

## 基本原理

### TTY / PTY

> TTY - Teletypewriter, PTY - Pseudo Terminal

TTY 本质为内核中的双向通信管道与数据处理层. 现代 Linux 系统中, 物理 TTY 几乎完全被 PTY 取代. PTY 是一对虚拟的字符设备, 分为 **Master** 和 **Slave**.

- **Slave** 模拟了传统的硬件串口行为. Shell 和其他命令行程序主要与这一端交互.

- **Master** 则由终端模拟器使用, 负责将用户的输入传递给 Slave 端, 并将 Slave 端的输出渲染到屏幕上.

- **Line Discipline** 是介于 Master 和 Slave 之间的一个中间层, 负责处理"行编辑"逻辑.
  - **Canonical Mode**: 这是默认模式, Line Discipline 会缓存用户输入的字符, 直到检测到换行符(Enter)或 EOF(通常为 Ctrl+D)时才将整行输入发送给 Slave 端. 在此模式下, Line Discipline 还会处理一些特殊字符, 如退格符(Backspace)用于删除前一个字符, Ctrl+U 用于删除整行等.

  - **Raw Mode**: 在此模式下, Line Discipline 不会对输入进行任何处理, 用户输入的每个字符都会立即传递给 Slave 端. 这对于需要实时响应用户输入的应用程序(如文本编辑器和终端复用器)非常重要.

  - **Signal Handling**: Line Discipline 还负责处理一些控制字符, 如 Ctrl+C 用于发送中断信号(SIGINT)给前台进程, Ctrl+Z 用于发送挂起信号(SIGTSTP)等.

### Shell

Shell 是运行在 TTY Slave 端的命令行解释器, 负责:

- 解析用户输入的命令;

- 通过 `fork()` 和 `exec()` 等系统调用来启动子进程或执行内置命令;

- 将子进程的输出通过 TTY Slave 端发送回终端模拟器的 Master 端进行显示;

- 管理前台和后台进程组, 处理信号传递等.

值得注意的是, Shell 中输入命令后的"回显"并不是 Shell 自己完成的, 而必须通过 TTY 的 Line Discipline. 当用户输入字符时, Line Discipline 会将其显示在屏幕上, 从未完成"回显".

### 终端模拟器

终端模拟器是负责转换 I/O 数据流与渲染显示的 GUI 应用程序. 它通过 PTY Master 端与 Shell 及其他命令行程序通信.

- **输入**: 捕获键盘事件, 转换为字节流写入 PTY Master 文件描述符;

- **输出**: 从 PTY Master 读取字节流, 解析控制序列;

- **渲染**: 根据解析结果更新屏幕显示, 包括文本内容, 光标位置, 颜色等.

### 控制序列

控制序列是一种特殊的字节序列, 基于不同协议, 用于在终端模拟器中实现各种功能, 如:

- `CSI` (Control Sequence Introducer): 以 `\033[` 开头
  - 光标移动: `\033[<row>;<col>H` 或 `\033[<row>;<col>f`
  - 清屏: `\033[2J`
  - 颜色设置: `\033[38;2;<r>;<g>;<b>m` (前景色), `\033[48;2;<r>;<g>;<b>m` (背景色)

- `OSC` (Operating System Command): 以 `\033]` 开头
  - 设置窗口标题: `\033]0;title\a`
  - 设置剪贴板内容: `\033]52;c;data\a`

下一节将会提到的各类图像协议也是通过控制序列实现的.

## 图像协议

即在终端模拟器里显示图片的~~旁门左道~~各类协议, 其中使用较为广泛的有三个:

- **KGP**(非官方简称): [Kitty Terminal Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
- **Sixel**: [Sixel](https://en.wikipedia.org/wiki/Sixel)
- **ITerm**: [ITerm2 Inline Images Protocol](https://iterm2.com/documentation-images.html)

值得一提的是其中 KGP 甚至能被用来在终端模拟器里播放视频, 只需要给 mpv 加上 `--vo=kitty` 参数即可.

### 各终端支持情况

不完全统计, 只列举我知道和确实使用过的.

| Terminal      | KGP | Sixel | ITerm |
| ------------- | --- | ----- | ----- |
| Alacritty     | ❌  | ❌    | ❌    |
| Foot          | ❌  | ✅    | ❌    |
| Ghostty       | ✅  | ❌    | ❌    |
| GNOME Console | ❌  | ❌    | ❌    |
| Kitty         | ✅  | ❌    | ❌    |
| Konsole       | ✅  | ✅    | ✅    |
| Rio           | ❌  | ✅    | ❌    |
| Tabby         | ❌  | ✅    | ❌    |
| Warp          | ✅  | ❌    | ❌    |
| WezTerm       | ✅  | ✅    | ✅    |

### 使用方法

- 部分终端模拟器提供了显示图片的小程序/内置功能, 可以通过参数调用, 例如:

  ```bash
  kitty +kitten icat /path/to/image
  ```

  将会使用 KGP 显示图片,

  ```bash
  wezterm imgcat /path/to/image
  ```

  将会使用 ITerm 图形协议形式图片. 以上两个指令在其他支持相同协议的终端模拟器同样可用.

- 另一个很好用的通用程序是 [chafa](https://github.com/hpjansson/chafa). 除了自动检测并使用以上三种协议显示图片外, 它还支持以 `symbols` 格式使用 [ANSI 颜色转义序列](https://en.wikipedia.org/wiki/ANSI_escape_code)显示图片的大致样貌, 这在不支持以上任何一种协议的终端模拟器(如 Alacritty)上很好用.

### 检测方法

最简单直接的检测方法当然是真的找一张图片用各种协议都试一遭. 但有些时候可能会需要快速 / 轻量 / 自动的检测手段, 例如在一个需要显示图片的 TUI / CLI 程序里. 此时各种控制序列就可以派上用场了.

> [!NOTE]
>
> 下文中所有控制序列及其响应均采用反斜杠转义表示方法, 例如 `\033` 表示 ESC, `\\` 表示单个反斜杠.

#### 基本模式

正如[基本原理](#基本原理)一节所说, 在 Linux 的 TTY 架构设计中, 终端模拟器和内核之间只有一条双向通信管道. 当内核向终端发送查询序列后, 终端模拟器的响应会通过这唯一一条管道发送给内核, 而用户输入的字符也是通过这条管道发送给内核的, 因此内核会将终端模拟器的响应像用户的输入一样放在输入队列中. 具体表现为终端模拟器的响应出现在输入缓冲区内.

为了读取这些响应, 脚本需要通过 `stty raw -echo` 开启 Raw 模式, 关闭回显, 然后通过 `read` 等命令逐字符读取. 这适用于本节将会涉及的所有控制序列.

#### KGP

KGP 提供了[标准化的检测方法](https://sw.kovidgoyal.net/kitty/graphics-protocol/#querying-support-and-available-transmission-mediums). 一种简单通用的实践为发送 `\033_Gi=<ID>,s=1,v=1,a=q,t=d,f=24;AAAA\033\\\033[c` 序列, 它由两部分组成:

- `\033_Gi=<ID>,s=1,v=1,a=q,t=d,f=24;AAAA\033\\`

  这是 KGP 规定的用于查询的控制序列, `i=<ID>` 用于指定查询操作的编号, 范围 `1` 到 `4294967295`, 可以设为随机数. `a=q` 表明该操作为查询. 如果终端支持 KGP, 则会响应:

  `\033_Gi=<ID>;OK\033\\`

  反之如果无响应或响应错误, 则可认为不支持.

- `\033[c`

  这是大多数终端都会响应的 `DA1` 序列, 用于查询终端特性, 标准响应正则为 `\033\[\?[0-9;]*c`, 但是此处只用于标识 Kitty 图像协议查询序列响应的结束, 其本身具体响应了什么并不重要, 这得益于 KGP "在收到查询序列后必须立即相应, 不能先处理其他输入"的规定. 例如, 如果一次查询返回了 `DA1` 的响应而没有有效的 KGP 的相应, 则可视为该终端模拟器不支持 KGP.

#### Sixel

Sixel 支持情况可以用 `DA1` 查询, 即 `\033[c`. 如响应中分号分隔的数字中包含 `4`, 则可视为支持.

值得注意的一点是, 很多终端复用器(Terminal Multiplexer)如 Tmux / Zellij 也会在 `DA1` 的响应中包含 `4`, 但实际支持情况取决于终端复用器的配置与宿主终端.

#### ITerm

ITerm2 图片协议本质为 `OSC 1337` 控制序列的 `FILE` 特性. ITerm2 文档虽然提供了[检测方法](https://iterm2.com/feature-reporting/), 但一番测试后发现在我认知范围内的支持 ITerm2 图片协议的终端上均无法得到有效相应.

但还有其他方法可以实现查询目的. 虽然无法直接查询 `FILE` 特性的支持情况, 但可以通过执行 `OSC 1337` 控制序列中其他副作用和开销较小的查询来间接获知是否支持该控制序列, 进而获知是否支持通过该协议显示图片. 一种常见的方法是查询 `ReportCellSize`, 具体控制序列为 `\033]1337;ReportCellSize\a`. 如果返回了以 `\033]1337;ReportCellSize=` 为前缀的响应, 则可视为通过. 虽然看起来并不怎么健壮, 但根据我自己的测试结果误判可能性很小, 已经足够使用了.

同样的, 上述查询也推荐使用 `DA1` 做哨兵. 由此, 完整的控制序列为: `\033]1337;ReportCellSize\a\033[c`.

#### 3 in 1

不难发现, 用于查询 KGP 和 `OSC 1337` 的控制序列都可以用 `DA1` 做哨兵, 而 `DA1` 本身可以用来查询 Sixel 协议的支持情况. 因此, 三次查询可以被整合到单个控制序列中, 由此得以实现三合一检测脚本:

```bash
#!/usr/bin/env bash

set -euo pipefail

# Ensure in a interactive terminal
[ ! -t 0 ] && exit 0

# Construct query
KGP_QUERY_ID=$RANDOM
KGP_QUERY_CODE=$(printf "\033_Gi=%d,s=1,v=1,a=q,t=d,f=24;AAAA\033\\" "$KGP_QUERY_ID")
ITERM2_QUERY_CODE=$(printf "\033]1337;ReportCellSize\a")
KGP_EXPECTED_RESPONSE=$(printf "\033_Gi=%d;OK\033\\" "$KGP_QUERY_ID")
ITERM2_EXPECTED_RESPONSE=$(printf "\033]1337;") # followed by "ReportCellSize=...", but only the prefix is enough
FENCE_CODE=$(printf "\033[c")

# Set terminal to raw mode with timeout
stty_orig=$(stty -g)
trap 'stty "$stty_orig"' EXIT
stty -echo -icanon min 1 time 0

printf "%s%s%s" "$ITERM2_QUERY_CODE" "$KGP_QUERY_CODE" "$FENCE_CODE" > /dev/tty

support_kgp=0
support_iterm2=0
support_sixel=0

response=""
while true; do
    IFS= read -r -N 1 -t 0.3 char || {
        [ -z "$char" ] && break
    }

    response+="$char"

    if [[ "$response" == *"$KGP_EXPECTED_RESPONSE"* ]]; then
        support_kgp=1
    fi

    if [[ "$response" == *"$ITERM2_EXPECTED_RESPONSE"* ]]; then
        support_iterm2=1
    fi

    if [[ "$response" == *$'\033['*'c' ]]; then
        break
    fi

    if [ ${#response} -gt 1024 ]; then
        break
    fi
done

if [[ "$response" =~ $'\x1b'\[\?([0-9;]*)c ]]; then
    params="${BASH_REMATCH[1]}"

    IFS=';' read -ra codes <<< "$params"

    for code in "${codes[@]}"; do
        if [[ "$code" == "4" ]]; then
            support_sixel=1
            break
        fi
    done
fi

if [ "$support_kgp" -eq 1 ]; then
    echo "kitty"
fi

if [ "$support_iterm2" -eq 1 ]; then
    echo "iterm"
fi

if [ "$support_sixel" -eq 1 ]; then
    echo "sixels"
fi
```

对于支持的协议, 这个脚本会输出 `kitty` / `iterm` / `sixels` (命名方式来自 chafa 的 format 参数), 每个一行.

#### 快速检测

如果不想写脚本, 也可以直接在 shell 里执行以下命令:

```bash
bash <(curl -fsSL https://tgp.uyani.de/query)
```

这将会根据上述原理检测当前终端模拟器支持的图像协议, 并输出结果. 当然, 这需要联网并且信任该脚本的来源. 请务必先拉取并查看脚本内容以确认无害后再执行.

将网址中的 `query` 替换为 `kitty` / `iterm` / `sixels` 可以通过显示测试图片的方式验证对应协议的支持情况, 例如:

```bash
bash <(curl -fsSL https://tgp.uyani.de/kitty)
```

将会尝试用 KGP 显示一张测试图片, 如果显示成功则说明支持 KGP, 反之则不支持.

> [!TIP]
>
> 对于 fish shell, 类似 `cmdA <(cmdB)` 的语法可被替换为 `cmdA (cmdB | psub)`, 因此上述命令在 fish 里可以写为:
>
> ```fish
> bash (curl -fsSL https://tgp.uyani.de/query | psub)
> ```

### 显示效果

先说结论, 在大多数终端模拟器上, KGP ≈ ITerm >> Sixel.

Sixel 是三者之中最老的, 颜色格式类似 GIF89a, 只支持索引颜色和单色键透明度, 画面有明显的颗粒感和色带. 如此妥协换来的是三者之中最强的兼容性, 甚至连 Windows Terminal 都支持 Sixel, 可见一斑.

ITerm 的实现方式很简单粗暴, 它会将图片数据原封不动地交给终端模拟器渲染, 因此实际显示效果极大程度上取决于终端模拟器的实现方式. 不过, 由于终端模拟器能拿到原始的图像二进制数据, 显示效果一般不会比其他二者差.

KGP 既支持直接传输 PNG 二进制数据, 也支持传输 24bit 与 32bit 像素数据, 支持指定 Z-Index 叠加显示, 原生支持动图, 可玩性是三者之中最高的, 显示效果通常也不会差.

### 性能测试

简单的速度测试.

- 固定宽度连续输出53张中到大尺寸(1920x1080到9457x5324不等)JPEG和PNG图片, 取5次耗时平均, 单位为秒.

  | Terminal | KGP   | Sixels | ITerm |
  | -------- | ----- | ------ | ----- |
  | Kitty    | 4.486 | -      | -     |
  | Ghostty  | 7.184 | -      | -     |
  | Konsole  | 7.388 | 4.842  | 7.266 |
  | WezTerm  | 4.820 | 6.218  | 5.042 |
  | Foot     | -     | 4.124  | -     |

- 连续输出64张小尺寸(50x50以内)PNG图片, 取5次耗时平均, 单位为毫秒.

  | Terminal | KGP   | Sixels | ITerm |
  | -------- | ----- | ------ | ----- |
  | Kitty    | 975.0 | -      | -     |
  | Ghostty  | 724.9 | -      | -     |
  | Konsole  | 744.6 | 781.6  | 768.1 |
  | WezTerm  | 970.4 | 980.2  | 962.0 |
  | Foot     | -     | 719.6  | -     |

## 默认 Shell

> 虽然这和终端模拟器关系不大, 但姑且放这里一起说说.

### 一些概念

- **登录 shell** 是指用户通过终端登录系统时启动的 shell, 通常是用户登录时执行的第一个 shell.

  登录 shell 为 bash 时, 在登录时会检索
  - `/etc/profile`

  并加载, 并会加载以下第一个存在的用户配置文件:
  - `~/.bash_profile`
  - `~/.bash_login`
  - `~/.profile`

  所有全局环境变量以及其他非交互配置都可以写进这些文件.

- **非登录 shell** 是指用户在已经登录的情况下启动的 shell, 通常是通过终端模拟器或其他方式打开的 shell.

  非登录 shell 为 bash 时, 会先加载 `/etc/bash.bashrc`, 然后加载用户的 `~/.bashrc` 文件.

  对于非登录 shell 为 fish 的情况, 则会先加载 `/etc/fish/conf.d` 以及 `/etc/fish/config.fish`,
  然后加载用户的 `~/.config/fish/conf.d` 以及 `~/.config/fish/config.fish`.

  非登录 shell 会继承登录 shell 的环境变量, 但不会加载登录 shell 的配置文件.

- **默认 shell** 是指用户通过终端登录系统时默认启动的登录 shell, 通常也将会是大多数终端模拟器默认启动的 shell.

  默认 shell 对每个用户单独设置, 存储在 `/etc/passwd` 文件中, 可以在 `useradd` 时通过 `-s` 参数指定, 后续也可以通过 `chsh` 更改.

- **POSIX 兼容** 的 shell 指兼容 [POSIX 规定的 Shell 语法](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)的 shell, 常用 shell 如 bash / dash / zsh 均在此列, 另一些注重用户交互体验或其他方面的 Shell 如 fish 可能不会(完全)做到 POSIX 兼容.

### 最佳实践

由于类似 fish 的 shell 未做到 POSIX 兼容, 因此不适合作为登录 shell 使用. 如果想享受 fish 提供的便利功能, 最推荐的方法是仅在交互场景启用 fish. [Archwiki](https://wiki.archlinux.org/title/Fish) 上列举了两种方法:

- 在终端模拟器的配置里指定启动的程序

  绝大多数终端模拟器都提供了类似的选项, 如 Kitty 可以通过设置 `shell fish` 自动启动 fish, 对于 WezTerm 则为 `config.default_prog = { "/usr/bin/fish" }`.

  这是兼容性最好的方法, 因为它完全不会影响原有登录终端的任何配置, 同时也完全不影响日常使用. 唯一的麻烦点在于对于每个终端模拟器(也包括 TTY 与 Kmscon 之类, 如果用到的话)需要单独配置.

- 在 .bashrc 中自动启用 fish

  这适用于不想对每个终端模拟器单独配置的情况或远程 SSH 登录的情况. 具体做法为添加以下内容到 `$HOME/.bashrc` 的**末尾**:

  ```bash
  if grep -qv 'fish' /proc/$PPID/comm && [[ ${SHLVL} == [1,2] ]]; then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
  fi
  ```

  但值得注意的是, 此方法不保证完全不会出问题, 例如我曾经遇到过在服务器如此配置后 vscode 远程连接无法正常建立的情况.

  一种更为妥协的办法是通过

  ```bash
  type f &>/dev/null || alias f="exec fish"
  ```

  设置 `f` 别名(如果没有被占用的话), 在进入 bash 后手动敲击 `f` + Enter 切换到 fish. 虽然麻烦些但明显更为可靠.

## GPU 加速

虽然听起来高大上, 也是很多终端模拟器写在 Description 里的核心特性之一, 但是在实际使用场景中就我个人经验而言影响并没有想象中那么巨大. 终端模拟器所主要面对的仍然是纯文本场景, 最多换一换颜色, 滚一滚屏幕, 这对于现代 CPU 来说并没有很吃力.

## 一些特殊者

### Ghostty

如果说终端模拟器也要有自己的原神, 那么 Ghostty 无疑是最合适的候选之一. 关于这个终端模拟器可以聊的东西有很多, 这里先简单列一些 Pro 和 Con.

- Pros
  - Terminal Inspector

    独一份的调试窗口. 虽然对我来说大多数时候都没什么实际作用, 但总会有用到的时候, 具有一定不可替代性~~, 并且真的很酷~~.

  - 自定义 Shader

    简单如光标跳转动画, 复杂如全局光效, 从 CRT 到 Glitchy, 可玩性极高.

- Cons
  - 不稳定

    尽管从首个正式 Release 开始计算已经过了一周岁生日, 但 Ghostty 目前仍处于早期版本, 使用过程中还是会遇到各种奇奇怪怪的问题, 并不适合作为主力终端模拟器使用.

  - 启动速度

    相比其他相同定位的终端模拟器, Ghostty 的冷启动速度可以说奇慢无比. 尽管[文档](https://ghostty.org/docs/linux/systemd)有提到在启动 `app-com.mitchellh.ghostty.service` 服务的前提下使用 `ghostty +new-window` 加快启动速度, 但这同时放弃了很多灵活性. 例如, `ghostty +new-window` 无法与 `-e` 参数一起使用, 非冷启动的实例也难以同步环境变量, 以 systemd 服务启动的 ghostty 甚至无法自动同步在 WM 如 niri 处配置的环境变量. 虽然这些缺失的灵活性可以通过其他一些方法弥补, 但这确实是使用其他终端模拟器时不曾面对的问题.

### Kmscon

这是运行在 Linux TTY 上的终端模拟器, 可以在一定程度上作为传统 TTY 的替代品使用, 提供了诸如复杂字体渲染 / CJK 文字 / 多显示器支持等高级功能. 关于此的话题可以在 [kmscon.md](kmscon.md) 中找到.

## References

- [Kitty Terminal Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)

- [Sixel - Wikipedia](https://en.wikipedia.org/wiki/Sixel)

- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Sixel-Graphics)

- [Feature Reporting Spec - ITerm2](https://iterm2.com/feature-reporting/)

- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)

- [Fish - ArchWiki](https://wiki.archlinux.org/title/Fish)

- [Systemd and D-Bus - Linux - Ghostty](https://ghostty.org/docs/linux/systemd)
