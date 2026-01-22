> 公共邮箱服务显然已经足够用了，但是用自己的域名收发邮件真的很酷

> [!WARNING]
>
> 仅记录我的折腾过程, 并非指南, 并非推荐, 并非技术文档.

## 目录

- [目录](#目录)
- [要做什么](#要做什么)
- [需要什么](#需要什么)
- [放开那个端口!](#放开那个端口)
- [注册 SMTP 中继服务](#注册-smtp-中继服务)
- [配置 DNS 和 rDNS](#配置-dns-和-rdns)
  - [在 DNS 服务商处](#在-dns-服务商处)
  - [在云服务器商处](#在云服务器商处)
  - [在服务器上](#在服务器上)
- [配置邮件服务器](#配置邮件服务器)
  - [搞定 SSL](#搞定-ssl)
  - [创建 compose.yaml](#创建-composeyaml)
  - [创建邮箱账号](#创建邮箱账号)
  - [配置 SPF](#配置-spf)
  - [配置 DKIM](#配置-dkim)
  - [配置 DMARC](#配置-dmarc)
  - [启动!](#启动)
  - [Rspamd Web UI](#rspamd-web-ui)
- [配置邮件客户端](#配置邮件客户端)
- [exim4: 我呢?](#exim4-我呢)
- [Catch'em All!](#catchem-all)
- [Extra Notes](#extra-notes)
  - [MTA-STS](#mta-sts)
  - [查看报告](#查看报告)
  - [邮件传输链路](#邮件传输链路)
- [为什么要做自建邮局?](#为什么要做自建邮局)

## 要做什么

一个概览.

1. 在自己的服务器上配置邮件服务器, 直接接收邮件;

2. 配置邮件服务器通过 SMTP 中继服务发送邮件;

   > 或者也可以让邮件服务器直接发信, 但要额外做好以下准备:
   >
   > - 出入站均畅通无阻的 25 端口
   >
   >   大多数云服务商默认封锁 25 端口的出站流量, 需要联系或付费解封.
   >
   > - 良好的 IP 声誉
   >
   >   可以通过 [mxtoolbox](https://mxtoolbox.com) 或类似网站检查 IP 是否在任意黑名单中. 如果在的话也不是没救, 可以查查对应黑名单的影响范围, 有些其实根本无人在意.
   >
   > - 绝对完善的安全策略
   >
   >   很多对于使用 SMTP 中继服务时可选的配置在自己发信的场景下是基本要求, 例如 rDNS, DKIM 等. 可以通过 [mail-tester.com](https://www.mail-tester.com) 或 [Hardenize](https://www.hardenize.com/) 等网站检查配置是否完善.
   >
   > - 耗费数周乃至数月培养 IP 声誉的时间与物质成本
   >
   >   多少沾点玄学. 举个例子, 在这个过程中需要持续向多个公共邮箱平台的多个邮箱发送**有效**邮件, 什么样的邮件是"有效"的? 不知道. 发送多少封才能被认为"无害"? 也不知道. 发送到多少封会被认为"滥用"? 不知道. 不同平台具体采取什么样的评估标准? 还是不知道. 对于纯良的个人邮局来说这无疑是最大的挑战
   >
   > - IP 长期保活的持久战准备
   >
   >   及时在上面的一点中成功培养了良好的初始声誉, 如果后续不进行长期维护仍然可能会回到垃圾箱. 这不是短期努力可以解决的, 而需要长期坚持.
   >
   > 如果确实觉得没问题, 那么可以忽略下文中所有有关 SMTP 中继相关的内容. 其实就本文包含的步骤而言区别并没有很大, 下文中相关的地方会以引用的形式进行标注.

3. 配置 SPF/DKIM/DMARC/MTA-STS 等等.

## 需要什么

1. 一个中意的域名.

   下文中将使用 `domain.tld` 作为示例域名, 使用 `mail.domain.tld` 作为邮件服务器域名, 使用 `me@domain.tld` 作为示例邮箱.

2. DNS 服务, (至少)需要支持以下记录类型:
   - A
   - TXT
   - MX

3. SMTP 中继服务.

   也就是帮忙发邮件的服务商, 详见后续章节.

4. 一个拥有公网 IP 和充足空闲资源的服务器, 并且(至少)需要开通以下 TCP 端口:

   | 端口 | 用途            | 出站 | 入站 | 说明                                                |
   | ---- | --------------- | ---- | ---- | --------------------------------------------------- |
   | 25   | SMTP            | ⚠️   | ✅   | 核心传输端口. 如果使用 SMTP 中继服务, 则出站可选    |
   | 993  | IMAPS           | ❌   | ✅   | 用于邮件客户端收信                                  |
   | 587  | SMTP Submission | ⚠️   | ✅   | 支持 STARTTLS. 如果使用 SMTP 中继服务, 则也需要出站 |
   | 465  | SMTPS           | ❌   | ✅   | 支持 Implicit SSL/TLS                               |

   很多云服务商会默认屏蔽 25 端口的出站方向流量, 但这对于使用 SMTP 中继服务的场景来说并不重要, 因为发信时直接连接收件方服务器的并非自己的服务器.

   同时, 最好支持 rDNS, 也就是把 IP 反解析到域名. IPv4 和 IPv6 用到哪个就配置哪个, 都用得到就都配置.

   > 如果选择直接发信不使用 SMTP 中继服务, 则必须配置 rDNS

   下文中将使用 `1.14.5.14` 作为服务器的公网 IP 地址.

## 放开那个端口!

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
> 再次说明, 如果使用 SMTP 中继服务, 25 端口的出站并不重要. 只需要保证入站开放即可. 反之则必须保证 25 端口出入站通畅.

2. 解决占用:

   我的服务器是 Debian 13 系统, 默认使用 `exim4` 作为邮件传输代理(MTA). 不出意外的话 25 端口已经在它手里攥了很久了. 因此除了在防火墙里放行 25 端口外, 还需要禁用 `exim4`.

   ```bash
   sudo systemctl disable --now exim4
   ```

   如果确实需要系统内部通信, 例如 `cron` 发送邮件通知, 可以安装 `ssmtp` 或 `msmtp` 之类的轻量级 MTA, 参见 [后续章节](#exim4-我呢).

## 注册 SMTP 中继服务

> 如果选择直接发信不使用 SMTP 中继服务, 则**跳过**本节内容.

此类服务可以大致理解为"帮忙发邮件的中介", 他们通常有很多 IP 地址, 这些地址的声誉都不错, 配置也很完善, 因此用他们发信的话, 邮件更容易送达收件箱而不是自动被扔进垃圾箱. 并且这也可以避免 25 端口出站被封的问题.

我此次用的是 [Resend](https://resend.com), 其他类似服务还有 Amazon SES, Mailgun 等等.

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

  这将会是邮件的接收和发送服务器的域名.

> [!TIP]
>
> 如果乐意的话可以把收信域名, 发信域名, 乃至退信域名等等都拆分开来配置, 但这超过了本文的讨论范围且配置大同小异, 因此不做另外说明 ~~主要是懒~~ :)

- A 记录:
  - 主机名: `mail`
  - 值: `1.14.5.14`

  指向邮件服务器的公网 IP 地址.

其他记录将会在启动邮件服务器后配置.

### 在云服务器商处

将服务器 ip 的 rDNS 设置为 `mail.domain.tld`. 虽然未来主要使用 Resend 发信, 但是收信时一些发信方也可能会检查 rDNS, 因此最好设置正确, 有备无患.

> 如果选择直接发信不使用 SMTP 中继服务, 则**必须**配置 rDNS

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

### 创建 compose.yaml

```yaml
services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:15.1.0
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
- `resend`: 替换为在 SMTP 服务商处创建的真实用户名.
- `res_some_random_api_key`: 替换为在 SMTP 服务商处创建的 SMTP 凭据或 API Key.

一些 environment 的解释:

- 如果机器性能孱弱或很在意占用的资源, 可以关掉 [Rspamd](https://docker-mailserver.github.io/docker-mailserver/latest/config/security/rspamd/) 使用老东西:
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

  Fail2Ban 用于防止暴力破解, 需要 `NET_ADMIN` 权限, 挂载 `./fail2ban` 目录用于保存状态.

- `DEFAULT_RELAY_HOST=[smtp.resend.com]:587`

  中括号用于跳过 MX 查找直接解析 A 记录, 这对于连接明确的 SMTP 中继服务效率更高且更稳定.

- `POSTFIX_INET_PROTOCOLS=ipv4`:

  如果服务器的 IPv6 配置不完善, 可以强制 Postfix 仅使用 IPv4. 反之也可以只支持 IPv6.

> 如果选择直接发信不使用 SMTP 中继服务, **必须**删除以下环境变量:
>
> - `DEFAULT_RELAY_HOST=[smtp.resend.com]:587`
> - `RELAY_USER=resend`
> - `RELAY_PASSWORD=res_some_random_api_key`

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
  - 值: `v=spf1 include:resend.com -all` (假设使用 Resend 作为 SMTP 服务商)

  解释:
  - `v=spf1`: 指定 SPF 版本.
  - `include:resend.com`: 仅允许 Resend 的服务器以此域名的名义发送邮件.
  - `-all`: 硬失败, 未授权的服务器发送邮件时拒绝. 因为发行渠道只有 Resend, 所以这样设置是合理的. 如果希望软失败, 即接受但标记为可疑, 可以使用 `~all`.

  > 如果选择直接发信不使用 SMTP 中继服务, 则**需要**将 `include:resend.com` 替换为自己的邮件服务器的 IP 地址或域名, 例如:
  >
  > `v=spf1 a:mail.domain.tld -all`
  >
  > 详细语法参见 [SPF 规范](https://datatracker.ietf.org/doc/html/rfc7208).

### 配置 DKIM

DKIM (DomainKeys Identified Mail) 用于验证邮件的完整性和真实性. 对于使用 SMTP 中继服务的场景, DKIM 通常由服务商负责配置和签署, 但仍推荐在自建服务器侧进行签名以保证邮件从源头开始的完整性.

> 如果选择直接发信而非使用 SMTP 中继服务, 则本节内容是**必须的**.

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
     v=DKIM1; k=rsa; p=MIISncASjsASK...
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

  在运行一段时间并查看报告无误后, 可以将 `p` 和 `sp` 设置为 `quarantine` 或 `reject`, 以增强防护. `quarantine` 表示将可疑邮件标记为垃圾邮件, `reject` 则表示直接拒绝这些邮件.

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

我并非 TUI 重度爱好者, 日常用 Thunderbird 当客户端. 这里只涉及这一种客户端的配置方法, 当然其他的也大同小异.

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

   如果一切正常, 应该会在前面配置的邮箱客户端中收到这封测试邮件.

> [!NOTE]
>
> 此时可将 msmtp 看作 mailserver 的客户端, 因此 `/etc/msmtprc` 中配置的邮件服务器并不一定要部署在本机, 甚至可以是公共邮箱服务.

## Catch'em All!

如果希望接收发往不存在邮箱地址的邮件, 可以启用 Catch-all 功能. 方法也很简单, 使用 alias 即可:

```bash
docker exec -it mailserver setup alias add @domain.tld me@domain.tld
```

将其中 `me@domain.tld` 替换为希望接收这些邮件的真实邮箱地址即可.

> [!WARNING]
>
> 完全按照上述步骤配置通配符邮箱别名可能会导致后续添加其他邮箱时邮件仍然发到上面指定的 catch-all 邮箱而不是新创建的邮箱. 更好的实践是用到什么邮箱名再创建对应的别名.

## Extra Notes

### MTA-STS

**MTA-STS** (Mail Transfer Agent Strict Transport Security) 通过强制要求发送方使用加密连接发送邮件防止中间人攻击, 对个人邮箱来讲~~看起来其实没啥大用但总归~~是个加分项, 并且确实会让邮箱服务变得更酷.

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

### 查看报告

上述配置中的 DMARC 和 TLS-RPT 都会发送报告到指定邮箱. 可以定期查看这些报告以了解邮件传输的安全状况和潜在问题, 推荐部署 [Parsedmarc](https://github.com/domainaware/parsedmarc) 或类似工具进行自动化处理.

### 邮件传输链路

> 一些术语简写:
>
> - `MTA`: Mail Transfer Agent, 邮件传输代理, 负责在邮件服务器之间传输邮件. 例如 Postfix.
> - `MDA`: Mail Delivery Agent, 邮件投递代理, 负责将邮件存储到用户邮箱中. 例如 Dovecot.
> - `MSA`: Mail Submission Agent, 邮件提交代理, 负责接收来自邮件客户端的邮件并将其传递给 MTA. 例如 Postfix.
> - `MUA`: Mail User Agent, 邮件用户代理, 即邮件客户端. 例如 Thunderbird.
>
> 以及位置:
>
> - `Local`: 自建邮件服务器.
> - `Source`: 外部邮件服务器, 发送方.
> - `Destination`: 外部邮件服务器, 接收方.
> - `Relay`: SMTP 中继服务.

以本文配置为例:

- 收信
  1. 外部投递 (Source MTA to Local MTA):
     - 连接方: 外部邮件服务器.

     - 被连接方: 自建邮件服务器公网 IP.

     - 目标端口: 25.

     - 说明: 标准的 SMTP 传输. 这也是为什么需要开放 25 端口入站.

  2. 本地分发 (Local MTA to Local MDA):
     - 连接方: 自建邮件服务器.

     - 被连接方: 自建邮件服务器本地存储.

     - 端口: 本地通信, 无需端口.

     - 说明: Postfix (MTA) 接收邮件后，转交给 Dovecot (MDA) 将邮件存入磁盘.

  3. 客户端拉取 (MUA to Local MDA):
     - 连接方: 邮件客户端 (例如 Thunderbird).

     - 被连接方: 自建邮件服务器公网 IP.

     - 目标端口: 993 (IMAPS).

     - 说明: 使用 IMAPS 拉取邮件.

- 发信
  1. 客户端提交 (MUA to Local MSA):
     - 连接方: 邮件客户端 (例如 Thunderbird).

     - 被连接方: 自建邮件服务器公网 IP.

     - 目标端口: 587 (STARTTLS) 或 465 (SSL/TLS).

     - 说明: 把邮件上传到服务器队列中.

  2. 中继转发 (Local MTA to Relay MTA):
     - 连接方: 自建邮件服务器.

     - 被连接方: SMTP 中继服务.

     - 目标端口: 587 (STARTTLS).

     - 说明: 自建邮件服务器根据 `DEFAULT_RELAY_HOST` 配置, 验证账号密码后将邮件转交给中继商.

  3. 最终投递 (Relay MTA to Destination MTA):
     - 连接方: SMTP 中继服务.

     - 被连接方: 外部邮件服务器.

     - 目标端口: 25.

     - 说明: 这一步由中继商完成. 收件人会看到类似"由 xxx@send.domain.tld 代发" 的信息.

---

> What, Why, How. 以上是 What 和 How, 接下来是...

## 为什么要做自建邮局?

排除利益驱动, 我能想到的最合适的借口就是"隐私". 可是如果登陆 Resend 的后台看一眼, 就会发现我写的邮件被一封封明晃晃地不加掩饰地放在那里, 所有的内容都以明文的方式被看得一清二楚. 此时和使用公共邮箱服务唯一的区别似乎也就只剩"有一个很酷的后缀"这一点了. 即便真的解决了 25 端口问题 (是的, 写完上述内容的几天后我确实做到了) 从而得以摆脱 SMTP 中继服务, 在惊讶于明明 Mail-Tester 给出了 10/10 的满分评价但还是被 Gmail 扔进垃圾箱的残酷现实之余, 我也意识到自建邮局这条路仅靠热情是绝对走不通的. 一是预热 IP 需要花费的时间成本乃至金钱成本远超我的想象, 二是无论如何邮件内容也会被收件方的平台以算法评估一遍的事实彻底击碎了对于"隐私"乌托邦最后的妄想. 即使有这么多复杂的安全措施, 补齐了传输过程中的每一个可能的安全漏洞, 但真正和我点对点沟通的从来都只是靠着一条条既定规则维系的平台, 而不是我在写下收件地址时心中所想的一个个鲜活的人.

那么做这一切的目的到底是什么呢? 或许也只剩"酷"了吧, 除此之外我唯一能想到的好处就是在仅需要邮箱就能注册账号的平台注册无穷无尽的小号.

Anyway, 确实是我拥有域名和服务器以来部署过的最复杂, 折腾时间最久, 也可能是最无用的服务. 仅论过程还是很有意思的, 至少能让我理解现代电子邮箱系统到底是如何运作的. ~~闲的没事的话~~还是很值得试一试的 :)

EOF
