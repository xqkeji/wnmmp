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

set "MONGODB_DIR=%HOME_DIR%\mongodb"
set "MONGODB_IS_OLD=0"
set "MONGOSH_IS_OLD=0"

REM ---- resume guard: skip only when finalized with sentinel ----
set "MONGODB_INSTALLED=0"
if exist "%MONGODB_DIR%\_installed" set "MONGODB_INSTALLED=1"
if "%MONGODB_INSTALLED%"=="1" goto :mongo_skip
REM incomplete previous run (dir exists but not finalized) -> clean and retry
if exist "%MONGODB_DIR%" (
	echo [mongodb] incomplete previous install detected, cleaning...
	rd /s /q "%MONGODB_DIR%" 2>nul
)
mkdir "%MONGODB_DIR%"

REM ============================ mongodb server ============================
set "USED_URL=%MONGODB_DOWNLOAD_URL%"
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -c -O %TMP_DIR%\download\mongodb.zip %MONGODB_DOWNLOAD_URL%
if !errorlevel! neq 0 (
	echo [WARN] mongodb 下载失败，尝试旧版 5.0.33...
	del %TMP_DIR%\download\mongodb.zip 2>nul
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -c -O %TMP_DIR%\download\mongodb.zip %MONGODB_OLD_DOWNLOAD_URL%
	if !errorlevel! neq 0 (
		echo.
		echo [ERROR] mongodb 下载失败！安装未完成。
		echo [ERROR] URL: %MONGODB_DOWNLOAD_URL% 及旧版 %MONGODB_OLD_DOWNLOAD_URL%
		echo [ERROR] 请检查网络后重新运行 install.bat（支持断点续传）。
		echo %DATE% %TIME% [mongodb] download FAILED >> "%TMP_DIR%\install.errors.log"
		rd "%MONGODB_DIR%" 2>nul
		pause
		exit
	)
	set "MONGODB_IS_OLD=1"
	set "USED_URL=%MONGODB_OLD_DOWNLOAD_URL%"
)
unzip -o %TMP_DIR%\download\mongodb.zip -d %TMP_DIR%\download
if !errorlevel! neq 0 (
	del %TMP_DIR%\download\mongodb.zip
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -O %TMP_DIR%\download\mongodb.zip %USED_URL%
	unzip -o %TMP_DIR%\download\mongodb.zip -d %TMP_DIR%\download
	if !errorlevel! neq 0 (
		echo.
		echo [ERROR] mongodb 解压失败！安装未完成。
		echo [ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。
		echo %DATE% %TIME% [mongodb] extract FAILED >> "%TMP_DIR%\install.errors.log"
		rd "%MONGODB_DIR%" 2>nul
		pause
		exit
	)
)

REM ============================== mongosh ===============================
set "SH_USED_URL=%MONGOSH_DOWNLOAD_URL%"
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -c -O %TMP_DIR%\download\mongosh.zip %MONGOSH_DOWNLOAD_URL%
if !errorlevel! neq 0 (
	echo [WARN] mongosh 下载失败，尝试旧版 1.10.6...
	del %TMP_DIR%\download\mongosh.zip 2>nul
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -c -O %TMP_DIR%\download\mongosh.zip %MONGOSH_OLD_DOWNLOAD_URL%
	if !errorlevel! neq 0 (
		echo.
		echo [ERROR] mongosh 下载失败！安装未完成。
		echo [ERROR] URL: %MONGOSH_DOWNLOAD_URL% 及旧版 %MONGOSH_OLD_DOWNLOAD_URL%
		echo [ERROR] 请检查网络后重新运行 install.bat（支持断点续传）。
		echo %DATE% %TIME% [mongosh] download FAILED >> "%TMP_DIR%\install.errors.log"
		rd "%MONGODB_DIR%" 2>nul
		pause
		exit
	)
	set "MONGOSH_IS_OLD=1"
	set "SH_USED_URL=%MONGOSH_OLD_DOWNLOAD_URL%"
)
unzip -o %TMP_DIR%\download\mongosh.zip -d %TMP_DIR%\download
if !errorlevel! neq 0 (
	del %TMP_DIR%\download\mongosh.zip
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -O %TMP_DIR%\download\mongosh.zip %SH_USED_URL%
	unzip -o %TMP_DIR%\download\mongosh.zip -d %TMP_DIR%\download
	if !errorlevel! neq 0 (
		echo.
		echo [ERROR] mongosh 解压失败！安装未完成。
		echo [ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。
		echo %DATE% %TIME% [mongosh] extract FAILED >> "%TMP_DIR%\install.errors.log"
		rd "%MONGODB_DIR%" 2>nul
		pause
		exit
	)
)

if !MONGODB_IS_OLD! equ 0 (
	xcopy "%TMP_DIR%\download\%MONGODB_ZIP_DIR%\*" "%MONGODB_DIR%" /E /H /Y /I
) else (
	xcopy "%TMP_DIR%\download\%MONGODB_OLD_ZIP_DIR%\*" "%MONGODB_DIR%" /E /H /Y /I
)
if !MONGOSH_IS_OLD! equ 0 (
	copy "%TMP_DIR%\download\%MONGOSH_ZIP_DIR%\bin\mongosh.exe" "%MONGODB_DIR%\bin\mongosh.exe" /Y
) else (
	copy "%TMP_DIR%\download\%MONGOSH_OLD_ZIP_DIR%\bin\mongosh.exe" "%MONGODB_DIR%\bin\mongosh.exe" /Y
)

if !MONGODB_IS_OLD! equ 0 ( set "LOG_M=%MONGODB_ZIP_DIR%" ) else ( set "LOG_M=%MONGODB_OLD_ZIP_DIR%" )
if !MONGOSH_IS_OLD! equ 0 ( set "LOG_S=%MONGOSH_ZIP_DIR%" ) else ( set "LOG_S=%MONGOSH_OLD_ZIP_DIR%" )
echo done > "%MONGODB_DIR%\_installed"
echo %DATE% %TIME% [mongodb] installed !LOG_M! / mongosh !LOG_S! >> "%TMP_DIR%\install.progress.log"
:mongo_skip


