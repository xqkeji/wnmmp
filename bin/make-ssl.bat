@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM Licensed under the Apache License, Version 2.0 (the "License");
REM you may not use this file except in compliance with the License.
REM You may obtain a copy of the License at
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS,
REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM See the License for the specific language governing permissions and
REM limitations under the License.
setlocal enabledelayedexpansion

REM ---- ANSI status colours:
REM ---- C_OK=green(success) C_SKIP=red(skip/error) C_WARN=yellow(warning) C_RST=reset
set "C_OK=[92m"
set "C_SKIP=[91m"
set "C_WARN=[93m"
set "C_RST=[0m"

REM This tool sits in bin, so the root is that directory's parent. It is taken
REM from %~dp0 rather than from the working directory: double-clicking the file
REM starts cmd with the current directory set to bin.
for %%i in ("%~dp0..") do set "HOME_DIR=%%~fi"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set TMP_DIR=%HOME_DIR%\tmp
set "BIN_DIR=%HOME_DIR%\bin"
set "SSL_DIR=%HOME_DIR%\etc\nginx\ssl"
set "NGINX_DIR=%HOME_DIR%\etc\nginx"
set "MKCERT=%BIN_DIR%\mkcert.exe"
set "ENABLE_PS1=%BIN_DIR%\ssl-enable.ps1"
set "NGINX_EXE=%HOME_DIR%\nginx\nginx.exe"
set "CERT_PEM=%SSL_DIR%\wnmmp.pem"
set "CERT_KEY=%SSL_DIR%\wnmmp-key.pem"
REM Names the certificate is issued for. *.xqkeji.com is one label deep, which is
REM how the local hosts entries (crm.xqkeji.com and friends) resolve.
set "CERT_HOSTS=localhost 127.0.0.1 ::1 *.xqkeji.com"

echo ==============================================================
set "MSG1= WNMMP https：本地证书签发（bin\mkcert.exe）与 nginx 443 开关"
echo !MSG1!
echo ==============================================================

set "ACTION=%~1"
if not defined ACTION set "ACTION=enable"
set "ACTION=!ACTION:-=!"

if /i "!ACTION!"=="enable" goto :do_enable
if /i "!ACTION!"=="renew" goto :do_renew
if /i "!ACTION!"=="disable" goto :do_disable
if /i "!ACTION!"=="uninstall" goto :do_uninstall
if /i "!ACTION!"=="help" goto :do_help
set "MSG1=%C_SKIP%[错误] 不认识的参数：%~1%C_RST%"
echo !MSG1!
goto :do_help

REM ===================== enable =====================
:do_enable
call :require
if errorlevel 1 exit /b 1
call :state
set "MSG1=目标：443 https（同时停止监听 80）"
echo !MSG1!
call :install_ca
if errorlevel 1 exit /b 1
call :make_cert
if errorlevel 1 exit /b 1
call :check_443
if errorlevel 1 exit /b 1
call :switch enable
if errorlevel 1 exit /b 1
call :verify_nginx
if errorlevel 1 (
	set "MSG1=%C_WARN%[警告] nginx 自检未通过，已自动回退到 80，证书文件保留%C_RST%"
	echo !MSG1!
	call :switch disable
	exit /b 1
)
call :reload_nginx
call :report_on
exit /b 0

REM ===================== renew =====================
:do_renew
call :require
if errorlevel 1 exit /b 1
call :install_ca
if errorlevel 1 exit /b 1
call :make_cert
if errorlevel 1 exit /b 1
call :verify_nginx
if errorlevel 1 exit /b 1
call :reload_nginx
set "MSG1=%C_OK%[√] 证书已重新签发%C_RST%"
echo !MSG1!
exit /b 0

REM ===================== disable =====================
:do_disable
call :require
if errorlevel 1 exit /b 1
call :state
call :switch disable
if errorlevel 1 exit /b 1
call :verify_nginx
call :reload_nginx
echo ==============================================================
set "MSG1=%C_OK%[√] 已回到 http：站点只监听 80，nginx 不再读取 etc\nginx\ssl%C_RST%"
echo !MSG1!
set "MSG1=证书和本地根证书都还在。要一并清掉请运行 bin\make-ssl.bat uninstall"
echo !MSG1!
echo ==============================================================
exit /b 0

REM ===================== uninstall =====================
:do_uninstall
call :require
if errorlevel 1 exit /b 1
call :switch disable
if errorlevel 1 exit /b 1
call "%BIN_DIR%\ssl-util.bat" :https_enabled STILL_ON
if "!STILL_ON!"=="1" (
	set "MSG1=%C_WARN%[警告] 站点里还有手工写的 443 监听，未改动配置，也不删除证书%C_RST%"
	echo !MSG1!
	exit /b 1
)
set "MSG1=正在移除本地根证书并删除 wnmmp 的证书文件..."
echo !MSG1!
"%MKCERT%" -uninstall
if exist "%CERT_PEM%" del "%CERT_PEM%"
if exist "%CERT_KEY%" del "%CERT_KEY%"
call :verify_nginx
call :reload_nginx
echo ==============================================================
set "MSG1=%C_OK%[√] 已卸载：根证书从信任库移除，etc\nginx\ssl 里的证书与私钥已删除%C_RST%"
echo !MSG1!
set "MSG1=Firefox 需重启才会丢掉旧缓存的证书；浏览器里如有 https 站点请刷新"
echo !MSG1!
echo ==============================================================
exit /b 0

REM ===================== help =====================
:do_help
echo ==============================================================
set "MSG1=用法："
echo !MSG1!
set "MSG1=  bin\make-ssl.bat              签发证书并把站点切到 443 https"
echo !MSG1!
set "MSG1=  bin\make-ssl.bat renew        只重新签发证书，不改配置"
echo !MSG1!
set "MSG1=  bin\make-ssl.bat disable      站点回到 80，证书与根证书保留"
echo !MSG1!
set "MSG1=  bin\make-ssl.bat uninstall    回到 80，并移除信任库里的根证书、删除证书文件"
echo !MSG1!
set "MSG1=说明："
echo !MSG1!
set "MSG1=  1. 本地根证书装进当前用户信任库，不需要管理员权限；Firefox 需重启浏览器"
echo !MSG1!
set "MSG1=  2. 证书域名固定为 localhost、127.0.0.1、::1、*.xqkeji.com"
echo !MSG1!
set "MSG1=  3. 要访问的子域名请自行写入 hosts，例如 127.0.0.1 crm.xqkeji.com"
echo !MSG1!
set "MSG1=  4. 切到 443 后 start.bat 与 stop.bat 会按 443 检查 nginx，无需另配"
echo !MSG1!
echo ==============================================================
exit /b 0

REM ===================== helper :require =====================
:require
if exist "%MKCERT%" (
	if exist "%ENABLE_PS1%" (
		if exist "%NGINX_DIR%\nginx.conf" (
			if exist "%NGINX_DIR%\conf.d" exit /b 0
		)
	)
)
set "MSG1=%C_SKIP%[错误] 工具文件不完整，请逐项确认：%C_RST%"
echo !MSG1!
set "MSG1=  缺少 bin\mkcert.exe"
if not exist "%MKCERT%" echo !MSG1!
set "MSG1=  缺少 bin\ssl-enable.ps1"
if not exist "%ENABLE_PS1%" echo !MSG1!
set "MSG1=  缺少 etc\nginx\nginx.conf"
if not exist "%NGINX_DIR%\nginx.conf" echo !MSG1!
set "MSG1=  缺少 etc\nginx\conf.d 目录"
if not exist "%NGINX_DIR%\conf.d" echo !MSG1!
exit /b 1

REM ===================== helper :state =====================
:state
call "%BIN_DIR%\ssl-util.bat" :https_enabled HTTPS_ON
if "!HTTPS_ON!"=="1" (
	set "MSG1=当前：https，nginx 监听 443"
	echo !MSG1!
) else (
	set "MSG1=当前：http，nginx 监听 80"
	echo !MSG1!
)
exit /b 0

REM ===================== helper :install_ca =====================
:install_ca
set "MSG1=正在创建并信任本地根证书（mkcert -install）..."
echo !MSG1!
"%MKCERT%" -install
if errorlevel 1 (
	set "MSG1=%C_SKIP%[错误] 本地根证书安装失败，请看上面 mkcert 的提示%C_RST%"
	echo !MSG1!
	exit /b 1
)
exit /b 0

REM ===================== helper :make_cert =====================
:make_cert
if not exist "%SSL_DIR%" md "%SSL_DIR%"
set "MSG1=正在签发证书：%CERT_HOSTS%"
echo !MSG1!
"%MKCERT%" -cert-file "%CERT_PEM%" -key-file "%CERT_KEY%" %CERT_HOSTS%
if errorlevel 1 (
	set "MSG1=%C_SKIP%[错误] 证书签发失败，配置文件未改动%C_RST%"
	echo !MSG1!
	exit /b 1
)
if not exist "%CERT_PEM%" (
	set "MSG1=%C_SKIP%[错误] 没找到生成的 %CERT_PEM%%C_RST%"
	echo !MSG1!
	exit /b 1
)
set "CAROOT="
for /f "delims=" %%c in ('"%MKCERT%" -CAROOT 2^>nul') do set "CAROOT=%%c"
exit /b 0

REM ===================== helper :check_443 =====================
REM The config is only rewritten after this passes, so a busy 443 cannot leave
REM the sites switched over with nginx unable to bind.
:check_443
set "PC_BUSY=0"
set "PC_PID="
set "PC_IMG="
set "PC_SVC=N/A"
call "%BIN_DIR%\port-util.bat" :port_owner 443 PC_BUSY PC_PID PC_IMG PC_SVC
if not "!PC_BUSY!"=="1" exit /b 0
if /i "!PC_IMG!"=="nginx.exe" exit /b 0
set "MSG1=%C_WARN%[警告] 443 已被 !PC_IMG! 占用（PID=!PC_PID!，服务=!PC_SVC!），配置未改动%C_RST%"
echo !MSG1!
set "MSG1=一般是 IIS 的 W3SVC、Visual Studio 的 IIS Express 或 VMware NAT。停掉后重新运行本工具。"
echo !MSG1!
exit /b 1

REM ===================== helper :switch =====================
REM Args: 1=enable|disable
:switch
set "SWITCH=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENABLE_PS1%" -Root "%HOME_DIR%" -Action !SWITCH!
if errorlevel 3 (
	set "MSG1=%C_SKIP%[错误] etc\nginx\nginx.conf 里找不到 include conf.d 或 http 行的锚点，配置未改动%C_RST%"
	echo !MSG1!
	exit /b 3
)
if errorlevel 2 (
	set "MSG1=%C_SKIP%[错误] 找不到 etc\nginx 配置目录，配置未改动%C_RST%"
	echo !MSG1!
	exit /b 2
)
if errorlevel 1 (
	set "MSG1=%C_SKIP%[错误] 调用 bin\ssl-enable.ps1 失败，请确认系统里有 powershell.exe%C_RST%"
	echo !MSG1!
	exit /b 1
)
exit /b 0

REM ===================== helper :verify_nginx =====================
REM nginx -t reads the real config and loads the certificates, so a missing or
REM unreadable etc\nginx\ssl pair fails here instead of at start time. Without
REM nginx.exe (install.bat not run yet) the check is skipped, not faked.
:verify_nginx
if not exist "%NGINX_EXE%" (
	set "MSG1=%C_WARN%[提示] 还没有 nginx，跳过配置自检；请先运行 install.bat 再执行 start.bat%C_RST%"
	echo !MSG1!
	exit /b 0
)
REM Quoted, and without a trailing backslash: -p "DIR\" would let nginx's argv
REM parsing eat the closing quote, and an unquoted path breaks on a space in the
REM install directory. nginx appends the separator itself.
"%NGINX_EXE%" -p "%HOME_DIR%" -c "%HOME_DIR%\etc\nginx\nginx.conf" -t
if errorlevel 1 exit /b 1
exit /b 0

REM ===================== helper :reload_nginx =====================
REM A running nginx keeps answering on the old port until it re-reads the
REM config, so reload is attempted whenever the process is up.
:reload_nginx
if not exist "%NGINX_EXE%" exit /b 0
tasklist /fi "IMAGENAME eq nginx.exe" /nh 2>nul | find /i "nginx.exe" >nul
if errorlevel 1 (
	set "MSG1=nginx 当前没有运行，下次 start.bat 会直接使用新配置"
	echo !MSG1!
	exit /b 0
)
"%NGINX_EXE%" -p "%HOME_DIR%" -c "%HOME_DIR%\etc\nginx\nginx.conf" -s reload
if errorlevel 1 (
	set "MSG1=%C_WARN%[警告] 自动 reload 失败，请先 stop.bat 再 start.bat%C_RST%"
	echo !MSG1!
	exit /b 0
)
set "MSG1=%C_OK%[√] 已通知 nginx 重新加载配置%C_RST%"
echo !MSG1!
exit /b 0

REM ===================== helper :report_on =====================
:report_on
echo ==============================================================
set "MSG1=%C_OK%[√] 已启用 https：站点从 listen 80 改为 listen 443 ssl%C_RST%"
echo !MSG1!
set "MSG1=证书：etc\nginx\ssl\wnmmp.pem 与 etc\nginx\ssl\wnmmp-key.pem（私钥不入库）"
echo !MSG1!
if defined CAROOT set "MSG1=根证书目录：!CAROOT!，其中 rootCA.pem 可作为 curl.cainfo 或 PHP 的 openssl.cafile"
if defined CAROOT echo !MSG1!
set "MSG1=子域名要自己写进 hosts，例如：127.0.0.1 crm.xqkeji.com"
echo !MSG1!
set "MSG1=现在可以访问 https://localhost 与 https://crm.xqkeji.com（80 已不再监听）"
echo !MSG1!
echo ==============================================================
exit /b 0
