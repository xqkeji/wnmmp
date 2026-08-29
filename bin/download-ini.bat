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

REM ===========================================================================
REM bin/download-ini.bat -- builds every component's download URL and zip
REM folder name from the versions declared in wnmmp.ini.
REM
REM This file used to (1) hardcode one URL per component and then (2) call
REM bin/get-latest.bat to probe vendor sites and override them. That probing
REM made installs non-deterministic: vendor pages change layout, gitee rate
REM limits anonymous API calls, and dev.mysql.com answers 403 to scripts, so
REM detection silently failed and stale pinned values (or worse, half-built
REM URLs) were used instead. All probing is gone -- wnmmp.ini is the single
REM source of truth and NOTHING here touches the network.
REM
REM To upgrade a component edit wnmmp.ini, not this file.
REM
REM NOTE on paths: %~dp0 is used instead of bare/relative names so this works
REM no matter what the current directory happens to be when install.bat runs.
REM ===========================================================================

if not defined HOME_DIR for %%i in ("%~dp0..") do set "HOME_DIR=%%~fi"

call "%~dp0wnmmp-ini.bat"

REM ---------------------------------------------------------------------------
REM Validate: every component needs a non-empty version before we build URLs,
REM otherwise wget would be handed something like ".../nginx-.zip" and fail
REM with a confusing error much later.
REM ---------------------------------------------------------------------------
call :need nginx "%CFG_nginx%"
call :need mysql "%CFG_mysql%"
call :need mongodb "%CFG_mongodb%"
call :need mongosh "%CFG_mongosh%"
call :need php "%CFG_php%"
call :need xqkeji "%CFG_xqkeji%"

REM ---------------------------------------------------------------------------
REM nginx
REM ---------------------------------------------------------------------------
set "NGINX_DOWNLOAD_URL=https://nginx.org/download/nginx-%CFG_nginx%.zip"
set "NGINX_ZIP_DIR=nginx-%CFG_nginx%"

REM ---------------------------------------------------------------------------
REM mysql
REM URL path carries only major.minor (26.7.0 -> MySQL-26.7), so derive it.
REM NOTE: the Innovation line uses calendar version YY.M.P since 2026-07 while
REM the LTS line (9.7 / 8.4) keeps the old scheme; the two are independent.
REM ---------------------------------------------------------------------------
for /f "tokens=1,2 delims=." %%x in ("%CFG_mysql%") do set "MYSQL_MM=%%x.%%y"
set "MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/MySQL-%MYSQL_MM%/mysql-%CFG_mysql%-winx64.zip"
set "MYSQL_ZIP_DIR=mysql-%CFG_mysql%-winx64"

REM ---------------------------------------------------------------------------
REM mongodb server + mongosh
REM ---------------------------------------------------------------------------
set "MONGODB_DOWNLOAD_URL=https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-%CFG_mongodb%.zip"
set "MONGODB_ZIP_DIR=mongodb-win32-x86_64-windows-%CFG_mongodb%"

set "MONGOSH_DOWNLOAD_URL=https://downloads.mongodb.com/compass/mongosh-%CFG_mongosh%-win32-x64.zip"
set "MONGOSH_ZIP_DIR=mongosh-%CFG_mongosh%-win32-x64"

REM ---------------------------------------------------------------------------
REM php runtime
REM The 3 PECL extensions (mongodb / apcu / xdebug) are deliberately NOT listed
REM here: bin/download-php.bat resolves them at RUNTIME from the actually
REM installed php.exe version and picks the matching nts/vs17/x64 build, so
REM changing php= in wnmmp.ini can never desync them.
REM ---------------------------------------------------------------------------
set "PHP_DOWNLOAD_URL=https://windows.php.net/downloads/releases/php-%CFG_php%-nts-Win32-vs17-x64.zip"

REM ---------------------------------------------------------------------------
REM xqkeji extension (gitee). The tag doubles as the version, e.g. v1.1.2-php8.5
REM ---------------------------------------------------------------------------
set "PHP_XQKEJI_DOWNLOAD_URL=https://gitee.com/xqkeji/php-xqkeji/repository/archive/%CFG_xqkeji%.zip"
set "PHP_XQKEJI_ZIP_DIR=php-xqkeji-%CFG_xqkeji%"

goto :eof

:need
if not "%~2"=="" goto :eof
echo.
echo [ERROR] wnmmp.ini has no value for "%~1".
echo [ERROR] file: %WNMMP_INI%
echo [ERROR] add a line such as: %~1=1.2.3
echo.
pause
exit 1
