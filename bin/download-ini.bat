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
REM NOTE on paths: do NOT trust %~dp0 in this script. When it is reached via a
REM bare `call "download-ini.bat"`, %0 carries NO path component, so %~dp0
REM silently expands to the CURRENT directory (the wnmmp root) instead of bin\,
REM and the parser is then looked for in the wrong place. The invariant we CAN
REM rely on is that install.bat does `cd /d %~dp0`, so the CWD is the wnmmp
REM root and "bin\..." is the correct spelling. The extra candidates below are
REM fallbacks for unusual CWDs.
REM ===========================================================================

if not defined HOME_DIR set "HOME_DIR=%CD%"

set "INI_PARSER="
if exist "bin\wnmmp-ini.bat" set "INI_PARSER=bin\wnmmp-ini.bat"
if not defined INI_PARSER if exist "%~dp0wnmmp-ini.bat" set "INI_PARSER=%~dp0wnmmp-ini.bat"
if not defined INI_PARSER if exist "%~dp0bin\wnmmp-ini.bat" set "INI_PARSER=%~dp0bin\wnmmp-ini.bat"
if not defined INI_PARSER goto ini_parser_missing

call "%INI_PARSER%"

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
REM The download is pinned to releases/archives, not releases/: windows.php.net
REM keeps only the current build in releases/ and moves the rest here, so a
REM pinned version would stop resolving the day the next patch ships. Both
REM directories carry the same bytes -- same sha256 as releases.json.
REM wnmmp.ini holds the full release id as the vendor publishes it, build
REM suffix included: php=8.5.12-1 downloads php-8.5.12-1-nts-Win32-vs17-x64.zip.
REM The 3 PECL extensions (mongodb / apcu / xdebug) are deliberately NOT listed
REM here: bin/download-php.bat resolves them at RUNTIME from the actually
REM installed php.exe version and picks the matching nts/vs17/x64 build, so
REM changing php= in wnmmp.ini can never desync them.
REM ---------------------------------------------------------------------------
set "PHP_DOWNLOAD_URL=https://windows.php.net/downloads/releases/archives/php-%CFG_php%-nts-Win32-vs17-x64.zip"

REM ---------------------------------------------------------------------------
REM xqkeji extension (gitee). The tag doubles as the version, e.g. v1.1.2-php8.5
REM ---------------------------------------------------------------------------
set "PHP_XQKEJI_DOWNLOAD_URL=https://gitee.com/xqkeji/php-xqkeji/repository/archive/%CFG_xqkeji%.zip"
set "PHP_XQKEJI_ZIP_DIR=php-xqkeji-%CFG_xqkeji%"

goto :eof

:ini_parser_missing
echo.
echo [ERROR] cannot locate bin\wnmmp-ini.bat
echo [ERROR] run install.bat from the wnmmp root directory.
echo.
pause
exit 1

:need
if not "%~2"=="" goto :eof
echo.
echo [ERROR] wnmmp.ini has no value for "%~1".
echo [ERROR] file: %WNMMP_INI%
echo [ERROR] add a line such as: %~1=1.2.3
echo.
pause
exit 1
