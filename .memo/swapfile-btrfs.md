在 btrfs 分区下使用 swapfile 创建虚拟内存：

1. 创建 swap 子卷 (假定已经挂载到 /mnt)：

```bash
btrfs subvolume create /mnt/@swap
```

2. 创建 swap 文件：

```bash
touch /mnt/@swap/swapfile
```

3. 设置 COW 禁用属性：

```bash
chattr +C /mnt/@swap/swapfile
```

4. 设置 swap 文件大小（例如 16GB）：

```bash
dd if=/dev/zero of=/mnt/@swap/swapfile bs=1M count=16384 oflag=direct
# 可检查属性，确保有 C：
lsattr /mnt/@swap/swapfile
```

5. 设置 swap 文件权限：

```bash
chmod 600 /mnt/@swap/swapfile
```

6. 启用 swap 文件：

```bash
mkswap /mnt/@swap/swapfile
swapon /mnt/@swap/swapfile
# 可检查 swap 状态
swapon --show
```

7. 修改 `/etc/fstab` 以自动挂载 swap 文件：

```conf
# Btrfs @swap subvolume
UUID={btrfs-uuid} /swap btrfs subvol=@swap,defaults,noatime 0 0

# Swap file
/swap/swapfile none swap sw 0 0
```
