@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Affero General Public License as
REM published by the Free Software Foundation, version 3 only.
REM SPDX-License-Identifier: AGPL-3.0-only
REM
REM This program is distributed in the hope that it will be useful, but
REM WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
REM Affero General Public License for more details.
REM
REM You should have received a copy of the GNU Affero General Public
REM License along with this program. If not, see
REM     https://www.gnu.org/licenses/
setlocal enabledelayedexpansion

REM ===========================================================================
REM bin\add-site.bat -- register one local site: nginx vhost + hosts + reload.
REM
REM   bin\add-site.bat <name> [project-dir]
REM
REM <name> becomes <name>.xqkeji.dev. project-dir defaults to www\<name> under
REM the wnmmp root; fast-admin passes the real project path, which is why a
REM project created inside www\default\ also works.
REM
REM Idempotent by design: an existing conf.d\<name>.conf is never overwritten,
REM a domain already claimed by another vhost is not claimed twice, and a hosts
REM entry that already resolves the domain is not appended again. Nothing here
REM touches default.conf, so the default site keeps working.
REM
REM The vhost listens on 443 only, because nginx.conf includes ssl.conf and
REM http_redirect.conf at http level: 80 is a blanket 301 to https. The cert
REM issued by make-ssl.bat already covers *.xqkeji.dev, so no re-issue is needed.
REM
REM Called automatically by fast-admin's post-create hook when this file is
REM found next to the project; it is equally usable by hand.
REM ===========================================================================

REM This tool sits in bin, so the root is that directory's parent. Taken from
REM %~dp0 rather than the working directory: double-clicking starts cmd in bin.
for %%i in ("%~dp0..") do set "HOME_DIR=%%~fi"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set "BIN_DIR=%HOME_DIR%\bin"
set "NGINX_DIR=%HOME_DIR%\etc\nginx"
set "CONF_DIR=%NGINX_DIR%\conf.d"
set "NGINX_EXE=%HOME_DIR%\nginx\nginx.exe"
set "CERT_PEM=%NGINX_DIR%\ssl\wnmmp.pem"
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"
REM Override for tests / non-standard Windows directories.
if defined ADD_SITE_HOSTS set "HOSTS_FILE=%ADD_SITE_HOSTS%"
set "DOMAIN_SUFFIX=xqkeji.dev"
set "TMP_DIR=%HOME_DIR%\tmp"

set "NAME=%~1"
set "PROJ_ARG=%~2"
if not defined NAME goto :usage
REM Validation goes through PowerShell, not findstr: findstr's regex character
REM classes are case-INsensitive ([a-z] matches CRM), and piping a variable into
REM it is unsafe -- the left side of a pipe runs in a child cmd that re-parses
REM the expanded text, so a name like a&b really does execute b. The name is
REM handed over as an environment variable, so it is never part of the command
REM text and cannot inject anything.
set "AS_NAME=%NAME%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if($env:AS_NAME -match '^[A-Za-z0-9][A-Za-z0-9-]*$'){exit 0}else{exit 1}"
if errorlevel 1 goto :bad_name
set "DOMAIN=%NAME%.%DOMAIN_SUFFIX%"

if defined PROJ_ARG (
	for %%i in ("%PROJ_ARG%") do set "PROJ=%%~fi"
) else (
	set "PROJ=%HOME_DIR%\www\%NAME%"
)
set "DOCROOT=%PROJ%\www"
if not exist "%DOCROOT%" goto :no_docroot
set "DOCROOT_URL=%DOCROOT:\=/%"
set "CONF=%CONF_DIR%\%NAME%.conf"

echo ==============================================================
set "MSG1= 添加本地站点：%DOMAIN%"
echo !MSG1!
echo ==============================================================

call :check_existing
if defined SKIP_CONF goto :hosts
call :write_conf
call :verify_nginx
if errorlevel 1 (
	del "%CONF%" >nul 2>&1
	set "MSG1=[错误] nginx 自检未通过，已删除刚生成的 %NAME%.conf，原有站点未受影响"
	echo !MSG1!
	exit /b 1
)
call :reload_nginx

:hosts
call :add_hosts
call :report
exit /b 0

REM ===================== helper :check_existing =====================
REM Sets SKIP_CONF when this site must not be written: either the file is
REM already there (the user may have edited it by hand) or another vhost already
REM answers for the same domain. findstr /m /c: is a literal substring scan over
REM every conf.d file, which also catches a proxy_set_header Host claim.
REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:check_existing
set "SKIP_CONF="
if exist "%CONF%" (
	set "MSG1=[跳过] 配置已存在，不覆盖：%CONF%"
	echo !MSG1!
	set "SKIP_CONF=1"
	goto :eof
)
findstr /i /m /c:"%DOMAIN%" "%CONF_DIR%\*.conf" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=[跳过] %DOMAIN% 已被 conf.d 里其它配置使用，不再重复添加"
	echo !MSG1!
	set "SKIP_CONF=1"
)
goto :eof

REM ===================== helper :write_conf =====================
REM Modeled on conf.d\crm.conf: relative logs, php_processes upstream, and the
REM asset/upload PHP-execution guard included BEFORE the php handler. The static
REM cache blocks of the sample site are left out on purpose -- they are tuning,
REM not something a generated site needs.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:write_conf
(
echo # Generated by bin\add-site.bat for %DOMAIN% -- edit freely.
echo # Re-running add-site.bat never overwrites an existing file.
echo server {
echo 	listen       443 ssl;
echo 	server_name  %DOMAIN%;
echo 	charset utf-8;
echo 	access_log logs/%NAME%_access.log;
echo 	error_log logs/%NAME%_error.log;
echo 	root    "%DOCROOT_URL%";
echo 	location = /favicon.ico {
echo 		try_files $uri =204;
echo 		log_not_found off;
echo 		access_log off;
echo 	}
echo 	location / {
echo 		index  index.html index.htm index.php;
echo 		autoindex  off;
echo 		try_files $uri $uri/ /index.php?_url=$uri^&$args;
echo 		include php_no_exec.conf;
echo 		location ~ \.php$ {
echo 			try_files  $uri =404;
echo 			fastcgi_pass   php_processes;
echo 			fastcgi_index  index.php;
echo 			fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
echo 			include        fastcgi_params;
echo 		}
echo 	}
echo }
) > "%CONF%"
set "MSG1=[√] 已生成 %CONF%"
echo !MSG1!
exit /b 0

REM ===================== helper :verify_nginx =====================
REM Same call make-ssl.bat uses. Quoted, and without a trailing backslash:
REM -p "DIR\" would let nginx's argv parsing eat the closing quote.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:verify_nginx
if not exist "%NGINX_EXE%" exit /b 0
"%NGINX_EXE%" -p "%HOME_DIR%" -c "%NGINX_DIR%\nginx.conf" -t
if errorlevel 1 exit /b 1
exit /b 0

REM ===================== helper :reload_nginx =====================
REM A running nginx keeps serving the old config until it re-reads it.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:reload_nginx
if not exist "%NGINX_EXE%" exit /b 0
tasklist /fi "IMAGENAME eq nginx.exe" /nh 2>nul | find /i "nginx.exe" >nul
if errorlevel 1 (
	set "MSG1=nginx 当前没有运行，下次 start.bat 会直接使用新配置"
	echo !MSG1!
	exit /b 0
)
"%NGINX_EXE%" -p "%HOME_DIR%" -c "%NGINX_DIR%\nginx.conf" -s reload
if errorlevel 1 (
	set "MSG1=[警告] 自动 reload 失败，请先 stop.bat 再 start.bat"
	echo !MSG1!
	exit /b 0
)
set "MSG1=[√] 已通知 nginx 重新加载配置"
echo !MSG1!
exit /b 0

REM ===================== helper :add_hosts =====================
REM hosts is append-only here: the domain is looked up as an exact hostname
REM token (comments stripped, every name on a line compared), so a line for
REM othercrm.xqkeji.dev does not count as a hit for crm.xqkeji.dev.
REM Writing hosts needs admin. :hosts_apply tries directly first and reports
REM "access denied" as exit 3; only then is one UAC elevation attempted.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:add_hosts
call :hosts_apply
set "RC=!errorlevel!"
if "!RC!"=="2" (
	set "MSG1=[跳过] hosts 里已有 %DOMAIN% 的解析，不重复添加"
	echo !MSG1!
	exit /b 0
)
if "!RC!"=="0" (
	set "MSG1=[√] hosts 已添加：127.0.0.1 %DOMAIN%"
	echo !MSG1!
	exit /b 0
)
call :hosts_elevate
call :hosts_apply
set "RC=!errorlevel!"
if "!RC!"=="2" (
	set "MSG1=[√] hosts 已添加（提权后）：127.0.0.1 %DOMAIN%"
	echo !MSG1!
	exit /b 0
)
set "MSG1=[警告] 无法写入 hosts（需要管理员权限）。请手动加一行：127.0.0.1 %DOMAIN%"
echo !MSG1!
set "MSG1=        文件：%HOSTS_FILE%"
echo !MSG1!
exit /b 0

REM ===================== helper :hosts_apply =====================
REM exit 2 = already resolved, 0 = appended, 3 = denied/failed.
REM PowerShell is used for the token comparison and the append: batch string
REM handling cannot do either reliably. Domain and path are passed as environment
REM variables rather than interpolated, so an apostrophe in the Windows profile
REM path (C:\Users\O'Brien\...) cannot break out of the script text.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:hosts_apply
set "AS_DOMAIN=%DOMAIN%"
set "AS_HOSTS=%HOSTS_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=$env:AS_DOMAIN; $p=$env:AS_HOSTS; $hit=$false; if(Test-Path -LiteralPath $p){ foreach($l in (Get-Content -LiteralPath $p)){ $t=($l -split '#')[0].Trim(); if($t){ $f=$t -split '\s+'; for($i=1;$i -lt $f.Count;$i++){ if($f[$i] -eq $d){ $hit=$true } } } } }; if($hit){ exit 2 }; try{ Add-Content -LiteralPath $p -Value ('127.0.0.1 '+$d) -Encoding ASCII -ErrorAction Stop; exit 0 }catch{ exit 3 }"
set "RC=!errorlevel!"
exit /b !RC!

REM ===================== helper :hosts_elevate =====================
REM One UAC prompt, running a one-line script from tmp. A file is used instead
REM of an inline -Command because the nested quoting of Start-Process plus
REM Add-Content is not survivable in batch. The file is deleted afterwards.
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:hosts_elevate
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%" >nul 2>&1
set "PS1=%TMP_DIR%\add-host.ps1"
> "%PS1%" echo Add-Content -LiteralPath "%HOSTS_FILE%" -Value "127.0.0.1 %DOMAIN%" -Encoding ASCII
set "MSG1=写入 hosts 需要管理员权限，正在请求提权（会弹出 UAC 确认框）..."
echo !MSG1!
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%PS1%'" >nul 2>&1
del "%PS1%" >nul 2>&1
exit /b 0

REM ===================== helper :report =====================
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:report
call "%BIN_DIR%\ssl-util.bat" :https_enabled HTTPS_ON
if not "!HTTPS_ON!"=="1" (
	set "MSG1=[警告] 当前 nginx 只在 80，新站点是 443 配置：请先运行 bin\make-ssl.bat enable"
	echo !MSG1!
)
if not exist "%CERT_PEM%" (
	set "MSG1=[警告] 未找到证书 %CERT_PEM%，请先运行 bin\make-ssl.bat enable"
	echo !MSG1!
)
echo ==============================================================
set "MSG1= 站点目录：%DOCROOT%"
echo !MSG1!
set "MSG1= 访问地址：https://%DOMAIN%/（http 会被 301 跳到 https）"
echo !MSG1!
if exist "%CERT_PEM%" (
	set "MSG1= 证书已覆盖 *.%DOMAIN_SUFFIX%，无需重签"
	echo !MSG1!
)
echo ==============================================================
exit /b 0

REM ===================== usage / errors =====================
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:usage
set "MSG1=用法：bin\add-site.bat <name> [project-dir]"
echo !MSG1!
set "MSG1=      name 会成为 <name>.%DOMAIN_SUFFIX%，project-dir 默认为 www\<name>"
echo !MSG1!
exit /b 1
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:bad_name
set "MSG1=[错误] 站点名只能包含字母、数字和连字符，且以字母或数字开头：%NAME%"
echo !MSG1!
exit /b 1
REM ---- keep the lines above this label 100% ASCII (see :check_existing).
REM ----
REM ----
:no_docroot
set "MSG1=[错误] 找不到站点入口目录：%DOCROOT%"
echo !MSG1!
set "MSG1=       请先把项目创建好，或用第二个参数指定项目目录"
echo !MSG1!
exit /b 1
