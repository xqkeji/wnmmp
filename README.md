# wnmmp

- window+nginx+mysql+mongodb+php绿色集成开发环境（mongodb-8.0.11、mongosh-2.5.5、mysql-8.4.5、nginx-1.28.0、php-8.4.10）。
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


#### 配置文件
- **Nginx**：`etc/nginx/nginx.conf`
- **MySQL**：`etc/mysql/my.ini`
- **MongoDB**：`etc/mongodb/mongo.conf`
- **PHP**：`etc/php/php.ini`

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

#### 使用方法
1. **下载和安装**：
   - 要使用前必须先执行一次 `install.bat` 运行bin目录里的“VC_redist.x64.exe”的安装程序，下载所有组件,并自动完成初始化。
2. **启动服务**：
   - 运行 `start.bat` 启动所有服务。
3. **停止服务**：
   - 运行 `stop.bat` 停止所有服务。
4. **安装Window服务**：
   - 右键`install_service.bat`"以管理员身份运行”可以将服务注册为 Windows 服务，默认开机启动。
5. **卸载服务**：
   - 右键`uninstall_service.bat`"以管理员身份运行”可以卸载已注册的 Windows 服务。


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
