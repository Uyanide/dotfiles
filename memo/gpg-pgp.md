> 虽说更多时候还是防自己, 但是整一套 GPG 密钥体系真的很酷, 多点安全感也绝不是坏事.

> [!WARNING]
>
> 仅记录我的折腾过程, 并非指南, 并非推荐, 并非技术文档.

## What?

PGP (Pretty Good Privacy) 是一种数据加密和解密的程序, GnuPG (GNU Privacy Guard) 是 PGP 的一个开源实现. GPG, PGP, 真是好名字.

## How?

1. 生成密钥对:

   ```bash
   gpg --full-generate-key
   ```

   按照提示选择密钥类型、大小和有效期, 并输入用户信息 (如姓名和电子邮件地址) 和密码.

2. 列出密钥:

   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

   从中找到刚刚生成的密钥, 例如:

   ```plain
   sec   ed25519/ABCDEF1234567890 2026-01-01 [SC]
         1234567890ABCDEF1234567890ABCDEF12345678
   uid                 [ultimate] Uyanide <email@domain.tld>
   ssb   cv25519/1234567890ABCDEF 2026-01-01 [E]
   ```

   其中 `ABCDEF1234567890` 是主密钥 ID, 记下来.

3. 生成撤销证书:

   ```bash
   gpg --output revoke.asc --gen-revoke ABCDEF1234567890
   ```

   将 `ABCDEF1234567890` 替换为主密钥 ID. 撤销证书用于在密钥泄露或不再使用时撤销该密钥, 请**离线**妥善保管 `revoke.asc` 文件.

> [!IMPORTANT]
>
> **离线** 指的是不连接互联网的环境. 最好将撤销证书存储在物理介质上, 如 USB 驱动器或打印出来, 并放在安全的地方.

4.  生成子密钥

    GPG 密钥有四种主要功能标志:

    - `C` (Certify): 用于签署其他密钥.
    - `S` (Sign): 用于签署数据 (如电子邮件或 git 提交).
    - `E` (Encrypt): 用于加密数据.
    - `A` (Authenticate): 用于身份验证 (如 SSH).

    主密钥通常只用于 `C` 功能, 默认也会有 `S` 功能. 但是在最佳实践中, 主密钥应只用于 `C` 功能, 其他三种功能由至少三个不同的子密钥承担, 日常使用也多使用子密钥而非主密钥.

    - 对于 `S` 和 `E` 功能, 可以通过以下命令添加子密钥:

      ```bash
      gpg --edit-key ABCDEF1234567890
      ```

      进入交互式界面后, 使用以下命令:

      - `addkey`: 添加子密钥, 按照提示选择密钥类型和大小.
      - `save`: 保存并退出.

    - 对于 `A` 功能, 可能需要启用 expert 模式:

      > 什么, 专家? 我?

      ```bash
      gpg --expert --edit-key ABCDEF1234567890
      ```

      进入交互式界面后, 使用以下命令:

      1. `addkey`: 添加子密钥
      2. 选择 `(set your own capabilities)` 后缀的选项作为密钥类型.
      3. 通过交互式操作仅保留 `A` 功能.
      4. `Q` 完成密钥功能的设置, 并按照提示选择密钥类型和大小.
      5. `save`: 保存并退出.

> [!NOTE]
>
> 和更换麻烦的主密钥相比, 子密钥建议设置为较短的有效期.

> [!TIP]
>
> 即使日常使用不同的子密钥做不同的事, 但实际分享公钥或配置软件时使用的公钥以及密钥 ID 通常仍然是主密钥的公钥和密钥 ID, 而非具体所使用的子密钥的公钥和密钥 ID.

5. 添加用户 ID

   有些时候需要添加额外的用户 ID (如其他电子邮件地址).

   ```bash
   gpg --edit-key ABCDEF1234567890
   ```

   进入交互式界面后, 使用以下命令:

   - `adduid`: 添加新的用户 ID, 按照提示输入姓名和电子邮件地址.
   - `save`: 保存并退出.

> [!NOTE]
>
> 很多平台要求密钥包含在平台经过验证的电子邮件地址, 否则无法使用该密钥进行加密通信.

6. 导出公钥

   ```bash
   gpg --armor --export ABCDEF1234567890 > publickey.asc
   ```

   将 `ABCDEF1234567890` 替换为主密钥 ID. 这会将公钥导出到 `publickey.asc` 文件中, 可以将其大大方方地分享给他人.

> [!IMPORTANT]
>
> 每次完成对已有 GPG 密钥的修改(如添加用户 ID, 添加子密钥等)后, 都需要重新导出和更新公钥.

7. 导出主密钥的私钥

   如果遵循最佳实践, 主密钥的私钥不应该长期保存在本地, 而只在需要时导入使用.

   导出所有私钥到文件:

   ```bash
   gpg --export-secret-keys --armor ABCDEF1234567890 > masterkey.asc
   gpg --export-secret-subkeys --armor ABCDEF1234567890 > subkeys.asc
   ```

   随后移除本地所有私钥:

   ```bash
   gpg --delete-secret-keys ABCDEF1234567890
   ```

   再导入先前导出的子私钥:

   ```bash
   gpg --import subkeys.asc
   ```

   验证:

   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

   如果输出的第一行变为 `sec#` 开头, 则表示主密钥的私钥已从 keyring 中移除, 只剩下其 Stub.

   请妥善**离线**保管 `masterkey.asc`, 它是恢复主密钥的唯一途径.

> [!IMPORTANT]
>
> 与 SSH 密钥不同, GPG 密钥应在多设备间同步, 以便在任何设备上都能向别人验证自己的身份以及进行加密通信.

8. 设置信任等级

   为了让 GPG 确认密钥是可信的, 有些情况下需要手动为其设置信任等级.

   ```bash
   gpg --edit-key ABCDEF1234567890
   ```

   进入交互式界面后, 使用以下命令:

   - `trust`: 选择信任等级, 例如 `5 = I trust ultimately`.
   - `save`: 保存并退出.

## Why?

举个例子, 使用 GPG 密钥对 git 提交进行签名, 参见 Github 文档: [Adding a GPG key to your GitHub account](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account) 和 [Telling Git about your signing key](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)

## One More Thing ...

通过 gpg-agent, GPG 密钥可以作为 SSH 密钥使用, 这~~真的很酷~~统一了密钥管理的同时也增加了一些安全性. 论使用体验其实目前的 [ssh-init](../config/scripts/.local/scripts/ssh-init) 方案已经足够满足我的要求了, ~~但它真的很酷~~.

总之, 记录一下折腾过程吧.

1. 添加认证子密钥

   参考上文, 添加一个仅带有 `A` (Authenticate) 功能的子密钥.

2. 告诉 GPG 启用 SSH 支持

   编辑 `~/.gnupg/gpg-agent.conf`, 添加或修改以下行:

   ```plain
   enable-ssh-support
   ```

   可选地, 设置缓存有效期 (这对于拥有密码管理系统的桌面环境来说用处不大):

   ```plain
   default-cache-ttl 600
   max-cache-ttl 7200
   ```

3. 绑定密钥

   首先, 获取认证子密钥的 Keygrip:

   ```bash
   gpg --list-secret-keys --with-keygrip ABCDEF1234567890
   ```

   输出类似:

   ```plain
   ssb   ed25519 2026-01-16 [A]
      Keygrip = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

   然后将其写入 `~/.gnupg/sshcontrol` 文件中:

   ```bash
   echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> ~/.gnupg/sshcontrol
   ```

4. 启动!

   参见 [gpg-init](../config/scripts/.local/scripts/gpg-init) 脚本.

   ```bash
   eval $(gpg-init)
   ```

   此时环境变量 `SSH_AUTH_SOCK` 已指向 gpg-agent 提供的 SSH 代理套接字, 可以像使用普通的 ssh-agent 一样使用 GPG 代理进行 SSH 认证.

5. 获取公钥

   获取 SSH 公钥以添加到远程服务器或服务:

   ```bash
   ssh-add -L
   ```
