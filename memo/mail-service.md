> 公共邮箱服务显然已经足够用了，但是用自己的域名收发邮件真的很酷

> [!WARNING]
>
> 仅记录我的折腾过程, 并非指南, 并非推荐, 并非技术文档.

## 目录

- [目录](#目录)
- [概览](#概览)
  - [一些术语和缩写](#一些术语和缩写)
  - [要做什么](#要做什么)
  - [需要什么](#需要什么)
- [前置准备](#前置准备)
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
  - [Thunderbird](#thunderbird)
- [Extra Notes](#extra-notes)
  - [exim4: 我呢?](#exim4-我呢)
  - [Catch'em All!](#catchem-all)
  - [MTA-STS](#mta-sts)
  - [DMARC Alignment](#dmarc-alignment)
  - [转发到其他域](#转发到其他域)
  - [查看报告](#查看报告)
  - [邮件传输链路](#邮件传输链路)
  - [备份与恢复](#备份与恢复)
  - [测试工具](#测试工具)
- [这一切到底是为什么?](#这一切到底是为什么)

## 概览

### 一些术语和缩写

> 看不懂没关系, 遇到了再回来翻就好 :)

- M\*A

  | 简写 | 全称                  | 中文名称     | 说明                                                       |
  | ---- | --------------------- | ------------ | ---------------------------------------------------------- |
  | MTA  | Mail Transfer Agent   | 邮件传输代理 | 负责在邮件服务器之间传输邮件. 例如 Postfix.                |
  | MDA  | Mail Delivery Agent   | 邮件投递代理 | 负责将邮件存储到用户邮箱中. 例如 Dovecot.                  |
  | MSA  | Mail Submission Agent | 邮件提交代理 | 负责接收来自邮件客户端的邮件并将其传递给 MTA. 例如 Postfix |
  | MUA  | Mail User Agent       | 邮件用户代理 | 即邮件客户端. 例如 Thunderbird                             |

- 协议

  | 简写            | 全称                             | 中文名称             | 说明                                                                                                                                                            |
  | --------------- | -------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | SMTP            | Simple Mail Transfer Protocol    | 简单邮件传输协议     | 用于 MTA 之间的服务器通信. 通常运行在 25 端口.                                                                                                                  |
  | SMTP Submission | SMTP Submission                  | SMTP 提交协议        | 用于 MUA 向 MSA 提交邮件. 通常运行在 587 端口, 支持 `STARTTLS` 加密通信.                                                                                        |
  | SMTPS           | SMTP over SSL/TLS                | 基于 SSL/TLS 的 SMTP | 用于 MUA 提交邮件给 MSA, 使用独立端口(465)进行加密通信, 支持 `Implicit TLS`, 与 `STARTTLS` 不同的是其在连接建立时便立即进行 SSL/TLS 握手, 降低中间人攻击的风险. |
  | IMAP            | Internet Message Access Protocol | 互联网消息访问协议   | 用于 MUA 从 MDA 拉取邮件.                                                                                                                                       |
  | IMAPS           | IMAP over SSL/TLS                | 基于 SSL/TLS 的 IMAP | 使用独立端口(993)进行加密通信.                                                                                                                                  |
  | POP3            | Post Office Protocol version 3   | 邮局协议版本 3       | 另一种用于 MUA 接收邮件的协议, 不同的是一旦某个 MUA 取走邮件, 该邮件会在服务器上删除, 其他 MUA 将不再能收到这封邮件. 本文不会涉及此协议.                        |
  | LMTP            | Local Mail Transfer Protocol     | 本地邮件传输协议     | 简化的 SMTP, 用于 MTA 在服务器内部将邮件传递给 MDA.                                                                                                             |

- 安全策略

  | 简写            | 全称                                                            | 中文名称                       | 说明                                                                                                 |
  | --------------- | --------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------- |
  | rDNS            | Reverse DNS                                                     | 反向域名解析                   | 将 IP 地址映射回域名的特殊 DNS 记录. 多个 ip 可以同时映射到同一个域名, 但一个 ip 只能映射到一个域名. |
  | SPF             | Sender Policy Framework                                         | 发件人策略框架                 | 用于防止伪造发件人的技术.                                                                            |
  | DKIM            | DomainKeys Identified Mail                                      | 域名密钥识别邮件               | 用于验证邮件的完整性和真实性的技术.                                                                  |
  | DMARC           | Domain-based Message Authentication, Reporting, and Conformance | 基于域的消息认证, 报告和一致性 | 用于指定邮件在目标服务的处理策略.                                                                    |
  | DMARC Alignment | DMARC Alignment                                                 | DMARC 对齐                     | 用于确保发件人域名与 SPF 和 DKIM 认证域名一致的策略.                                                 |
  | MTA-STS         | Mail Transfer Agent Strict Transport Security                   | 邮件传输代理严格传输安全       | 用于防止中间人攻击的技术.                                                                            |
  | TLS-RPT         | Transport Layer Security Reporting                              | 传输层安全报告                 | 一方向另一方反馈 TLS 相关报告的方式.                                                                 |
  | SRS             | Sender Rewriting Scheme                                         | 发件人重写方案                 | 用于确保在邮件转发后保持 SPF 通过的技术, 通过改写 Envelope From 地址实现.                            |
  | ARC             | Authenticated Received Chain                                    | 认证接收链                     | 用于在邮件转发过程中保持认证信息的技术.                                                              |

- 邮件数据

  | 名称               | 中文名称       | 说明                                                                                                                                                                                                        |
  | ------------------ | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | Envelope From      | 信封发件人     | 邮件传输过程中使用的发件人地址. 通常在接受到的邮件头部中以 `Return-Path` 字段显示.                                                                                                                          |
  | Header From / From | 邮件头部发件人 | 邮件头部中显示的发件人地址, 也是在邮件客户端中能清晰看到的最醒目的发件人地址.                                                                                                                               |
  | Return-Path        | 退信路径       | 邮件头部中的一个字段, 用于指定邮件的回执地址, 通常由接受方 MTA 根据 Envelope sender 生成.                                                                                                                   |
  | DKIM-Signature     | DKIM 签名      | 邮件头部中的一个字段, 包含用于验证邮件完整性和真实性的签名信息.                                                                                                                                             |
  | Content-Type       | 内容类型       | 邮件头部中的一个字段, 用于指定邮件内容的格式和编码方式. 文本为主的邮件通常使用 `text/plain; charset="UTF-8"` 或 `text/html; charset="UTF-8"`, 二者在收件方的垃圾邮件过滤策略中可能会有不同的检测标准和权重. |

- 反垃圾与声誉

  | 简写 | 全称                                        | 中文名称             | 说明                                                                                            |
  | ---- | ------------------------------------------- | -------------------- | ----------------------------------------------------------------------------------------------- |
  | RBL  | Real-time Blackhole List                    | 实时黑洞列表         | 由第三方维护的黑名单数据库.                                                                     |
  | -    | Greylisting                                 | 灰名单               | 一种反垃圾邮件技术, 通过拒绝第一次发送的邮件并要求重试来过滤垃圾邮件.                           |
  | BIMI | Brand Indicators for Message Identification | 邮件识别的品牌指示符 | 允许在收件人的列表页显示自定义品牌 Logo 的标准. ~~因为我没有品牌也没有 Logo 所以~~本文不会涉及. |

### 要做什么

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
   >   和上面一点一样也是黑箱. 即使有良好的初始声誉, 如果后续不进行长期维护仍然可能会回到垃圾箱. 这不是短期努力可以解决的, 需要长期坚持.
   >
   > 如果确实觉得以上这些都不算问题, 那么可以忽略下文中所有有关 SMTP 中继相关的内容. 其实就本文包含的步骤而言区别并没有很大, 下文中相关的地方会以引用的形式进行标注.

3. 配置 SPF/DKIM/DMARC/MTA-STS 等等.

### 需要什么

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

> [!IMPORTANT]
>
> 在网络工程和状态防火墙的语境中, 当提到"封锁端口 X 的出站流量"时, 通常指的是"禁止从本地服务器发起到外部服务器的连接请求, 目标端口为 X". 相反, "封锁端口 X 的入站流量"则意味着"禁止外部服务器发起到本地服务器的连接请求, 目标端口为 X". 策略中用于识别流量的是目标端口, 而非源端口. 例如即使"25 端口的出站流量被封", 如果强行用 25 端口连接外部服务器的其他开放端口如 80, 这种连接请求仍然是允许的. 当然策略中也可以通过源端口进行过滤, 不过这么做通常意义不大.

## 前置准备

### 放开那个端口!

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

### 注册 SMTP 中继服务

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
>
> 在使用 SMTP 中继服务的情况下, 这个域名只作为收信服务器存在, 发信时使用的域名通常是 SMTP 服务商提供的子域名.

> [!NOTE]
>
> 优先级数值越小, 优先级越高. 如果同一个域名下有多个 MX 记录, 那么邮件服务器会优先选择优先级最高的记录进行连接.

- A 记录:
  - 主机名: `mail`
  - 值: `1.14.5.14`

  指向邮件服务器的公网 IP 地址.

其他记录将会在启动邮件服务器后配置.

### 在云服务器商处

将服务器 ip 的 rDNS 设置为 `mail.domain.tld`. 这对于使用 SMTP 中继服务的场景来说几乎毫无作用, 但是收信时一些发信方也可能会检查 rDNS, 因此最好设置正确, 有备无患.

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
        # 启用 SRS
        # - ENABLE_SRS=1
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

- `RSPAMD_GREYLISTING=0`

  启用后, 在第一次接受陌生人邮件时拒绝, 要求对方重试, 这样可以有效减少垃圾邮件, 但会显著增加延迟.

- `ENABLE_MTA_STS=1`:

  MTA-STS 可以防止中间人攻击, 但配置较为复杂, [下文](#更进一步) 将单独介绍.

- `ENABLE_FAIL2BAN=1`:

  Fail2Ban 用于防止暴力破解, 需要 `NET_ADMIN` 权限, 挂载 `./fail2ban` 目录用于保存状态.

- `DEFAULT_RELAY_HOST=[smtp.resend.com]:587`

  中括号用于跳过 MX 查找直接解析 A 记录, 这对于连接明确的 SMTP 中继服务效率更高且更稳定.

- `POSTFIX_INET_PROTOCOLS=ipv4`:

  如果服务器的 IPv6 配置不完善, 可以强制 Postfix 仅使用 IPv4. 反之也可以只支持 IPv6.

- `ENABLE_SRS=1`:

  启用 SRS 用于转发场景, 详见 [后续章节](#转发到其他域).

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

SPF 记录用于指定哪些服务器被允许代表该域名发送邮件. 它会检查信件 "Envelope sender" (也就是 `Return-Path` 头部) 中的域名是否与对应域名的 SPF 记录匹配, 从而防止伪造发件人.

> [!IMPORTANT]
>
> 对于使用 SMTP 中继服务的场景, SPF 记录仍然是**必须的**. 即使正常发信时收件方检查的是子域名如 `send.domain.tld` 的 SPF 记录, 但设置根域名 `domain.tld` 的 SPF 记录仍然是良好的实践, 可以防止伪造发件人.

在 DNS 服务商处添加以下记录:

- SPF 记录 (TXT 记录):
  - 主机名: `@`
  - 值: `v=spf1 -all` (假设使用 Resend 作为 SMTP 服务商)

  解释:
  - `v=spf1`: 指定 SPF 版本.
  - `include:resend.com`: 仅允许 Resend 的服务器以此域名的名义发送邮件. 因为 Resend 并不会通过根域名发送邮件, 所以这条记录严格来说可以省略.
  - `-all`: 硬失败, 未授权的服务器发送邮件时拒绝. 因为发行渠道只有 Resend, 所以这样设置是合理的. 如果希望软失败, 即接受但标记为可疑, 可以使用 `~all`.

  > 如果选择直接发信不使用 SMTP 中继服务, 则**需要**将 `include:resend.com` 替换为自己的邮件服务器的 IP 地址或域名, 例如:
  >
  > `v=spf1 a:mail.domain.tld -all`
  >
  > 详细语法参见 [SPF 规范](https://datatracker.ietf.org/doc/html/rfc7208).

### 配置 DKIM

DKIM (DomainKeys Identified Mail) 用于验证邮件的完整性和真实性.

> [!NOTE]
>
> 对于使用 SMTP 中继服务的场景, DKIM 通常由服务商负责配置和签署, 本地 DKIM 在中继场景下不一定会被最终保留或使用, 其价值更多在于内部一致性或未来切换为直连发信的准备.

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

DMARC (Domain-based Message Authentication, Reporting, and Conformance) 用于指定邮件的处理策略. 更多有关 DMARC Alignment 的内容参见 [后续章节](#dmarc-alignment).

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

我并非 TUI 重度爱好者, 日常用 Thunderbird 当客户端, 因此这里只涉及这一种客户端的配置方法, 当然其他的也大同小异.

### Thunderbird

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

## Extra Notes

本节包含一些额外的说明和可选配置.

### exim4: 我呢?

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

### Catch'em All!

如果希望接收发往不存在邮箱地址的邮件, 可以启用 Catch-all 功能. 方法也很简单, 使用 alias 即可:

```bash
docker exec -it mailserver setup alias add @domain.tld me@domain.tld
```

将其中 `me@domain.tld` 替换为希望接收这些邮件的真实邮箱地址即可.

> [!WARNING]
>
> 完全按照上述步骤配置通配符邮箱别名可能会导致后续添加其他邮箱时邮件仍然发到上面指定的 catch-all 邮箱而不是新创建的邮箱. 更好的实践是用到什么邮箱名再创建对应的别名.

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

### DMARC Alignment

这是一种收信方采取的安全策略, 用于确保发件人的身份与邮件头部的 `From` 地址一致.

- 两种模式
  1. Relaxed (默认)

     只要域名相同或子域名关系即可通过.

  2. Strict

     必须完全相同才可通过.

  可以在 DMARC 记录中通过 `adkim` 和 `aspf` 标签指定 DKIM 和 SPF 的 Alignment 模式, 例如:

  ```plain
  v=DMARC1; p=none; adkim=r; aspf=r;
  ```

  指定了 DKIM 和 SPF 都使用 Relaxed 模式.

  使用 SMTP 中继服务时, **必须**使用 Relaxed 模式, 原因后续会说明.

- 两个步骤
  1. SPF Alignment

     匹配 `Return-Path` 地址的域名和 `From` 头部的域名是否相同或子域名关系.

  2. DKIM Alignment

     匹配 DKIM 签名中 `d=` 标签的域名和 `From` 头部的域名是否相同或子域名关系.

  二者只要有一个通过即可满足 DMARC Alignment 要求.

- SMTP 中继发信时如何工作
  - 对于 SPF Alignment

    以 Resend 为例, 其发出的邮件中 `Return-Path` 地址虽然会被改写, 但会被改写为 `<很长一串>@send.domain.tld`, 其域名属于 `domain.tld` 的子域名, 因此在 Relaxed 模式下可以通过 SPF Alignment 检查.

  - 对于 DKIM Alignment

    以 Resend 为例, 在其让添加进 DNS 的记录中有一条便是选择器为 `resend` 的 DKIM 记录, resend 会使用该密钥对发出的邮件进行签名, 签名中的 `d=` 标签会被设置为 `domain.tld`, 因此可以通过 DKIM Alignment 检查.

### 转发到其他域

> [!CAUTION]
>
> 大多数 SMTP 中继服务采用严格的发件人核验制度, 即发件人的域名必须是经过验证和配置的域名. 因此如果使用类似的服务发信, 那么自动转发到其他域名很有可能是不可能的事情.
>
> 因此本节内容更适合自建邮件服务器并直接发信的场景, 对于没有强商业目的的个人邮箱来说意义不大.

- SRS (Sender Rewriting Scheme)

  用于在转发邮件时重写发件人地址, 改写 envelope sender 为自己域名下的地址, 从而避免 SPF 检查失败的问题.

  对于 docker-mailserver, 只需要在 `compose.yaml` 中添加 `ENABLE_SRS=1` 环境变量即可. 其他相关配置参见 [官方文档](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/#srs-sender-rewriting-scheme).

  > 在此处我遇到了一个极其诡异的情况, 简单提一嘴:
  >
  > - What
  >
  >   启用 SRS 后, postfix 迟迟无法启动, postsrsd 长时间以 CPU 满负荷持续运行.
  >
  > - Why
  >
  >   如果使用 strace 跟踪 postsrsd 进程, 会发现它在不停地尝试关闭一些文件描述符, 类似这样:
  >
  >   ```plain
  >   close(192479922)                        = -1 EBADF (Bad file descriptor)
  >   ```
  >
  >   原因是 postsrsd 在启动时，为了确保环境干净，会执行"关闭从 3 到 MAX 的所有文件描述符"的操作, 而 MAX 的值通过 `sysconf(_SC_OPEN_MAX)` 或 `getrlimit(RLIMIT_NOFILE)` 获取. 在 Docker 容器中, 这个值可能会非常大, 导致 postsrsd 花费大量时间尝试关闭这些不存在的文件描述符.
  >
  > - How
  >
  >   通过在 `compose.yaml` 中添加 `ulimits` 配置, 将 `nofile` 的软限制和硬限制都设置为一个合理的值, 例如 65535:
  >
  >   ```yaml
  >   services:
  >     mailserver:
  >       ...
  >       ulimits:
  >         nofile:
  >           soft: 65535
  >           hard: 65535
  >   ```
  >
  >   之后重建容器即可.

- ARC (Authenticated Received Chain)

  用于在邮件转发过程中保留并传递上游服务器对 SPF / DKIM / DMARC 的认证结果, 从而帮助下游服务器在 DMARC 检查失败时判断邮件是否原本是可信的.
  - 为什么需要 ARC

    SRS 会改写 Return-Path, 在 From 域不属于转发域的情况下这会破坏 SPF 对齐. 如果同时一些受 DKIM 签名中 `h=` 标签保护的 Header (在不知情的情况下)调整顺序/增/删/改, 或邮件内容改变, 则会导致 DKIM 签名失效, 从而导致 DMARC 检查失败. 此时如果启用了 ARC, 则可以通过 ARC 链来证明邮件的真实性.

    但同时, ARC 工作的前提条件是转发服务器受目标服务器信任. 这又是一个黑盒, 涉及漫长和玄学的信誉培养过程.

  - 如何启用

    对于启用 Rspamd 的 docker-mailserver, 需要在 `config/rspamd/override.d/arc.conf` 中添加如下内容:

    ```plain
    sign_local = true;
    sign_authenticated = true;

    allow_env_sender_mismatch = true;
    allow_hdr_from_mismatch = true;

    domain {
      domain.tld {
        path = "/path/to/dkim/private/key.private.txt";
        selector = "mail";
      }
    }
    ```

    替换 `domain.tld` 和 `path` 以及 `selector` 为真实值. Rspamd 中, ARC 通常使用和 DKIM 相同的密钥对邮件进行签名.

    `allow_env_sender_mismatch` 和 `allow_hdr_from_mismatch` 用于在转发导致的发件人域名与当前服务器域名不一致时仍然进行签名.

    详细配置参见 [Rspamd 文档](https://docs.rspamd.com/modules/arc/).

### 查看报告

上述配置中的 DMARC 和 TLS-RPT 都会发送报告到指定邮箱. 可以定期查看这些报告以了解邮件传输的安全状况和潜在问题, 推荐部署 [Parsedmarc](https://github.com/domainaware/parsedmarc) 或类似工具进行自动化处理.

### 邮件传输链路

> 一些关于服务器位置描述的解释:
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

     - 说明: 这一步由中继商完成. 部分客户端可能会显示代发信息, 具体取决于中继实现与客户端策略.

### 备份与恢复

> [!CAUTION]
>
> 邮件数据一旦丢失几乎不可恢复, 务必定期离机备份.

本文采用 docker 部署邮件服务器, 容器本身是无状态的, 因此只需要备份挂载的卷即可, 不做过多赘述.

唯一需要特殊说明的是务必保留文件权限和属主信息, 否则恢复后邮件服务器可能无法正常工作.

### 测试工具

一些上文中提到或者没提到的在线测试工具:

- [Mail-Tester](https://www.mail-tester.com): 用于测试邮件是否容易被判定为垃圾邮件.

- [MailGenius](https://www.mailgenius.com/): 比 Mail-Tester 更全面和严格的测试工具.

- [Hardenize](https://www.hardenize.com/): 用于测试域名的安全配置, 其中也包括 DMARC, MTA-STS 等邮件服务器相关的配置.

- [MXToolbox](https://mxtoolbox.com/): 提供多种邮件相关的测试工具, 包括黑名单检查, SMTP 测试等等.

- [GMass](https://www.gmass.co/inbox): 提供了 15 个 Gmail 邮箱用于测试邮件送达率.

- [Google Postmaster Tools](https://postmaster.google.com/v2/sender_compliance): 如果主要收件方是 Gmail 且选择自己发信而不使用 SMTP 中继服务, 可以注册并使用该工具来监控邮件送达情况和声誉. 需要注意的是即使"Compliance status"中全部项为绿色, 也不代表邮件一定不会被扔进垃圾箱, 仅供参考.

---

> What, Why, How. 以上是 What 和 How, 接下来是...

## 这一切到底是为什么?

排除利益驱动, 我能想到的最合适的借口就是"隐私". 可是如果登陆 Resend 的后台看一眼, 就会发现我写的邮件被一封封明晃晃地不加掩饰地放在那里, 所有的内容都以明文的方式被看得一清二楚. 此时和使用公共邮箱服务唯一的区别似乎也就只剩"有一个很酷的后缀"这一点了. 即便真的解决了 25 端口问题 (是的, 写完上述内容的几天后我确实做到了) 从而得以摆脱 SMTP 中继服务, 在惊讶于明明 Mail-Tester 给出了 10/10 的满分评价但还是被 Gmail 扔进垃圾箱的残酷现实之余, 我也意识到自建邮局这条路仅靠热情是绝对走不通的. 一是预热 IP 需要花费的时间成本乃至金钱成本远超我的想象, 二是无论如何邮件内容也会被收件方的平台以算法评估一遍的事实彻底击碎了对于"隐私"乌托邦最后的妄想. 即使有这么多复杂的安全措施, 补齐了传输过程中的每一个可能的安全漏洞, 但真正和我点对点沟通的从来都只是靠着一条条既定规则维系的平台, 而不是我在写下收件地址时心中所想的一个个鲜活的人.

那么做这一切的目的到底是什么呢? 或许也只剩"酷"了吧, 除此之外我唯一能想到的好处就是在仅需要邮箱就能注册账号的平台注册无穷无尽的小号.

Anyway, 确实是我拥有域名和服务器以来部署过的最复杂, 折腾时间最久, 也可能是最无用的服务. 仅论过程还是很有意思的, 至少能让我理解现代电子邮箱系统到底是如何运作的. ~~闲的没事的话~~还是很值得试一试的 :)

EOF
