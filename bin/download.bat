@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
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

REM Ensure TMP_DIR/DOWNLOAD_DIR are defined before any !var! use below.
if not defined TMP_DIR set "TMP_DIR=%~dp0tmp"
if not defined HOME set "HOME=%TMP_DIR%"
if not defined DOWNLOAD_DIR set "DOWNLOAD_DIR=%TMP_DIR%\download"

call "download-ini.bat"
if not exist "!DOWNLOAD_DIR!" mkdir "!DOWNLOAD_DIR!"

REM nginx (skip if user chose to skip due to port 80 occupied)
if not "%SKIP_NGINX%"=="1" (
	call "download-nginx.bat"
	set "MSG1=nginx 下载完成！"
	echo !MSG1!
) else (
	set "MSG1=[skip] nginx 安装已跳过，不下载"
	echo !MSG1!
)

REM mongodb (skip if user chose to skip due to port 27017 occupied)
if not "%SKIP_MONGODB%"=="1" (
	call "download-mongodb.bat"
	set "MSG1=mongodb 下载完成！"
	echo !MSG1!
) else (
	set "MSG1=[skip] mongodb 安装已跳过，不下载"
	echo !MSG1!
)

REM mysql (skip if user chose to skip due to port 3306 occupied)
if not "%SKIP_MYSQL%"=="1" (
	call "download-mysql.bat"
	set "MSG1=mysql 下载完成！"
	echo !MSG1!
) else (
	set "MSG1=[skip] mysql 安装已跳过，不下载"
	echo !MSG1!
)

REM PHP runtime is ALWAYS required (extensions / composer / PIE),
REM even when the php-cgi SERVICE is skipped (port 9000 occupied).
call "download-php.bat"
set "MSG1=php 下载完成！"
echo !MSG1!

rd /s /q "!DOWNLOAD_DIR!"
set "MSG1=下载文件清理完成！"
echo !MSG1!


