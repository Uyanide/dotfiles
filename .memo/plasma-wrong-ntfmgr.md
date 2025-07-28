当安装了其他 notification manager 时，plasma 在启动时可能会选择错误的 notification manager 导致通知中心无法正常工作 <s>(虽然平时也并不怎么在意这玩意，用什么 daemon 都无所谓，只要有通知看就行)</s>

如何知道是否是这种情况呢？以 mako 为例：

1. 先知道 mako 是什么时候被启动的 (或者自己推算时间)：
   ```sh
   journalctl --user -u mako.service --no-pager -g 'Starting'
   ```
2. 查看先后的日志：
   ```sh
   journalctl --user --since '2025-07-29 00:43:16' --until '2025-07-29 00:43:18'
   ```
3. 如果发现类似以下内容：
   ```
   ...
   Jul 29 00:43:17 Artemisia systemd[1080]: Starting Lightweight Wayland notification daemon...
   Jul 29 00:43:17 Artemisia systemd[1080]: Started Lightweight Wayland notification daemon.
   ...
   Jul 29 00:43:17 Artemisia plasmashell[1599]: org.kde.plasma.notificationmanager: Failed to register Notification service on DBus
   ...
   ```
   那就是这种情况了。

解决方法也很简单，启动时屏蔽掉错误的服务，例如：

```sh
systemctl --user mask mako.service
```

或者将 plasmashell 的 notificationmanager 优先级提高：

```sh
mkdir -p ~/.local/share/dbus-1/services/
ln -s /usr/share/dbus-1/services/org.kde.plasma.Notifications.service ~/.local/share/dbus-1/services/org.kde.plasma.Notifications.service
```
