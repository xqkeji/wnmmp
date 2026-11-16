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
REM ---- ANSI status colours (harmless if the console lacks VT support):
REM ---- C_OK=green(success) C_SKIP=red(skip/error) C_WARN=yellow(warning) C_RST=reset
set "C_OK=[92m"
set "C_SKIP=[91m"
set "C_WARN=[93m"
set "C_RST=[0m"

REM ===================== 管理员权限检查 =====================
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo.
	set "MSG1=%C_WARN%[警告] 卸载 Windows 服务需要管理员权限！%C_RST%"
	echo !MSG1!
	set "MSG1=请右键单击 uninstall_service.bat，选择以管理员身份运行。"
	echo !MSG1!
	echo.
	set "MSG1=按任意键关闭本窗口..."
	echo !MSG1!
	pause >nul
	exit /b 1
)

cd /d %~dp0
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set "TMP_DIR=%HOME_DIR%\tmp"
REM skipped-install record (each line: nginx / mysql / mongodb / php-cgi)
set "SKIP_FILE=%TMP_DIR%\skipped.lst"

set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"

if not exist "%NSSM_PATH%" (
	set "MSG1=%C_SKIP%[错误] 未找到 nssm.exe%C_RST%"
	echo !MSG1!
	set "MSG1=按任意键关闭本窗口..."
	echo !MSG1!
	pause >nul
	exit /b 1
)

REM skip components that were never installed (so we don't try to remove a missing service)
findstr /x /i /c:"nginx" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] nginx：未安装，跳过卸载%C_RST%"
	echo !MSG1!
) else (
	%NSSM_PATH% stop wnmmp-nginx
	%NSSM_PATH% remove wnmmp-nginx confirm
)

findstr /x /i /c:"mongodb" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] mongodb：未安装，跳过卸载%C_RST%"
	echo !MSG1!
) else (
	%NSSM_PATH% stop wnmmp-mongodb
	%NSSM_PATH% remove wnmmp-mongodb confirm
)

findstr /x /i /c:"mysql" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] mysql：未安装，跳过卸载%C_RST%"
	echo !MSG1!
) else (
	%NSSM_PATH% stop wnmmp-mysql
	%NSSM_PATH% remove wnmmp-mysql confirm
)

findstr /x /i /c:"php-cgi" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] php-cgi：未安装，跳过卸载%C_RST%"
	echo !MSG1!
) else (
	call :remove_php_cgi
)

echo.
set "MSG1=%C_OK%[√] 卸载完成。按任意键关闭本窗口...%C_RST%"
echo !MSG1!
pause >nul

REM ===================== helper :remove_php_cgi =====================
REM php-cgi runs one Windows service per process, so every possible instance
REM name is walked up to PHP_CGI_SVC_MAX. The configured count is NOT used
REM here: instances left over from a bigger processes value must go too, and
REM the unsuffixed wnmmp-php-cgi name of the older single-process layout goes
REM with them (index 0).
:remove_php_cgi
call bin\php-cgi-util.bat :load
for /L %%i in (1,1,%PHP_CGI_SVC_MAX%) do call :remove_php_svc "%%i"
call :remove_php_svc "0"
goto :eof

REM Args: 1=instance index. Does nothing when that service is not registered.
:remove_php_svc
set "PCGI_SVC=wnmmp-php-cgi-%~1"
if "%~1"=="0" set "PCGI_SVC=wnmmp-php-cgi"
sc query "%PCGI_SVC%" >nul 2>&1
if errorlevel 1 goto :eof
"%NSSM_PATH%" stop "%PCGI_SVC%" >nul 2>&1
"%NSSM_PATH%" remove "%PCGI_SVC%" confirm >nul 2>&1
set "MSG1=已卸载服务 %PCGI_SVC%"
echo !MSG1!
goto :eof

