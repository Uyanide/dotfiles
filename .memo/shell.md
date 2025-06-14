## 登陆 shell

登陆 shell 是指用户通过终端登录系统时启动的 shell，通常是用户登录时执行的第一个 shell，可以通过`grep "^$(whoami):" /etc/passwd`查看。

登陆 shell 为 bash 时，在登陆时会检索

-   `/etc/profile`

并加载，并会加载以下第一个存在的用户配置文件：

-   `~/.bash_profile`
-   `~/.bash_login`
-   `~/.profile`

所有全局环境变量以及其他非交互配置（如 ssh-agent）都可以写进这些文件。

## 非登陆 shell

非登陆 shell 是指用户在已经登录的情况下启动的 shell，通常是通过终端仿真器或其他方式打开的 shell。

非登陆 shell 为 bash 时，会先加载`/etc/bash.bashrc`，然后加载用户的`~/.bashrc`文件。

对于非登陆 shell 为 fish 的情况，则会先加载`/etc/fish/conf.d`以及`/etc/fish/config.fish`，
然后加载用户的`~/.config/fish/conf.d`以及`~/.config/fish/config.fish`。

非登陆 shell 会继承登陆 shell 的环境变量，但不会加载登陆 shell 的配置文件。

## 当前做法

桌面端将登陆 shell 设置为 bash，对于终端模拟器显式指定 shell 为 fish，并禁用 conf.d 目录下的配置文件。

服务器端同样将登陆 shell 设置为 bash，并在.bashrc 中启动 fish，同样不使用 conf.d 目录下的配置文件。
