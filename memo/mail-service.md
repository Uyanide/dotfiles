> 公共邮箱服务显然已经足够用了，但是用自己的域名收发邮件真的很酷

> [!WARNING]
>
> 仅记录我的折腾过程, 并非指南, 并非推荐, 并非技术文档.

## 要做什么

1. 在自己的服务器上配置邮件服务器, 直接接收邮件;

2. 使用 SMTP 中继服务发送邮件;

3. 配置 SPF/DKIM/DMARC/MTA-STS 等等.

## 需要什么

1. 一个中意的域名.

   下文中将使用 `domain.tld` 作为示例域名, 使用 `mail.domain.tld` 作为邮件服务器域名, 使用 `me@domain.tld` 作为示例邮箱.

2. DNS 服务, (至少)需要支持以下记录类型:
   - A
   - TXT
   - MX

3. SMTP 中继服务.

   也就是帮你发邮件的服务商, 详见后续章节.

4. 一个拥有公网 IP 和充足空闲资源的服务器, 并且(至少)需要开通以下 TCP 端口:

   | 端口 | 用途            | 出站 | 入站 | 说明                                                |
   | ---- | --------------- | ---- | ---- | --------------------------------------------------- |
   | 25   | SMTP            | ❌   | ✅   | 核心传输端口. 如果使用 SMTP 中继服务, 则不需要出站  |
   | 993  | IMAPS           | ❌   | ✅   | 用于邮件客户端收信                                  |
   | 587  | SMTP Submission | ✅   | ✅   | 支持 STARTTLS. 如果使用 SMTP 中继服务, 则也需要出站 |
   | 465  | SMTPS           | ❌   | ✅   | 支持 Implicit SSL/TLS.                              |

   很多云服务商会默认屏蔽 25 端口的出站方向流量, 但这对于使用 SMTP 中继服务的场景来说并不重要, 因为发信时直接连接收件方服务器的并非自己的服务器.

   同时, 最好支持 rDNS, 也就是把 IP 反解析到域名.

   下文中将使用 `1.14.5.14` 作为服务器的公网 IP 地址.

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

> [!TIP]
>
> btw, 如果想测 25 端口出站是否被封, 可以借助类似 gmail 这样的公共邮箱服务测试. 先运行:
>
> ```bash
> host -t mx gmail.com
> ```
>
> 这会输出 google 的 SMTP 服务器地址, 选一个即可, 例如 `smtp.gmail.com`. 然后运行:
>
> ```bash
> nc -vz smtp.gmail.com 25
> ```
>
> 如果显示 Success 就没问题, 反之如果报错或超时, 那么说明 25 端口的出站被封了.

> [!IMPORTANT]
>
> 再次说明, 如果使用 SMTP 中继服务, 25 端口的出站并不重要. 只需要保证入站开放即可.

2. 解决占用:

   我的服务器是 Debian 13 系统, 默认使用 `exim4` 作为邮件传输代理(MTA). 它监听 127.0.0.1:25, 因此除了在防火墙里放行 25 端口外, 还需要禁用 `exim4`.

   ```bash
   sudo systemctl disable --now exim4
   ```

   如果确实需要系统内部通信, 例如 `cron` 发送邮件通知, 可以安装 `ssmtp` 或 `msmtp` 之类的轻量级 MTA, 参见 [后续章节](#exim4-我呢).

## 注册 SMTP 中继服务

此类服务可以大致理解为"帮你发邮件的中介", 他们有一大堆 IP 地址, 这些地址的声誉都不错, 因此用他们发信的话, 邮件更容易送达收件箱而不是自动进入垃圾箱. 并且也可以避免 25 端口出站被封的问题.

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
  - 值: `mail.domain.tld`
  - 优先级: `10`

  这将会是邮件的接收和发送服务器.

- A 记录:
  - 主机名: `mail`
  - 值: `1.14.5.14`

  指向邮件服务器的公网 IP 地址.

其他记录会在启动邮件服务器后配置.

### 在云服务器商处

将服务器 ip 的 rDNS 设置为 `mail.domain.tld`. 虽然未来主要使用 Resend 发信, 但是收信时一些发信方也可能会检查 rDNS, 因此最好设置正确, 有备无患.

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
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
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
        # 杀毒, 很占资源, 关掉
      - ENABLE_CLAMAV=0
        # 防爆破
      - ENABLE_FAIL2BAN=1
        # 禁止伪造发件人
      - SPOOF_PROTECTION=1
        # 启用 MTA-STS
        # - ENABLE_MTM_STS=1
        # 使用自定义证书
      - SSL_TYPE=manual
        # 与下方挂载路径对应
      - SSL_CERT_PATH=/tmp/ssl/fullchain.pem
      - SSL_KEY_PATH=/tmp/ssl/privkey.pem
        # 使用 Resend 作为中继
      - DEFAULT_RELAY_HOST=[smtp.resend.com]:587
      - RELAY_USER=resend
      - RELAY_PASSWORD=res_some_random_api_key
        # 强制使用 ipv4
        # - POSTFIX_INET_PROTOCOLS=ipv4
    volumes:
      - ./maildata:/var/mail
      - ./mailstate:/var/mail-state
      - ./maillogs:/var/log/mail
      - ./config/:/tmp/docker-mailserver/
        # 反爆破数据持久化
      - ./fail2ban:/var/lib/fail2ban
        # 自定义 SSL 证书挂载
      - ./ssl:/tmp/ssl:ro
```

以上配置中**必须**修改的地方有:

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

- `ENABLE_MTA_STS=1`:

  MTA-STS 可以防止中间人攻击, 但配置较为复杂, [下文](#更进一步) 将单独介绍.

- `ENABLE_FAIL2BAN=1`:

  Fail2Ban 用于防止暴力破解邮箱密码, 需要 `NET_ADMIN` 权限, 挂载 `./fail2ban` 目录用于保存状态.

- `DEFAULT_RELAY_HOST=[smtp.resend.com]:587`

  中括号用于跳过 MX 查找直接解析 A 记录, 这对于连接明确的 SMTP 中继服务效率更高且更稳定.

- `POSTFIX_INET_PROTOCOLS=ipv4`:

  如果服务器的 IPv6 配置不完善, 可以强制 Postfix 仅使用 IPv4.

如果要进行进一步配置, 必须先启动容器. 此时会报错, 因为还没有创建邮箱账号. 但不用管, 先让它跑着.

```bash
docker compose up -d
```

### 创建邮箱账号

使用 `docker-mailserver` 自带的脚本创建邮箱账号. 例如创建 `me@domain.tld`:

```bash
docker exec -it mailserver setup email add me@domain.tld <密码>
```

> [!TIP]
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

我并非 TUI 重度爱好者, 日常用 Thunderbird 当客户端.

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

   或使用安全性更高的 SMTPS:
   - Server hostname: `mail.domain.tld`
   - Port: `465`
   - SSL: `SSL/TLS`
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

2. 创建用于内网发信的邮箱地址:

   ```bash
   docker exec -it mailserver setup email add notification@domain.tld <密码>
   ```

3. 然后创建配置文件 `/etc/msmtprc`:

   ```plain
   defaults
   auth           on
   tls            on
   tls_starttls   off
   tls_trust_file /etc/ssl/certs/ca-certificates.crt
   logfile        /var/log/msmtp.log

   account        system-notifier
   host           mail.domain.tld
   port           465
   from           notifier@domain.tld
   user           notifier@domain.tld
   password       <密码>

   account default : system-notifier

   aliases        /etc/aliases
   ```

   可替换的部分:
   - `system-notifier`: 账户名称, 随便取.

   - `mail.domain.tld`: 邮件服务器地址.

   - `465`: 端口, 也可以使用 `587` 并将 `tls_starttls` 设置为 `on`. 前者使用更安全的 SMTPS, 后者使用 STARTTLS.

   - `notifier@domain.tld`: 用于发信的邮箱地址, 这里使用刚才创建的地址.

   - `<密码>`: 刚才创建地址时设置的密码.

   - `/var/log/msmtp.log`: 日志文件路径, 注意文件权限.

   上述配置使用了 TLS 加密和真实的邮箱与账号. 当然可以通过其他方式绕过限制从而使用任意并不需要真实存在的邮箱地址发信, 但既然存在更安全的实践, 何乐而不为呢.

4. 编辑 `/etc/aliases`, 添加如下内容:

   ```plain
   root: me@domain.tld
   default: me@domain.tld
   ```

   将 `me@domain.tld` 替换为希望用于接收系统邮件的邮箱地址.

5. 测试:

   ```bash
   echo "This is a test email from the system." | mail -s "Test Email" root
   ```

   如果一切正常, 你应该会在前面配置的邮箱客户端中收到这封测试邮件.

## Catch'em All!

如果希望接收发往不存在邮箱地址的邮件, 可以启用 Catch-all 功能. 方法也很简单, 使用 alias 即可:

```bash
docker exec -it mailserver setup alias add @domain.tld me@domain.tld
```

将其中 `me@domain.tld` 替换为希望接收这些邮件的真实邮箱地址即可.

## 更进一步

MTA-STS (Mail Transfer Agent Strict Transport Security) 通过强制要求发送方使用加密连接发送邮件防止中间人攻击, 对个人邮箱来讲~~看起来其实没啥大用但总归~~是个加分项, 并且确实会让邮箱服务变得更酷.

> [!IMPORTANT]
>
> 使用 SMTP 中继服务发送邮件时, MTA-STS 并不会生效, 因为发送方并非直接连接到自己的邮件服务器. 但是对于入站邮件来说, MTA-STS 依然有效.

1. 前置要求

   除了 [开头](#需要什么) 中提到的要求外, 还需要:
   - 部署 HTTPS 静态网站的能力, 用于托管 MTA-STS 策略文件, 且该文件必须通过 HTTPS 提供.

   - 将 `mta-sts.domain.tld` 指向该静态网站的能力, 且访问时返回的 SSL 证书中的 CN 或 SAN 必须包含 `mta-sts.domain.tld`.

2. 新增 DNS 记录
   - A 记录:
     - 主机名: `mta-sts`
     - 值: 指向托管 MTA-STS 策略文件的服务器 IP 地址.

     如果不在自己的服务器上托管, 可以使用 `CNAME` 记录指向第三方提供的静态网站托管服务.

   - MTA-STS 发现记录 (TXT 记录):
     - 主机名: `_mta-sts`
     - 值: `v=STSv1; id=2026010101`

     解释:
     - `v=STSv1`: 指定 MTA-STS 版本.
     - `id=2026010101`: 策略文件的版本号, 每次更新策略文件时需要更改此值以通知发送方.

   - TLS-RPT 报告记录 (TXT 记录):

     指定接收 TLS 报告的邮箱地址.
     - 主机名: `_smtp._tls`
     - 值: `v=TLSRPTv1; rua=mailto:me@domain.tld`

     解释:
     - `v=TLSRPTv1`: 指定 TLS-RPT 版本.
     - `rua=mailto:me@domain.tld`: 指定接收报告的邮箱地址.

3. 创建静态网站

   不展开了, 使用 OpenResty 或者直接用 Nginx 甚至借助 Github pages / Netlify / Cloudflare pages 等等都可以, 总之满足前面提到的要求就行.

4. 创建 MTA-STS 策略文件

   在 `mta-sts.domain.tld` 网站根目录下创建 `.well-known/mta-sts.txt` 文件, 内容如下:

   ```plain
   version: STSv1
   mode: testing
   mx: mail.domain.tld
   max_age: 86400
   ```

   解释:
   - `version: STSv1`: 指定 MTA-STS 版本.

   - `mode: testing`: 策略模式, 可选值有 `enforce`, `testing`, `none`. `enforce` 表示强制执行策略, `testing` 表示仅测试不强制执行, `none` 表示不启用 MTA-STS. 初始阶段建议使用 `testing`, 确认无误后再改为 `enforce`.

   - `mx: mail.domain.tld`: 指定允许发送邮件的 MX 服务器.

   - `max_age: 86400`: 策略的最大缓存时间, 单位为秒. 这里设置为 86400 秒(1 天). 建议在测试结束确认无误后将此值调大一些, 例如一周(604800 秒) 或更长.

5. 验证配置
   - 通过 [Hardenize](https://www.hardenize.com/) 或类似的在线工具验证 MTA-STS 配置是否正确.

   - 从支持 MTA-STS 的邮箱服务商 (例如 Gmail) 发送测试邮件, 查看 Postfix 日志来验证入站时 TLS 握手等流程是否符合预期. 至于 MTA-STS 是否真的生效, 可以稍后查看 TLS-RPT 报告邮箱收到的相关报告来确认.
