@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM Licensed under the Apache License, Version 2.0 (the "License");
REM you may not use this file except in compliance with the License.
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS,
REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM See the License for the specific language governing permissions and
REM limitations under the License.

REM Ensure TMP_DIR/DOWNLOAD_DIR are defined before any !var! use below.
if not defined TMP_DIR set "TMP_DIR=%~dp0tmp"
if not defined HOME set "HOME=%TMP_DIR%"
if not defined DOWNLOAD_DIR set "DOWNLOAD_DIR=%TMP_DIR%\download"

call "download-ini.bat"
if not exist "!DOWNLOAD_DIR!" mkdir "!DOWNLOAD_DIR!"

REM nginx (skip if user chose to skip due to port 80 occupied)
if not "%SKIP_NGINX%"=="1" (
	call "download-nginx.bat"
	echo "nginx 下载完成！"
) else (
	echo "[skip] nginx 安装已跳过，不下载"
)

REM mongodb (skip if user chose to skip due to port 27017 occupied)
if not "%SKIP_MONGODB%"=="1" (
	call "download-mongodb.bat"
	echo "mongodb 下载完成！"
) else (
	echo "[skip] mongodb 安装已跳过，不下载"
)

REM mysql (skip if user chose to skip due to port 3306 occupied)
if not "%SKIP_MYSQL%"=="1" (
	call "download-mysql.bat"
	echo "mysql 下载完成！"
) else (
	echo "[skip] mysql 安装已跳过，不下载"
)

REM PHP runtime is ALWAYS required (extensions / composer / PIE),
REM even when the php-cgi SERVICE is skipped (port 9000 occupied).
call "download-php.bat"
echo "php 下载完成！"

rd /s /q "!DOWNLOAD_DIR!"
echo "下载文件清理完成！"


