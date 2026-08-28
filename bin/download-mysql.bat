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
if not defined TMP_DIR set "TMP_DIR=%~dp0tmp"
if not defined DOWNLOAD_DIR set "DOWNLOAD_DIR=%TMP_DIR%\download"

set "MYSQL_DIR=%HOME_DIR%\mysql"

REM ---- resume guard: skip only when finalized with sentinel ----
set "MYSQL_INSTALLED=0"
if exist "%MYSQL_DIR%\_installed" set "MYSQL_INSTALLED=1"
if "%MYSQL_INSTALLED%"=="1" goto :mysql_skip
REM incomplete previous run (dir exists but not finalized) -> clean and retry
if exist "%MYSQL_DIR%" (
	echo [mysql] incomplete previous install detected, cleaning...
	rd /s /q "%MYSQL_DIR%" 2>nul
)
mkdir "%MYSQL_DIR%"

wget.exe --no-hsts --no-config -c -O %TMP_DIR%\download\mysql.zip %MYSQL_DOWNLOAD_URL%
if !errorlevel! neq 0 (
	echo.
	echo [ERROR] mysql 下载失败！安装未完成。
	echo [ERROR] URL: %MYSQL_DOWNLOAD_URL%
	echo [ERROR] 请检查网络后重新运行 install.bat（支持断点续传）。
	echo %DATE% %TIME% [mysql] download FAILED >> "%TMP_DIR%\install.errors.log"
	rd "%MYSQL_DIR%" 2>nul
	pause
	exit
)
unzip -o %TMP_DIR%\download\mysql.zip -d %TMP_DIR%\download
if !errorlevel! neq 0 (
	del %TMP_DIR%\download\mysql.zip
	wget.exe --no-hsts --no-config -O %TMP_DIR%\download\mysql.zip %MYSQL_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\mysql.zip -d %TMP_DIR%\download
	if !errorlevel! neq 0 (
		echo.
		echo [ERROR] mysql 解压失败！安装未完成。
		echo [ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。
		echo %DATE% %TIME% [mysql] extract FAILED >> "%TMP_DIR%\install.errors.log"
		rd "%MYSQL_DIR%" 2>nul
		pause
		exit
	)
)
xcopy "%TMP_DIR%\download\%MYSQL_ZIP_DIR%\*" "%MYSQL_DIR%" /E /H /Y /I
echo done > "%MYSQL_DIR%\_installed"
echo %DATE% %TIME% [mysql] installed (%MYSQL_ZIP_DIR%) >> "%TMP_DIR%\install.progress.log"
:mysql_skip


