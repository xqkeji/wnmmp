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

wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -c -O %TMP_DIR%\download\mysql.zip %MYSQL_DOWNLOAD_URL%
if !errorlevel! neq 0 (
	echo.
	set "MSG1=[ERROR] mysql 下载失败！安装未完成。"
	echo !MSG1!
	echo [ERROR] URL: %MYSQL_DOWNLOAD_URL%
	set "MSG1=[ERROR] 请检查网络后重新运行 install.bat（支持断点续传）。"
	echo !MSG1!
	echo %DATE% %TIME% [mysql] download FAILED >> "%TMP_DIR%\install.errors.log"
	rd "%MYSQL_DIR%" 2>nul
	pause
	exit
)
unzip -o %TMP_DIR%\download\mysql.zip -d %TMP_DIR%\download
if !errorlevel! neq 0 (
	del %TMP_DIR%\download\mysql.zip
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -O %TMP_DIR%\download\mysql.zip %MYSQL_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\mysql.zip -d %TMP_DIR%\download
	if !errorlevel! neq 0 (
		echo.
		set "MSG1=[ERROR] mysql 解压失败！安装未完成。"
		set "MSG2=[ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。"
		echo !MSG1!
		echo !MSG2!
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


