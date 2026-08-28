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

REM ===================== 管理员权限检查 =====================
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo.
	echo "[警告] 卸载 Windows 服务需要管理员权限！"
	echo "请右键单击 uninstall_service.bat，选择以管理员身份运行。"
	echo.
	echo 按任意键关闭本窗口...
	pause >nul
	exit /b 1
)

set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set "TMP_DIR=%HOME_DIR%\tmp"
REM skipped-install record (each line: nginx / mysql / mongodb / php-cgi)
set "SKIP_FILE=%TMP_DIR%\skipped.lst"

set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"

if not exist "%NSSM_PATH%" (
	echo "未找到 nssm.exe"
	echo 按任意键关闭本窗口...
	pause >nul
	exit /b 1
)

REM skip components that were never installed (so we don't try to remove a missing service)
findstr /x /i /c:"nginx" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] nginx：未安装，跳过卸载
) else (
	%NSSM_PATH% stop wnmmp-nginx
	%NSSM_PATH% remove wnmmp-nginx confirm
)

findstr /x /i /c:"mongodb" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] mongodb：未安装，跳过卸载
) else (
	%NSSM_PATH% stop wnmmp-mongodb
	%NSSM_PATH% remove wnmmp-mongodb confirm
)

findstr /x /i /c:"mysql" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] mysql：未安装，跳过卸载
) else (
	%NSSM_PATH% stop wnmmp-mysql
	%NSSM_PATH% remove wnmmp-mysql confirm
)

findstr /x /i /c:"php-cgi" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] php-cgi：未安装，跳过卸载
) else (
	%NSSM_PATH% stop wnmmp-php-cgi
	%NSSM_PATH% remove wnmmp-php-cgi confirm
)

echo.
echo 卸载完成。按任意键关闭本窗口...
pause >nul

