# wnmmp

- window+nginx+mysql+mongodb+php绿色集成开发环境（mongodb、mongosh、mysql、nginx、php）。
- 双击"install.bat"时会自动运行bin目录里的“VC_redist.x64.exe”进行安装（php要运行需要Microsoft Visual C++运行库），如果已安装，可以直接关闭“VC_redist.x64.exe”的安装程序，"install.bat"会自动下载相关组件并自动完成初始化。
- 安装完成后，会将bin/composer/目录添加到系统环境变量。

### 当前版本说明：
wnmmp 是一个基于 Windows 的 Nginx、MySQL、MongoDB 和 PHP 的集成环境包。它提供了一整套用于 Web 开发和部署的工具和服务，适用于快速搭建本地或生产环境。

### 运行说明
wnmmp 提供了一系列脚本和工具来管理服务和组件。以下是主要功能和操作指南：

#### 主要组件
- **Nginx**：高性能的 HTTP 服务器和反向代理服务器。
- **MySQL**：广泛使用的关系型数据库管理系统。
- **MongoDB**：NoSQL 数据库，适用于处理大量非结构化数据。
- **PHP**：流行的服务器端脚本语言，适用于 Web 开发。

#### 常用脚本
- `install.bat`（要正常使用，必须先执行一次install.bat）：自动运行“VC_redist.x64.exe”的安装程序和下载对应组件,并自动完成初始化（mongodb和mysql数据库账号默认为root，密码默认为：xqkeji.cn。）。
- `start.bat`：启动所有服务（Nginx、MySQL、MongoDB、PHP）。
- `stop.bat`：停止所有服务。
- `install_service.bat`：右键install_service.bat"以管理员身份运行”,可以将服务安装为 Windows 服务。
- `uninstall_service.bat`：右键uninstall_service.bat"以管理员身份运行”,可以卸载 Windows 服务。
- `bin\make-ssl.bat`：签发本地受信证书并把站点切换到 443 https（80 只做 301 跳转）；`install.bat` 末尾会自动执行一次，详见下面「启用 HTTPS」。


#### 配置文件
- **Nginx**：`etc/nginx/nginx.conf`
- **MySQL**：`etc/mysql/my.ini`
- **MongoDB**：`etc/mongodb/mongo.conf`
- **PHP**：`etc/php/php.ini`
- **PHP-CGI 多进程**：`etc/php/php-cgi.conf`（`processes` 进程数，默认 4；`port` 第一个进程的端口，默认 9000，第 i 个进程监听 port+i-1）。nginx 的 `etc/nginx/php_processes.conf` 由脚本按这份配置自动生成，不要手工编辑。
- **HTTPS**：`etc/nginx/ssl.conf`（证书路径与 TLS 参数）与 `etc/nginx/http_redirect.conf`（80 上做 301 跳转的 server 块），两行 `include` 都由 `bin\make-ssl.bat` 加到 `nginx.conf` 的 http 层；证书文件在 `etc/nginx/ssl/`（不入库）。
- **目录禁止执行 PHP**：`etc/nginx/php_no_exec.conf`（`asset/`、`upload/` 目录里的 php 文件一律不解析执行，返回 403）。`etc/nginx/conf.d/` 下每个虚拟主机都要在 `location /` 里面、`location ~ \.php$` 之前加一行 `include php_no_exec.conf;`——顺序不能换，放在 server 层也拦不住 php 处理块。

#### 日志和数据
- **日志目录**：
  - `logs/mysql/`
  - `logs/mongodb/`
  - `logs/nginx/`
  - `logs/php/`
- **数据目录**：
  - `data/mysql`（MySQL数据库数据目录）
  - `data/mongodb`（MongoDB数据库数据目录）
  - `www/default/`（默认网站根目录）

#### 第三方工具
- `RunHiddenConsole.exe`：用于在后台运行控制台程序。
- `nssm.exe`：用于管理 Windows 服务。
- `wget.exe` 和 `unzip.exe`：用于下载和解压文件。
- `bin\mkcert.exe`：生成本地受信 HTTPS 证书（BSD-3-Clause，许可证见 `bin\mkcert\LICENSE`）。

#### 使用方法
1. **下载和安装**：
   - 要使用前必须先执行一次 `install.bat` 运行bin目录里的“VC_redist.x64.exe”的安装程序，下载所有组件,并自动完成初始化。最后一步会自动启用 https（签发本地证书、站点切到 443、80 做 301 跳转），详见下面「启用 HTTPS」。
2. **启动服务**：
   - 运行 `start.bat` 启动所有服务。
3. **停止服务**：
   - 运行 `stop.bat` 停止所有服务。
4. **安装Window服务**：
   - 右键`install_service.bat`"以管理员身份运行”可以将服务注册为 Windows 服务，默认开机启动。
5. **卸载服务**：
   - 右键`uninstall_service.bat`"以管理员身份运行”可以卸载已注册的 Windows 服务。


#### 启用 HTTPS
- `install.bat` 的最后一步会自动运行一次 `bin\make-ssl.bat`：用自带的 `bin\mkcert.exe`（BSD-3-Clause，已随包放在 bin 目录，不需要联网下载）创建本地根证书并装入**当前用户**信任库（不需要管理员权限），签发 `etc\nginx\ssl\wnmmp.pem` / `etc\nginx\ssl\wnmmp-key.pem`，把 `etc\nginx\conf.d\*.conf` 里的 `listen 80` 改成 `listen 443 ssl`，并在 `etc\nginx\nginx.conf` 的 http 层加上 `include ssl.conf;` 与 `include http_redirect.conf;`。改完会跑 `nginx -t` 自检，不通过就自动回退到 80。手工执行同一个命令即可，站点已在 443 且证书在位时不改配置、也不重签证书。
- 证书签发给 `localhost`、`127.0.0.1`、`::1`、`*.xqkeji.com`（通配符只有一级，正好覆盖 `crm.xqkeji.com` 这类本地域名）。`*.xqkeji.com` 的子域名需要自己写进 hosts，例如 `127.0.0.1 crm.xqkeji.com`。
- 443 提供 https，80 只负责跳转：`etc\nginx\http_redirect.conf` 把 http 请求 301 到 `https://$host$request_uri`，即同一个域名同一个路径，不再有明文访问。`start.bat`、`stop.bat`、`install.bat` 会自己识别当前是 443 还是 80，不用改端口配置。
- 开启前先探测 443 和 80：占用者不是 nginx 就拒绝改配置，并指明是哪个程序（IIS 的 W3SVC、IIS Express、VMware NAT 或其他 web 服务），停掉后重新运行即可；占用者是 nginx 则放行——`install.bat` 开头本来就会先停掉所有 nginx，正常安装不会因此受阻。同时跑着另一份 wnmmp 时两份都会抢 80，先在那一份里 `bin\make-ssl.bat disable` 或者直接停掉它。
- `bin\make-ssl.bat renew` 只重新签发证书，不动配置；`disable` 让站点回到 80，两行 include（含 80 跳转）一并撤销，证书保留；`uninstall` 回到 80 并从信任库移除根证书、删除 `etc\nginx\ssl` 里的证书文件。
- Firefox 用自己独立的证书库，装完根证书要重启浏览器才生效；命令行 curl、PHP 的 `openssl_verify` 读不到系统信任库，需要把 mkcert 输出提示的根证书目录（默认 `%LOCALAPPDATA%\mkcert`）里的 `rootCA.pem` 配给 `curl.cainfo` / `openssl.cafile`。


#### 注意事项
- 修改配置文件后，需重启对应服务以生效。
- 日志文件可用于排查服务运行中的问题。

#### 第三方组件许可与协议
- **wnmmp 本体**（脚本、配置等）以 Apache License 2.0 发布，详见仓库根 `LICENSE` 文件。
- 集成包内附带的第三方组件保留各自许可证，随官方发布物提供；其中：
  - **php-xqkeji**（xqkeji 低代码开发框架 PHP 扩展，二进制 `php_xqkeji.dll`）：采用「双重授权」协议（专有软件）。其二进制随包分发时必须附带 `LICENSE.md` 与 `NOTICES`（含 Phalcon BSD-3-Clause、Zephir MIT 第三方声明）且不得移除。`install.bat` 执行后会把这两个文件安装到 `php/ext/` 目录（与 `php_xqkeji.dll` 同目录）。基于该扩展开发的应用须遵循其双重授权条款：以 OSI 认证开源协议开源用户代码，或向授权方获取商业授权。详见 https://xqkeji.cn/。
  - Nginx / MySQL / MongoDB / PHP / Composer / nssm / RunHiddenConsole 等：各自遵循其官方许可证。

#### 许可证
wnmmp 本体遵循 Apache License 2.0 许可证。有关详细信息，请参阅 `LICENSE` 文件。
