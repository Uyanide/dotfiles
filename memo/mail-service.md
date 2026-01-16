> 公共邮箱服务显然已经足够用了，但是用自己的域名收发邮件真的很酷

> [!WARNING]
>
> 仅记录我的折腾过程, 并非指南, 并非推荐, 并非技术文档.

## 需要什么

1. 一个中意的域名.

   下文中将使用 `domain.tld` 作为示例域名, 使用 `me@domain.tld` 作为示例邮箱.

2. DNS 服务, 需要包含以下记录类型的支持:

   - MX
   - TXT
   - A

3. 一个拥有公网 IP 和充足空闲资源的服务器, 并且(至少)需要开通以下 TCP 端口:

   - 25
   - 993
   - 587

   > 据说很多云服务商屏蔽了 25 端口, 但我用的并没有. 赞美 IONOS!

   同时, 最好支持 rDNS, 也就是把 IP 反解析到域名.

   > 赞美 IONOS!

   下文中将使用 `11.45.1.4` 作为服务器的公网 IP 地址.

4. SMTP 服务商, 主要为了 IP 声誉, 否则发的邮件很容易进别人的垃圾箱. 如 [Resend](https://resend.com).

## 放开那个 25 端口!

1. 检测 25 端口是否真的开放:

   在服务器上运行:

   ```bash
   sudo nc -l -p 25
   ```

   在另一台机器上运行:

   ```bash
   nc -vz <服务器公网IP> 25
   ```

2. 解决占用:

   我的服务器是 Debian 13 系统, 默认使用 `exim4` 作为邮件传输代理(MTA). 它监听 127.0.0.1:25, 因此除了在防火墙里放行 25 端口外, 还需要禁用 `exim4`.

   ```bash
   sudo systemctl disable --now exim4
   ```

   如果确实需要系统内部通信, 例如 `cron` 发送邮件通知, 可以安装 `ssmtp` 或 `msmtp` 之类的轻量级 MTA, 参见 [后续章节](#exim4-我呢).

## 注册 SMTP 服务

此类服务可以大致理解为"帮你发邮件的中介", 他们有一大堆 IP 地址, 这些地址的声誉都不错, 因此用他们发信的话, 邮件更容易送达收件箱而不是自动进入垃圾箱.

我此次用的是 [Resend](https://resend.com), 其他类似服务还有 [SendGrid](https://sendgrid.com), [Mailgun](https://www.mailgun.com) 等等.

大体分为这样几步:

1. 注册账号, 并完成邮箱验证.

2. 添加发信域名, 并获取 DNS 记录值.

3. 在 DNS 服务商处添加相应的 DNS 记录.

4. 回到 SMTP 服务商处完成域名验证.

5. 创建 API Key 或 SMTP 凭据.

## 配置 DNS 和 rDNS

### 在 DNS 服务商处

除了上述 SMTP 服务商提供的 DNS 记录外, 还需要添加以下记录:

- MX 记录:

  - 主机名: `@`
  - 值: `mail.domain.tld` (假设邮件服务器域名是 `mail.domain.tld`)
  - 优先级: `10`

  这将会是邮件的接收和发送服务器.

- A 记录:

  - 主机名: `mail`
  - 值: `11.45.1.4`

  指向邮件服务器的公网 IP 地址.

其他记录会在启动邮件服务器后配置.

### 在云服务器商处

将服务器 ip 的 rDNS 设置为 `mail.domain.tld`. 虽然使用 Resend 发信, 但是收信时一些发信方也可能会检查 rDNS, 因此最好设置正确, 有备无患.

### 在服务器上

同时, `/etc/hosts` 最好也包含 `mail.domain.tld`.

## 配置邮件服务器

这里使用 [docker-mailserver](https://docker-mailserver.github.io/docker-mailserver/latest/#welcome-to-the-documentation-for-docker-mailserver) 作为邮件服务器. 当然也可以使用其他的, 但是这个比较简单.

### 搞定 SSL

随便什么方法获取包含 `mail.domain.tld` 的 SSL 证书, 放到随便什么记得住的路径下. 我这里直接使用自动续签的泛域名证书了, 放在 `compose.yaml` 同级目录的 `ssl` 目录下, 包含:

- `fullchain.pem`
- `privkey.pem`

如果使用这种方式, 在续签证书后可能需要重启 `docker-mailserver` 容器以加载新证书, 或者用 `cron` 定期重启容器, 例如一周一次:

```cron
0 3 * * 0 docker restart mailserver
```

或者也可以让 `docker-mailserver` 自己申请证书, 但是我的服务器的 `80` 和 `443` 端口都是 `openresty` 的, 并且恰好有合适的证书, 不想折腾了.

### 创建 `compose.yaml`

```yaml
services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail
    domainname: domain.tld
    ports:
      - '25:25' # SMTP
      - '143:143' # IMAP
      - '587:587' # STARTTLS
      - '465:465' # SMTPS
      - '993:993' # IMAPS
      - '127.0.0.1:11334:11334' # Raspamd Web UI
    environment:
      - DMS_DEBUG=0
        # 反垃圾
      - ENABLE_AMAVIS=0
      - ENABLE_OPENDKIM=0
      - ENABLE_OPENDMARC=0
      - ENABLE_POLICYD_SPF=0
      - ENABLE_SPAMASSASSIN=0
      - ENABLE_RSPAMD=1 # 替代上面几个
      - RSPAMD_LEARN=1 # 自动学习垃圾邮件
        # 杀毒, 很占资源, 关掉, 个人服务没必要
      - ENABLE_CLAMAV=0
        # 防爆破
      - ENABLE_FAIL2BAN=1
        # 使用自定义证书
      - SSL_TYPE=manual
        # 与下方挂载路径对应
      - SSL_CERT_PATH=/tmp/ssl/fullchain.pem
      - SSL_KEY_PATH=/tmp/ssl/privkey.pem
        # 使用 Resend 作为中继
      - RELAY_HOST=smtp.resend.com
      - RELAY_PORT=587
      - RELAY_USER=resend
      - RELAY_PASSWORD=re_some_random_api_key
    volumes:
      - ./maildata:/var/mail
      - ./mailstate:/var/mail-state
      - ./maillogs:/var/log/mail
      - ./config/:/tmp/docker-mailserver/
        # 反爆破数据持久化
      - ./fail2ban:/var/lib/fail2ban
        # 自定义 SSL 证书挂载
      - ./ssl:/tmp/ssl:ro
    restart: unless-stopped
```

以上配置中需要修改的地方有:

- `domain.tld`: 替换为真实域名.
- `res_some_random_api_key`: 替换为在 SMTP 服务商处创建的 SMTP 凭据或 API Key.

一些 environment 的解释:

- 如果机器性能孱弱或很在意占用的资源, 可以关掉 [Raspamd](https://docker-mailserver.github.io/docker-mailserver/latest/config/security/rspamd/) 使用老东西:

  - `ENABLE_AMAVIS=1`
  - `ENABLE_OPENDKIM=1`
  - `ENABLE_OPENDMARC=1`
  - `ENABLE_POLICYD_SPF=1`
  - `ENABLE_SPAMASSASSIN=1`
  - `ENABLE_RSPAMD=0`
  - `RSPAMD_LEARN=0`

- 如果垃圾邮件实在太多:

  - `RSPAMD_GREYLISTING=1`

  在第一次接受陌生人邮件时拒绝, 要求对方重试, 这样可以有效减少垃圾邮件, 但会显著增加延迟.

如果要进行进一步配置, 必须先启动容器. 此时会报错, 因为还没有创建邮箱账号. 但不用管, 先让它跑着.

```bash
docker compose up -d
```

### 创建邮箱账号

使用 `docker-mailserver` 自带的脚本创建邮箱账号. 例如创建 `me@domain.tld`:

```bash
docker exec -it mailserver setup email add me@domain.tld <密码>
```

> [!TIPS]
>
> 把密码存在 Shell 历史里并不是个好主意. 可以通过在命令的最前面加一个空格来避免保存到历史记录中(具体取决于所使用的 Shell 和其配置). 或者从 stdin 中读取也是个不错的选择.

其他一些配置命令可以通过 `docker exec -it mailserver setup help` 查看.

### 配置 SPF

SPF 记录用于指定哪些服务器被允许代表该域名发送邮件.

在 DNS 服务商处添加以下记录:

- SPF 记录 (TXT 记录):

  - 主机名: `@`
  - 值: `v=spf1 mx include:resend.com -all` (假设使用 Resend 作为 SMTP 服务商)

  解释:

  - `v=spf1`: 指定 SPF 版本.
  - `mx`: 允许通过 MX 记录指定的服务器发送邮件.
  - `include:resend.com`: 允许 Resend 的服务器发送邮件.
  - `-all`: 硬失败, 未授权的服务器发送邮件时拒绝. 因为发行渠道只有 Resend, 所以这样设置是合理的. 如果希望软失败, 即接受但标记为可疑, 可以使用 `~all`.

### 配置 DKIM

DKIM (DomainKeys Identified Mail) 用于验证邮件的完整性和真实性.

1. 生成 DKIM 密钥:

   ```bash
   docker exec -it mailserver setup config dkim <选择器名称>
   ```

   这会输出公钥, 记下来.

   `<选择器名称>` 可以省略, 默认为 `mail`. 选择器名称用于区分同一域名下的不同 DKIM 密钥.

   如果使用的不是 `rspamd` 而是 `opendkim`, 过程会略有不同. 此时会输出一个容器内路径, 需要到本地的 `./config/opendkim/keys/` 目录下找到对应的公钥文件.

2. 添加 DKIM 记录 (TXT 记录):

   - 主机名: `mail._domainkey`
   - 值: 上一步获取的公钥内容. 大概是这样的:

     ```plain
     v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQ...
     ```

   解释:

   - `mail`: 选择的选择器名称, 与生成密钥时使用的选择器一致.
   - `_domainkey`: 固定值, 指示这是一个 DKIM 记录.

### 配置 DMARC

DMARC 记录用于指定邮件接收方如何处理未通过 SPF 或 DKIM 检查的邮件.

在 DNS 服务商处添加以下记录:

- DMARC 记录 (TXT 记录):

  - 主机名: `_dmarc`
  - `v=DMARC1; p=none; sp=none; rua=mailto:me@domain.tld`

  解释:

  - `v=DMARC1`: 指定 DMARC 版本.
  - `p=none`: 对未通过 DMARC 检查的邮件不采取任何措施.
  - `sp=none`: 对子域名的策略同样为 none.
  - `rua=mailto`: 如果希望收到报告, 可以指定一个邮箱地址.

  在运行一段时间并查看报告无误后, 可以将 `p` 和 `sp` 设置为 `quarantine` 或 `reject`, 以增强防护.

> [!IMPORTANT]
>
> 同一个域名下只能有一个 DMARC 记录.

### 启动!

```bash
docker compose up -d
```

看一眼 log, 没问题的话就可以下一步了.

### Rspamd Web UI

1. 设置密码

   ```bash
   docker exec -it mailserver rspamadm pw -p <密码>
   ```

   会输出以 `$2$` 开头的很长的字符串, 记下来.

2. 创建配置文件

   ```bash
   sudo mkdir -p config/rspamd/override.d
   sudoedit config/rspamd/override.d/worker-controller.inc
   ```

   写入 **(注意分号)**:

   ```plain
   # 前面得到的很长一串
   password = "$2$...";
   ```

3. 重启容器

   ```bash
   docker compose restart mailserver
   ```

4. 访问

   然后就和其他 WebUI 一样了. 可以暴露 11334 端口然后通过 http 访问, 也可以通过 SSH 隧道本地访问, 也可以反向代理, 等等等等, 怎样都好.

## 配置邮件客户端

我并非 TUI 重度爱好者, 所以直接用 Thunderbird 当客户端了.

1. 在添加邮箱的第一个页面, 点击 `MANUAL CONFIGURATION`.

2. Incoming server settings:

   - Protocol: IMAP
   - Server hostname: `mail.domain.tld`
   - Port: `993`
   - SSL: `SSL/TLS`
   - Authentication: `Normal password`

3. Outgoing server settings:

   - Server hostname: `mail.domain.tld`
   - Port: `587`
   - SSL: `STARTTLS`
   - Authentication: `Normal password`

> 为什么是英语? 因为我的 LANG 是 en_US.UTF-8 :)

4. 点击 Test 按钮, 如果一切正常, 会显示成功信息.

5. 输入密码, 完成配置.

现在已经可以试着和其他邮箱互发邮件了!

## exim4: 我呢?

这个, 不需要了. 既然已经有了邮箱服务, 那么继续使用重量级的 `exim4` 就没什么意义了.

> [!NOTE]
>
> 如果不需要系统内部邮件发送功能, 可以放心大胆地跳过本节剩余内容.

1. 可以安装 `ssmtp` 或 `msmtp` 之类的轻量级 MTA, 用于系统内部邮件发送. 这里用 `msmtp` 作为示例:

   ```bash
   sudo apt install msmtp msmtp-mta bsd-mailx
   ```

   这个过程会自动卸载 `exim4`.

2. 创建用于内网发信的邮箱账号:

   ```bash
   docker exec -it mailserver setup email add notification@domain.tld <密码>
   ```

3. 然后创建配置文件 `/etc/msmtprc`:

   ```plain
   defaults
   auth           on
   tls            on
   tls_trust_file /etc/ssl/certs/ca-certificates.crt
   logfile        /var/log/msmtp.log

   account        system-notifier
   host           mail.domain.tld
   port           587
   from           notifier@domain.tld
   user           notifier@domain.tld
   password       <密码>

   account default : system-notifier

   aliases        /etc/aliases
   ```

   这里即使在内网中也使用了 TLS 加密和真实的邮箱与账号. 当然可以通过其他方式绕过限制从而使用任意并不需要真实存在的邮箱地址发信, 但既然存在更安全的实践, 何乐而不为呢.

4. 编辑 `/etc/aliases`, 添加如下内容:

   ```plain
   root: me@domain.tld
   default: me@domain.tld
   ```

   此处的 `me@domain.tld` 替换为希望用于接收系统邮件的邮箱地址.

5. 测试:

   ```bash
   echo "This is a test email from the system." | mail -s "Test Email" root
   ```

   如果一切正常, 你应该会在前面配置的邮箱中收到这封测试邮件.
