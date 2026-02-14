一些关于终端模拟器(Terminal Emulator)的话题, 持续补充中...

> 我日常 99% 的时间都在 Wayland (剩下 0.9% 在 Windows, 0.1% 对着 TTY 发呆), 所以本篇内容**完全不会**考虑 X11 环境.

## 目录

- [目录](#目录)
- [前言](#前言)
- [基本原理](#基本原理)
  - [TTY / PTY](#tty--pty)
  - [Shell](#shell)
  - [终端模拟器](#终端模拟器)
  - [PTY 创建流程](#pty-创建流程)
  - [控制序列](#控制序列)
- [图像协议](#图像协议)
  - [各终端支持情况](#各终端支持情况)
  - [使用方法](#使用方法)
  - [检测方法](#检测方法)
    - [基本模式](#基本模式)
    - [KGP](#kgp)
    - [Sixel](#sixel)
    - [ITerm2](#iterm2)
    - [3 in 1](#3-in-1)
    - [快速检测](#快速检测)
  - [显示效果](#显示效果)
  - [性能测试](#性能测试)
  - [KGP Unicode Placeholders](#kgp-unicode-placeholders)
    - [特性](#特性)
    - [使用](#使用)
    - [实现](#实现)
- [默认 Shell](#默认-shell)
  - [一些概念](#一些概念)
  - [最佳实践](#最佳实践)
- [GPU 加速](#gpu-加速)
- [单独聊聊](#单独聊聊)
  - [Ghostty](#ghostty)
  - [Kmscon](#kmscon)
  - [Terminal Multiplexer](#terminal-multiplexer)
- [References](#references)

## 前言

本文会涉及很多经验结论与少数测试, 因此在这里给出我所使用的平台的部分信息与后文所涉及的终端模拟器列表, 以供参考.

- **平台**: Arch Linux (kernel 6.18.9-3-cachyos, glibc 2.43+r5+g856c426a7534-2)
- **桌面环境**: Niri (Wayland) 25.11
- **CPU**: 13th Gen Intel(R) Core(TM) i5-13500HX (20) @ 4.70 GHz
- **GPU**: NVIDIA GeForce RTX 4050 Max-Q / Mobile (with PRIME Render Offload)
- **终端模拟器**:

  | Terminal      | Version                       | Installed From   |
  | ------------- | ----------------------------- | ---------------- |
  | alacritty     | 0.16.1-1.1                    | cachyos-extra-v3 |
  | foot          | 1.25.0-1                      | extra            |
  | ghostty       | 1.2.3-2.1                     | cachyos-extra-v3 |
  | gnome-console | 49.2-1.1                      | cachyos-extra-v3 |
  | kitty         | 0.45.0-4.1                    | cachyos-extra-v3 |
  | konsole       | 25.12.2-1.1                   | cachyos-extra-v3 |
  | rio           | 0.2.37-1.1                    | cachyos-extra-v3 |
  | tabby-bin     | 1.0.230-1                     | aur              |
  | warp          | v0.2026.02.10.11.37.stable_01 | AppImage         |
  | wezterm       | 20240203.110809.5046fc22-2.1  | cachyos-extra-v3 |

- **其他部分相关软件**:

  | Name      | Version    | Installed From   |
  | --------- | ---------- | ---------------- |
  | chafa     | 1.18.0-1.1 | cachyos-extra-v3 |
  | fish      | 4.4.0-1.1  | cachyos-extra-v3 |
  | bash      | 5.3.9-2    | cachyos-v3       |
  | hyperfine | 1.20.0-1.1 | cachyos-extra-v3 |

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

    Line Discipline 通过 termios 结构体维护控制字符映射表, 详细的 termios 配置可参考 [Linux man-pages: termios(3)](https://man7.org/linux/man-pages/man3/termios.3.html).

### Shell

Shell 是运行在 TTY Slave 端的命令行解释器, 负责:

- 解析用户输入的命令;

- 通过 `fork()` 和 `exec()` 等系统调用来启动子进程或执行内置命令;

- 将子进程的输出通过 TTY Slave 端发送回终端模拟器的 Master 端进行显示;

- 管理前台和后台进程组, 处理信号传递等.

值得注意的是, Canonical Mode 下 shell 中输入命令后的"回显"并不是 shell 自己完成的, 而必须通过 TTY 的 Line Discipline. 当用户输入字符时, Line Discipline 会将其显示在屏幕上, 从而完成"回显".

### 终端模拟器

终端模拟器是负责转换 I/O 数据流与渲染显示的 GUI 应用程序. 它通过 PTY Master 端与 Shell 及其他命令行程序通信.

- **输入**: 捕获键盘事件, 转换为字节流写入 PTY Master 文件描述符;

- **输出**: 从 PTY Master 读取字节流, 解析控制序列;

- **渲染**: 根据解析结果更新屏幕显示, 包括文本内容, 光标位置, 颜色等.

### PTY 创建流程

1. 终端模拟器调用 `posix_openpt` 获取 Master 端 FD.

2. 内核 devpts 文件系统在 `/dev/pts` 下创建对应的 Slave 端设备节点.

3. 终端模拟器调用 `grantpt()` 设置 Slave 端权限, `unlockpt()` 解锁.

4. 终端模拟器 `fork()` 出子进程调用 `setsid()` 创建新会话并成为会话首进程.

5. 子进程打开 Slave 端并通过 `dup2()` 重定向 stdin/stdout/stderr 到 Slave 端 FD.

6. 子进程执行 Shell, Master 端由终端模拟器持有.

可通过 `ls -l /proc/$$/fd/` 查看当前 Shell 的 PTY Slave 端:

```bash
lrwx------ 1 kolkas kolkas 64 Feb 13 10:19 0 -> /dev/pts/2
lrwx------ 1 kolkas kolkas 64 Feb 13 10:19 1 -> /dev/pts/2
lrwx------ 1 kolkas kolkas 64 Feb 13 10:19 2 -> /dev/pts/2
```

### 控制序列

控制序列是一种特殊的字节序列, 基于不同协议, 用于在终端模拟器中实现各种功能, 如:

- **CSI** (Control Sequence Introducer): 以 `\033[` 开头
  - 光标移动: `\033[<row>;<col>H` 或 `\033[<row>;<col>f`
  - 清屏: `\033[2J`
  - 颜色设置: `\033[38;2;<r>;<g>;<b>m` (前景色), `\033[48;2;<r>;<g>;<b>m` (背景色)

- **OSC** (Operating System Command): 以 `\033]` 开头
  - 设置窗口标题: `\033]0;title\a`
  - 设置剪贴板内容: `\033]52;c;data\a`
  - ITerm2 图片协议: `\033]1337;File=...;...\a`

- **APC** (Application Program Command): 以 `\033_` 开头
  - Kitty 图像协议: `\033_G...;...\033\\`

下一节将会提到的各类图像协议也是通过控制序列实现的.

## 图像协议

即在终端模拟器里显示图片的~~旁门左道~~各类协议, 其中使用较为广泛的有三个:

- **KGP**(非官方简称): [Kitty Terminal Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
- **Sixel**: [Sixel](https://en.wikipedia.org/wiki/Sixel)
- **ITerm2**: [ITerm2 Inline Images Protocol](https://iterm2.com/documentation-images.html)

> 值得一提的是其中 KGP 甚至能被用来在终端模拟器里播放视频, 只需要给 mpv 加上 `--vo=kitty` 参数即可.

> 此处 KGP 仅指代传统 Kitty 图像协议, 不包括其中关于 Unicode Placeholders 的部分.

### 各终端支持情况

不完全统计, 只列举我知道并且确实使用过的.

| Terminal      | KGP | Sixel | ITerm2 |
| ------------- | --- | ----- | ------ |
| Alacritty     | ❌  | ❌    | ❌     |
| Foot          | ❌  | ✅    | ❌     |
| Ghostty       | ✅  | ❌    | ❌     |
| GNOME Console | ❌  | ❌    | ❌     |
| Kitty         | ✅  | ❌    | ❌     |
| Konsole       | ✅  | ✅    | ✅     |
| Rio           | ❌  | ✅    | ❌     |
| Tabby         | ❌  | ✅    | ❌     |
| Warp          | ✅  | ❌    | ❌     |
| WezTerm       | ✅  | ✅    | ✅     |
| Windows Term. | ❌  | ✅    | ❌     |

### 使用方法

- 部分终端模拟器提供了显示图片的小程序/内置功能, 可以通过参数调用, 例如:

  ```bash
  kitty +kitten icat /path/to/image
  ```

  将会使用 KGP 显示图片,

  ```bash
  wezterm imgcat /path/to/image
  ```

  将会使用 ITerm2 图片协议显示图片.

  以上两个指令在其他支持相同协议的终端模拟器同样可用.

- 另一个很好用的通用程序是 [chafa](https://github.com/hpjansson/chafa). 除了自动检测并使用以上三种协议显示图片外, 它还支持以 `symbols` 格式使用 [ANSI 颜色转义序列](https://en.wikipedia.org/wiki/ANSI_escape_code)显示图片的大致样貌, 这很适合在不支持以上任何一种协议的终端模拟器(如 Alacritty)上作为 fallback.

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

  这是大多数终端都会响应的 `DA1` 序列, 用于查询终端特性, 标准响应正则为 `\033\[\?[0-9;]*c`, 但是此处只用于标识 Kitty 图像协议查询序列响应的结束, 其本身具体响应了什么并不重要, 这得益于 KGP "在收到查询序列后必须立即相应, 不能先处理其他输入"的规定. 例如, 如果一次查询返回了 `DA1` 的响应之前没有有效的 KGP 响应, 则可视为该终端模拟器不支持 KGP.

关于更多构造 KGP 控制序列的话题, 会在[后面](#实现)单独展开.

#### Sixel

Sixel 支持情况可以用 `DA1` 查询, 即 `\033[c`. 如响应中分号分隔的数字中包含 `4`, 则可视为支持.

值得注意的一点是, 很多终端复用器(Terminal Multiplexer)如 Tmux / Zellij 也会在 `DA1` 的响应中包含 `4`, 但实际支持情况取决于终端复用器的配置与宿主终端.

#### ITerm2

ITerm2 图片协议本质为 `OSC 1337` 控制序列的 `FILE` 特性. ITerm2 文档虽然提供了[检测方法](https://iterm2.com/feature-reporting/), 但一番测试后发现在我认知范围内的支持 ITerm2 图片协议的终端模拟器上均无法得到有效响应.

但还有其他方法可以实现查询目的. 虽然无法直接查询 `FILE` 特性的支持情况, 但可以通过执行 `OSC 1337` 控制序列中其他副作用和开销较小的查询来间接获知是否支持该控制序列, 进而获知是否支持通过该协议显示图片. 一种常见的方法是查询 `ReportCellSize`, 具体控制序列为 `\033]1337;ReportCellSize\a`. 如果返回了以 `\033]1337;ReportCellSize=` 为前缀的响应, 则可视为通过. 虽然看起来并不怎么健壮, 但根据我自己的测试结果误判可能性很小, 已经足够使用了.

同样的, 上述查询也推荐使用 `DA1` 做哨兵. 由此, 完整的控制序列为: `\033]1337;ReportCellSize\a\033[c`.

#### 3 in 1

不难发现, 用于查询 KGP 和 `OSC 1337` 的控制序列都可以用 `DA1` 做哨兵, 而 `DA1` 本身可以用来查询 Sixel 协议的支持情况. 因此, 三次查询可以被整合到单个控制序列中, 由此得以实现三合一检测脚本:

```bash
#!/usr/bin/env bash

set -euo pipefail

# Ensure in a interactive terminal
[ ! -t 0 ] && exit 0

# Increase timeout for SSH sessions
TIMEOUT=0.3
[[ -n "${SSH_CONNECTION:-}" ]] && TIMEOUT=1.0

# Construct query
KGP_QUERY_ID=$RANDOM
KGP_QUERY_CODE=$(printf "\033_Gi=%d,s=1,v=1,a=q,t=d,f=24;AAAA\033\\" "$KGP_QUERY_ID")
ITERM2_QUERY_CODE=$(printf "\033]1337;ReportCellSize\a")
KGP_EXPECTED_RESPONSE=$(printf "\033_Gi=%d;OK\033\\" "$KGP_QUERY_ID")
ITERM2_EXPECTED_RESPONSE=$(printf "\033]1337;") # followed by "ReportCellSize=...", but only the prefix is enough
FENCE_CODE=$(printf "\033[c")

# Set terminal to raw mode with timeout
stty_orig=$(stty -g)
trap 'stty "$stty_orig"' EXIT INT TERM HUP
stty -echo -icanon min 1 time 0

printf "%s%s%s" "$ITERM2_QUERY_CODE" "$KGP_QUERY_CODE" "$FENCE_CODE" > /dev/tty

support_kgp=0
support_iterm2=0
support_sixel=0

response=""
while true; do
    IFS= read -r -N 1 -t "$TIMEOUT" char || {
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

将会尝试用 KGP 显示一张测试图片, 如果显示成功则说明支持 KGP, 反之则(大概率)不支持.

> [!TIP]
>
> 对于 fish shell, 类似 `cmdA <(cmdB)` 的语法可被替换为 `cmdA (cmdB | psub)`, 因此上述命令在 fish 里可以写为:
>
> ```fish
> bash (curl -fsSL https://tgp.uyani.de/query | psub)
> ```

### 显示效果

先说结论, 在大多数终端模拟器上, KGP ≈ ITerm2 >> Sixel.

Sixel 是三者之中最老的, 颜色格式类似 GIF89a, 只支持索引颜色和单色键透明度, 画面有明显的颗粒感和色带. 如此妥协换来的是三者之中最强的兼容性, 甚至连 Windows Terminal 都支持 Sixel, 可见一斑.

ITerm2 的实现方式很简单粗暴, 它会将图片数据原封不动地交给终端模拟器渲染, 因此实际显示效果极大程度上取决于终端模拟器的实现方式. 不过, 由于终端模拟器能拿到原始的图像二进制数据, 显示效果一般不会比其他二者差.

KGP 既支持直接传输 PNG 二进制数据, 也支持传输 24bit 与 32bit 像素数据, 支持指定 Z-Index 叠加显示, 原生支持动图, 可玩性是三者之中最高的, 显示效果通常也不会差.

### 性能测试

一些简单的测试.

- 固定宽度连续输出53张中到大尺寸(1920x1080到9457x5324不等)JPEG和PNG图片, 取5次耗时平均, 单位为秒.

  | Terminal | KGP   | Sixels | ITerm2 |
  | -------- | ----- | ------ | ------ |
  | Kitty    | 4.486 | -      | -      |
  | Ghostty  | 7.184 | -      | -      |
  | Konsole  | 7.388 | 4.842  | 7.266  |
  | WezTerm  | 4.820 | 6.218  | 5.042  |
  | Foot     | -     | 4.124  | -      |

  说明:
  - 使用 chafa 转换图片为控制序列. 所有耗时包含 chafa 预处理耗时.

  - KGP 使用 32bit RGBA 格式传输.

  - ITerm2 使用 32bit RGBA 以 TIFF 格式传输.

- 连续输出64张小尺寸(50x50以内)PNG图片, 取5次耗时平均, 单位为毫秒.

  | Terminal | KGP   | Sixels | ITerm2 |
  | -------- | ----- | ------ | ------ |
  | Kitty    | 975.0 | -      | -      |
  | Ghostty  | 724.9 | -      | -      |
  | Konsole  | 744.6 | 781.6  | 768.1  |
  | WezTerm  | 970.4 | 980.2  | 962.0  |
  | Foot     | -     | 719.6  | -      |

  说明:
  - 使用 chafa 转换图片为控制序列. 所有耗时包含 chafa 预处理耗时.

  - KGP 使用 32bit RGBA 格式传输.

  - ITerm2 使用 32bit RGBA 以 TIFF 格式传输.

- 转换 PNG 图片为对应协议数据传输的大小比较.
  - chafa:

    ```bash
    chafa -f <FORMAT> -s 100x <IMAGE>
    ```

    | Protocol | 原始大小(B) | 控制序列大小(B) | 格式            | 编码   |
    | -------- | ----------- | --------------- | --------------- | ------ |
    | KGP      | 8,400,484   | 3,335,131       | 32bit RGBA      | Base64 |
    | Sixel    | 8,400,484   | 1,227,194       | 256 color       | 7bit   |
    | ITerm2   | 8,400,484   | 3,285,617       | 32bit RGBA TIFF | Base64 |

  - kitty +kitten icat:

    ```bash
    kitty +kitten icat --place "100x32768@0x0" <IMAGE>
    ```

    | Protocol | 原始大小(B) | 控制序列大小(B) | 格式      | 编码         |
    | -------- | ----------- | --------------- | --------- | ------------ |
    | KGP      | 8,400,484   | 1,182,033       | 24bit RGB | zlib, Base64 |

  - idog (自己写的)

    ```bash
    idog <IMAGE>
    ```

    | Protocol | 原始大小(B) | 控制序列大小(B) | 格式 | 编码         |
    | -------- | ----------- | --------------- | ---- | ------------ |
    | KGP      | 8,400,484   | 11,152,402      | PNG  | zlib, Base64 |

    该程序在此处的作用为将 PNG 原始数据通过 zlib 压缩后以 4096 字节为单位分块后分为多个控制序列传输.

  - wezterm imgcat:

    ```bash
    wezterm imgcat <IMAGE>
    ```

    | Protocol | 原始大小(B) | 控制序列大小(B) | 格式 | 编码   |
    | -------- | ----------- | --------------- | ---- | ------ |
    | ITerm2   | 8,400,484   | 11,200,685      | PNG  | Base64 |

    ```bash
    wezterm imgcat --width 100 <IMAGE>
    ```

    | Protocol | 原始大小(B) | 控制序列大小(B) | 格式 | 编码   |
    | -------- | ----------- | --------------- | ---- | ------ |
    | ITerm2   | 8,400,484   | 11,200,695      | PNG  | Base64 |

    是的, 限制宽度并不会减少控制序列的大小, 反而会因为 `,width=100` 元数据增加 10 字节.

### KGP Unicode Placeholders

#### 特性

Unicode Placeholders 是 Kitty 图像协议的一个独特功能, 它允许使用占位符嵌入图像, 这提供了一些有意思的特性:

- 可在任意支持 Unicode 字符和 `CSI` 前景色控制序列的终端应用中显示图像.

- 对于不支持该协议的终端模拟器, 对应位置会显示为相同大小的(彩色)不明字符, 避免格式错乱.

- 对于一张图像, 可以仅传递一次数据, 后续通过相同 ID 的占位符即可重复引用相同图像.

- 可以通过仅输出部分占位符来实现"裁剪"显示图像的效果.

- 更改终端中字体大小时已经显示的图像会被同比例缩放, 而不会像传统 KGP 那样保持原来的大小不变.

- 只需要简单的清屏即可删除已经显示的图像, 不需要发送额外的控制序列.

#### 使用

该功能可通过 `kitty +kitten icat` 的 `--unicode-placeholders` 参数启用.

如果想自己从头实现控制序列编码, Unicode Placeholders 相较传统办法最大的不同就是在 `APC` 后输出多行由 `U+10EEEE` 和变音符号组成的 Unicode 字符串, 其中 `U+10EEEE` 为占位字符, 变音符号用于标识行号和列号, 文本前景色用于编码图片 ID, 下划线颜色用于编码放置 ID, 背景色用于...充当背景色. 更多细节可以参考 [Kitty 官方文档](https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders).

虽然这个功能很有趣, 但就目前而言真正实现它的终端模拟器寥寥无几, 在[前面的表格](#各终端支持情况)中只有 Kitty 和 Ghostty 位于此列, 其他终端模拟器即便支持 KGP, 也只会同时显示占位符和正常的图片, 效果非常诡异.

#### 实现

指编码端的实现. 如前文所说, 该方法和传统方法在前半部分是几乎完全一致的, 因此实现 Unicode Placeholders 的同时也可以~~顺便~~实现 KGP 的基础部分. 以下摘取[前面](#性能测试)提到的 idog 的 Python 部分实现代码.

- 工具函数

  ```python
  import base64
  import random
  import zlib

  def random_ID(max: int = 0xFFFFFF): return random.randint(0, max)
  def base64_encode(data: bytes) -> str: return base64.b64encode(data).decode("ascii")
  def zlib_compress(data: bytes) -> bytes: return zlib.compress(data)
  ```

  以及构造 PNG 数据的函数, 用于 query 和测试.

  ```python
  import struct

  def png_makechunk(type: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + type + data + struct.pack(">I", zlib.crc32(type + data))


  def mock_png_data(width: int, height: int) -> bytes:
      data = b"\x89PNG\r\n\x1a\n"
      # IHDR
      ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
      data += png_makechunk(b"IHDR", ihdr)
      # IDAT
      compressor = zlib.compressobj(level=9, strategy=zlib.Z_DEFAULT_STRATEGY)
      idat = compressor.compress(b"".join(
          b"\x00" + b"\xff\xff\xff\x80" * width for _ in range(height)
      )) + compressor.flush()
      data += png_makechunk(b"IDAT", idat)
      # IEND
      data += png_makechunk(b"IEND", b"")
      return data
  ```

- 构造 KGP 检测序列

  可以大致分为三个部分:
  - 检测是否支持 KGP
  - 检测是否支持 Unicode Placeholders
  - 检测是否支持 Shared Memory 作为传输介质

  其中有不少重复代码, 可以先进行抽象:

  ```python
  import re
  import os
  import sys
  import termios
  from select import select

  def do_query(code: str, expected_response: re.Pattern, fence_response: re.Pattern, timeout: float = -1) -> bool:
      """Helper function to send a query and wait for the expected response"""
      if timeout < 0:
          timeout = 1 if os.environ.get("SSH_TTY") else 0.1

      fd = sys.stdin.fileno()
      if not os.isatty(fd):
          return False

      old_settings = termios.tcgetattr(fd)
      response = ""

      try:
          new_settings = termios.tcgetattr(fd)
          # Disable canonical mode and echo
          new_settings[3] = new_settings[3] & ~termios.ICANON & ~termios.ECHO
          termios.tcsetattr(fd, termios.TCSANOW, new_settings)

          sys.stdout.write(code)
          sys.stdout.flush()

          success = False
          while True:
              # Set a timeout to prevent blocking indefinitely
              r, w, e = select([fd], [], [], timeout)
              if not r:
                  break

              char = os.read(fd, 1)
              if not char:
                  break

              response += char.decode('utf-8', errors='ignore')

              if expected_response.search(response):
                  success = True

              if fence_response.search(response):
                  break

          return success
      except Exception:
          pass
      finally:
          termios.tcsetattr(fd, termios.TCSANOW, old_settings)

      return False
  ```

  检测是否支持 KGP. 该部分原理与[前文](#kgp)所述完全一致:

  ```python
  def query_support() -> bool:
      query_id = random_ID(0xFFFFFFFF)
      query_code = f"\033_Gi={query_id},s=1,v=1,a=q,t=d,f=24;AAAA\033\\"
      expected_response = re.compile(rf"\033_Gi={query_id};OK\033\\")
      fence_code = "\033[c"
      fence_response = re.compile(r"\033\[\?[0-9;]*c")

      return do_query(query_code + fence_code, expected_response, fence_response)
  ```

  检测是否支持 Unicode Placeholders. KGP 并未针对此功能提供专门的查询方法, 但是如[前文](#使用)所说, 支持该功能的终端模拟器很少, 因此可以通过在检测是否支持 KGP 的基础上添加对终端模拟器特有的环境变量的检查来实现:

  ```python
  def query_unicode_placeholder_support() -> bool:
      if os.environ.get("KITTY_PID") or os.environ.get("GHOSTTY_SHELL_FEATURES"):
          return query_support()
      return False
  ```

  类似 `KITTY_PID` 和 `GHOSTTY_SHELL_FEATURES` 这样的环境变量(主观上似乎)比 `TERM` 更可靠. 并且需要注意的是即便明确知道所使用的终端模拟器支持该协议, 最好也用控制序列进行一次验证, 因为终端复用器/配置/特殊环境可能导致实际支持情况与预期不符.

  检测是否支持 Shared Memory 作为传输介质:

  ```python
  from pathlib import Path
  from multiprocessing import shared_memory, resource_tracker

  def query_shared_memory_support(format: str = "32") -> bool:
      # Mock data
      size = 0
      data = b""

      if format == "32":
          size = 4
          data = b"\x00\x00\x00\x00"
      elif format == "24":
          size = 3
          data = b"\x00\x00\x00"
      elif format == "100":
          data = mock_png_data(1, 1)
          size = len(data)
      else:
          raise ValueError(f"Unsupported format: {format}")

      query_id = random_ID(0xFFFFFFFF)
      memory_name = f"idog_{query_id}"
      encoded_memory_name = base64_encode(memory_name.encode("utf-8"))
      shm: shared_memory.SharedMemory | None = None
      success = False
      try:
          shm = shared_memory.SharedMemory(name=memory_name, create=True, size=size)
          if shm is None or shm.buf is None:
              return False
          shm.buf[:size] = data
          query_code = f"\033_Gi={query_id},s=1,v=1,a=q,t=s,f={format};{encoded_memory_name}\033\\"
          expected_response = re.compile(rf"\033_Gi={query_id};OK\033\\")
          fence_code = "\033[c"
          fence_response = re.compile(r"\033\[\?[0-9;]*c")
          success = do_query(query_code + fence_code, expected_response, fence_response)
      except Exception:
          success = False
      finally:
          try:
              if shm is not None:
                  shm.close()
                  if Path(f"/dev/shm/{shm.name}").exists():
                      shm.unlink()
                  else:
                      # shm unlinked by terminal
                      resource_tracker.unregister(f"/{shm.name}", "shared_memory")
          except Exception:
              pass

      return success
  ```

  需要注意的是, 如果终端模拟器支持 Shared Memory, 则会在数据传输完成后**主动**删除对应的 Shared Memory, 因此需要在 finally 里先检查 Shared Memory 是否已经被删除, 再决定是否需要调用 `unlink`. 如果确认不需要手动 unlink, 则可以调用 `resource_tracker.unregister` 来避免 Python 进程退出时发出警告.

- 基础序列构造

  ```python
  import fcntl
  import array
  import termios
  import sys
  from pathlib import Path
  from PIL import Image
  from multiprocessing import resource_tracker, shared_memory


  class KGPEncoderBase:
      image_id: int
      # Original image
      image: Image.Image
      # Resized image that fits the terminal dimensions
      resized_image: Image.Image

      # Displayed image dimensions in terms of character cells
      displayCols: int
      displayRows: int

      def __init__(self, path: Path):
          self._init_id()
          self._init_image(path)
          self._init_size()

      def _init_id(self) -> None:
          """Initialize a random image ID"""
          self.image_id = random_ID(0xFFFFFFFF)

      def _init_image(self, path: Path) -> None:
          """Load the image and convert it to a supported pixel format"""
          image = Image.open(path).convert("RGB")
          if image.mode in ("RGBA", "LA") or (image.mode == "P" and "transparency" in image.info):
              self.image = image.convert("RGBA")
          else:
              self.image = image.convert("RGB")

      def _init_size(self, max_cols=-1, max_rows=-1) -> None:
          """Initialize size-related attributes based on the image and terminal dimensions"""
          # Obtain terminal dimensions via ioctl
          buf = array.array('H', [0, 0, 0, 0])
          fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, buf)
          rows, cols, x_pixels, y_pixels = buf
          cell_width = x_pixels / cols
          cell_height = y_pixels / rows

          # Unicode Placeholder method has a maximum size of 289x289 cells
          new_cols = cols
          new_rows = rows
          if max_cols > 0:
              new_cols = min(cols, max_cols)
          if max_rows > 0:
              new_rows = min(rows, max_rows)
          new_x_pixels = cell_width * new_cols
          new_y_pixels = cell_height * new_rows

          # If the image is small enough to fit without resizing
          if self.image.width <= new_x_pixels and self.image.height <= new_y_pixels:
              self.displayCols = int(self.image.width / cell_width)
              self.displayRows = int(self.image.height / cell_height)
              self.displayWidth = self.image.width
              self.displayHeight = self.image.height
              self.resized_image = self.image.copy()
              return

          # Resize while maintaining aspect ratio
          image_aspect = self.image.width / self.image.height
          display_aspect = new_x_pixels / new_y_pixels
          if image_aspect > display_aspect:
              self.displayCols = new_cols
              self.displayRows = int(new_x_pixels / image_aspect / cell_height)
          else:
              self.displayCols = int(new_y_pixels * image_aspect / cell_width)
              self.displayRows = new_rows

          displayWidth = int(self.displayCols * cell_width)
          displayHeight = int(self.displayRows * cell_height)

          self.resized_image = self.image.resize((displayWidth, displayHeight), Image.Resampling.LANCZOS)

      def _shm_name(self) -> str:
          """Generate a unique shared memory name based on the image ID"""
          return f"idog_{self.image_id}"

      def _format_KGP(self, payload: str, options: str, chunk_size: int) -> list[str]:
          """Format the KGP payload into one or more escape sequences based on the chunk size"""
          if len(payload) <= chunk_size:
              return [f"\033_G{options};{payload}\033\\"]
          else:
              ret = [f"\033_G{options},m=1;{payload[:chunk_size]}\033\\"]
              for offset in range(chunk_size, len(payload), chunk_size):
                  chunk = payload[offset:offset + chunk_size]
                  # m=0 for the last chunk, m=1 for all previous
                  m = 1 if offset + chunk_size < len(payload) else 0
                  # The other options only need to be specified in the first chunk, subsequent chunks can omit them
                  ret.append(f"\033_Gm={m};{chunk}\033\\")
              return ret

      def _construct_payload(self, medium: str, compress: bool) -> str:
          """Construct the KGP payload, optionally compressing it"""
          if medium == "d":
              if compress:
                  return base64_encode(zlib_compress(self.resized_image.tobytes()))
              else:
                  return base64_encode(self.resized_image.tobytes())
          if medium == "s":
              shm_name = self._shm_name()
              if not Path(f"/dev/shm/{shm_name}").exists():
                  shm: shared_memory.SharedMemory | None = None
                  data = self.resized_image.tobytes()
                  try:
                      shm = shared_memory.SharedMemory(name=shm_name, create=True, size=len(data))
                      if shm is None or shm.buf is None:
                          raise RuntimeError("Failed to create shared memory segment")
                      shm.buf[:len(data)] = data
                      resource_tracker.unregister(f"/{shm.name}", "shared_memory")
                  except FileExistsError:
                      raise RuntimeError("Shared memory segment already exists")
              return base64_encode(shm_name.encode("utf-8"))
          raise ValueError(f"Unsupported transmission medium: {medium}")

      def _gen_options(self, medium: str, compress: bool) -> str:
          """Generate the options string for the KGP escape sequence"""
          if medium not in ("d", "s"):
              raise ValueError(f"Unsupported transmission medium: {medium}")
          if medium == "s" and compress:
              compress = False  # Disable compression for shared memory transmission
          format = "32" if self.image.mode == "RGBA" else "24"
          # a=T: Action, transmit and display
          # f=...: Pixel format, 24 for RGB, 32 for RGBA, 100 for PNG
          # t=...: transmission medium, d for transmitting data directly in control sequence, s for shared memory
          # c=...,r=...: Specify the image dimensions in terms of character cells
          # s=...,v=...: Specify the image dimensions in pixels, required when transmitting raw pixel data
          # o=z: Enable zlib compression (optional)
          options = f"i={self.image_id},a=T,f={format},t={medium},"\
              f"c={self.displayCols},r={self.displayRows},"\
              f"s={self.resized_image.width},v={self.resized_image.height}"
          if compress:
              options += ",o=z"
          return options

      def construct_KGP(self, medium: str = "d", chunk_size: int = 4096, compress: bool = True) -> list[str]:
          """Construct the KGP escape sequences for the image"""
          if chunk_size <= 0:
              raise ValueError("Chunk size must be a positive integer.")

          options = self._gen_options(medium, compress)
          payload = self._construct_payload(medium, compress)
          ret = self._format_KGP(payload, options, chunk_size)
          return ret

      def delete_image(self) -> str:
          """Construct the escape sequence to delete the image from the terminal"""
          if Path(f"/dev/shm/{self._shm_name()}").exists():
              try:
                  shm = shared_memory.SharedMemory(name=self._shm_name(), create=False)
                  shm.close()
                  shm.unlink()
              except FileNotFoundError:
                  pass  # Already unlinked by terminal
          return f"\033_Ga=d,d=i,i={self.image_id}\033\\"
  ```

  该类接受一个图片路径作为实例化参数, 通过 `ioctl` 获取终端尺寸并计算出合适的显示尺寸, 通过 `PIL` 加载和处理图片, 最后通过 `construct_KGP` 方法生成对应的 KGP 控制序列列表. 并包含一些额外特性:
  - 选择是否启用 zlib 压缩. 仅在传输介质为直接传输数据(`d`)时有效.

  - 选择传输介质类型. 目前支持直接在控制序列里传输数据(`d`)和通过 Shared Memory 传输(`s`)两种方式.

  - 清除显示的图片. 同时也会尝试删除对应的 Shared Memory.

  对于 Shared Memory 模式, 需要注意的是当发送控制序列后, 该 Shared Memory 的所有权可以被视为**转移**给了终端模拟器, 因此如果终端模拟器不支持 KGP 或环境不支持 Shared Memory, 则极有可能发生泄漏. 因此在使用 Shared Memory 作为传输介质时, 最好先通过类似 `query_shared_memory_support` 的方法进行一次验证, 确保当前环境和终端模拟器确实支持该功能, 再进行后续操作.

- Unicode Placeholders

  有了基类, 后续就方便多了. 只需要修改几个方法即可.

  ```python
  KGP_PLACEHOLDER = "\U0010EEEE"
  # https://sw.kovidgoyal.net/kitty/_downloads/f0a0de9ec8d9ff4456206db8e0814937/rowcolumn-diacritics.txt
  KGP_DIACRITICS = (
      "\u0305\u030D\u030E\u0310\u0312\u033D\u033E\u033F\u0346\u034A"
      ...)


  class KGPEncoderUnicode(KGPEncoderBase):
      def _init_id(self):
          """Initialize a smaller random image ID"""
          self.image_id = random_ID(0xFFFFFF)

      def _init_size(self, max_cols=-1, max_rows=-1) -> None:
          if max_cols > 0:
              max_cols = min(max_cols, len(KGP_DIACRITICS))
          else:
              max_cols = len(KGP_DIACRITICS)
          if max_rows > 0:
              max_rows = min(max_rows, len(KGP_DIACRITICS))
          else:
              max_rows = len(KGP_DIACRITICS)
          super()._init_size(max_cols, max_rows)

      def _gen_options(self, medium: str, compress: bool) -> str:
          """Generate the options string for the KGP escape sequence"""
          options = super()._gen_options(medium, compress)
          # q=2: Suppress response, required when using Unicode Placeholders
          # U=1: Enable Unicode Placeholders
          options += ",q=2,U=1"
          return options

      def construct_unicode_placeholders(self) -> list[str]:
          """Construct the Unicode placeholders for the image"""
          # Using 24-bit True Color foreground to encode the image ID,
          # the maximum id is therefore 0xFFFFFF, which is likely enough
          image_id_str = f"\033[38;2;{(self.image_id >> 16) & 0xFF};{(self.image_id >> 8) & 0xFF};{self.image_id & 0xFF}m"
          ret = []
          for i in range(self.displayRows):
              line = image_id_str

              # Placehoder + Row Diacritic + Column Diacritic
              line += f"{KGP_PLACEHOLDER}{KGP_DIACRITICS[i]}{KGP_DIACRITICS[0]}"
              for _ in range(1, self.displayCols):
                  # Col index and row index will be automatically determined
                  line += KGP_PLACEHOLDER

              line += "\033[39m"
              ret.append(line)

          return ret

  ```

  唯一新增的方法是 `construct_unicode_placeholders`, 该方法会生成一个字符串列表, 每个字符串代表一行, 所有行的开头是设置前景色的控制序列, 用于编码图片 ID, 后续会通过占位符的前景色来识别该占位符对应的图片. 每个占位符由一个占位字符和两个变音符号组成, 其中一个变音符号用于编码行号, 另一个用于编码列号, 每行的非首个占位符可省去变音符号. 由于变音符号的数量有限, 因此 Unicode Placeholders 的**最大显示尺寸**为 289x289 字符单元. 每行都会重新设置与重置前景色, 以保证最大程度的兼容性.

- 调用实例

  ```python
  image_path = Path("test.png")

  if not query_support():
      sys.stderr.write("KGP not supported in this terminal.\n")
      sys.exit(1)

  medium = "s" if query_shared_memory_support() else "d"
  placeholders = []
  encoder = None

  sys.stderr.write("Transmission medium: " + ("Shared Memory\n" if medium == "s" else "Direct Data\n"))

  if query_unicode_placeholder_support():
      sys.stderr.write("Using Unicode Placeholders\n")
      encoder = KGPEncoderUnicode(image_path)
      placeholders = encoder.construct_unicode_placeholders()

  else:
      sys.stderr.write("Using KGP without Unicode Placeholders\n")
      encoder = KGPEncoderBase(image_path)

  for seq in encoder.construct_KGP(medium=medium):
      print(seq, end="")
  sys.stdout.flush()

  for i, line in enumerate(placeholders):
      print(line, end="" if i == len(placeholders) - 1 else "\n")

  input()
  encoder.delete_image()
  ```

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

  但值得注意的是, 此方法不保证完全不会出问题, 例如我曾经遇到过在服务器如此配置后 vscode 远程连接时 Remote-SSH 插件卡在 "Setting up SSH Host" 无法正常建立连接的情况.

  一种更为妥协的办法是通过

  ```bash
  type f &>/dev/null || alias f="exec fish"
  ```

  设置 `f` 别名(如果没有被占用的话), 在进入 bash 后手动敲击 `f` + Enter 切换到 fish. 虽然麻烦些但明显更为可靠.

## GPU 加速

虽然听起来高大上, 也是很多终端模拟器写在 Description 里的核心特性之一, 但是在实际使用场景中就我个人经验而言影响并没有想象中那么巨大. 终端模拟器所主要面对的仍然是纯文本场景, 最多换一换颜色, 滚一滚屏幕, 这对于现代 CPU 来说并没有很吃力. 但"更好的渲染性能"甚至不是 GPU 加速的唯一目的, 例如 Ghostty 可以通过 shader 实现各种炫酷的视觉效果, 渲染性能反而是次要的. 因此, 在选择终端模拟器时, 是否支持 GPU 加速可以作为一个参考因素, 但并不应该是唯一的决定因素.

## 单独聊聊

### Ghostty

如果说终端模拟器也要有自己的原神, 那么 Ghostty 无疑是最合适的候选之一. 关于这个终端模拟器可以聊的东西有很多, 这里先简单列一些 Pro 和 Con.

- Pros
  - Terminal Inspector

    独一份的调试窗口. 虽然对我来说大多数时候都没什么实际作用, 但总会有用到的时候, 具有一定不可替代性~~, 并且真的很酷~~.

  - 自定义 Shader

    简单如光标跳转动画, 复杂如全局光效, 从 CRT 到 Glitchy, 可玩性极高.
    - [0xhckr/ghostty-shaders](https://github.com/0xhckr/ghostty-shaders) 包含很多现成的 shader, 可以直接拿来使用.

    - [KroneCorylus/ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground) 是一个 shader 预览和编辑器, 同时提供了包括光标跳转动画在内的 shader.

- Cons
  - 不稳定

    尽管从首个正式 Release 开始计算已经过了一周岁生日, 但 Ghostty 目前仍处于早期版本, 使用过程中还是会遇到各种奇奇怪怪的问题, 并不适合作为主力终端模拟器使用.

  - 启动速度

    相比其他相同定位的终端模拟器, Ghostty 的冷启动速度可以说奇慢无比. 尽管[文档](https://ghostty.org/docs/linux/systemd)有提到在启动 `app-com.mitchellh.ghostty.service` 服务的前提下使用 `ghostty +new-window` 加快启动速度, 但这同时放弃了很多灵活性. 例如, `ghostty +new-window` 无法与 `-e` 参数一起使用, 非冷启动的实例也难以同步环境变量, 以 systemd 服务启动的 ghostty 甚至无法自动同步在 WM 如 niri 处配置的环境变量. 虽然这些缺失的灵活性可以通过其他一些方法弥补, 但这确实是使用其他终端模拟器时不曾面对的问题.

    简单测试:

    ```bash
    hyperfine --warmup 3 'kitty -e echo' 'ghostty -e echo' 'foot -e echo'
    ```

    ```
    Benchmark 1: kitty -e echo
      Time (mean ± σ):     216.0 ms ±   6.2 ms    [User: 117.9 ms, System: 92.9 ms]
      Range (min … max):   204.2 ms … 224.6 ms    13 runs

    Benchmark 2: ghostty -e echo
      Time (mean ± σ):     643.5 ms ±  11.4 ms    [User: 561.1 ms, System: 125.7 ms]
      Range (min … max):   627.3 ms … 660.6 ms    10 runs

    Benchmark 3: foot -e echo
      Time (mean ± σ):      32.3 ms ±   1.4 ms    [User: 35.6 ms, System: 8.8 ms]
      Range (min … max):    28.5 ms …  39.3 ms    89 runs
    ```

### Kmscon

这是运行在 Linux TTY 上的终端模拟器, 可以在一定程度上作为传统 TTY 的替代品使用, 提供了诸如复杂字体渲染 / CJK 文字 / 多显示器支持等高级功能. 关于此的话题可以在 [kmscon.md](kmscon.md) 中找到.

### Terminal Multiplexer

不知道, 没用过, 不感兴趣. 偶尔有需求时会用 Zellij 玩一玩, 但没什么重度使用经验, 因此不展开说了.

## References

- [The TTY demystified](https://www.linusakesson.net/programming/tty/)

- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Sixel-Graphics)

- [Kitty Terminal Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)

- [Sixel - Wikipedia](https://en.wikipedia.org/wiki/Sixel)

- [Feature Reporting Spec - ITerm2](https://iterm2.com/feature-reporting/)

- [Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)

- [Fish - ArchWiki](https://wiki.archlinux.org/title/Fish)

- [Systemd and D-Bus - Linux - Ghostty](https://ghostty.org/docs/linux/systemd)
