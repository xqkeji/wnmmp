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

REM One service per php-cgi process: wnmmp-php-cgi-i listens on
REM PHP_CGI_PORT+i-1, the count comes from etc\php\php-cgi.conf.
call "%~dp0php-cgi-util.bat" :load

set "PHP_CGI_PATH=%HOME_DIR%\php\php-cgi.exe"

set "MSG1=正在安装 WNMMP php-cgi 服务（!PHP_CGI_PROCESSES! 个进程，端口 !PHP_CGI_PORT!-!PHP_CGI_PORT_END!，服务名 wnmmp-php-cgi-1 至 wnmmp-php-cgi-!PHP_CGI_PROCESSES!）..."
echo !MSG1!

REM Older wnmmp builds registered the unsuffixed wnmmp-php-cgi service, which
REM always binds the first port and would take it from wnmmp-php-cgi-1 at every
REM boot.
call :remove_one "wnmmp-php-cgi"

REM The whole possible range is walked so that instances left over from a bigger
REM processes value are unregistered too.
for /L %%i in (1,1,!PHP_CGI_SVC_MAX!) do (
	if %%i leq !PHP_CGI_PROCESSES! (
		call :install_one "%%i"
	) else (
		call :remove_one "wnmmp-php-cgi-%%i"
	)
)
goto :eof

REM NOTE: the lines below must stay free of unquoted Chinese, cmd.exe finds a
REM CALL target label by byte offset and the UTF-8/character drift can make it
REM land on a line above the label. See start.bat for the full explanation.

REM Args: 1=instance index. An already registered service is removed first:
REM nssm install never updates an existing service, so without the removal a
REM changed port or process count would keep running the old settings.
:install_one
set "PCGI_I=%~1"
set /a "PCGI_PORT=%PHP_CGI_PORT%+%PCGI_I%-1"
set "PCGI_SVC=wnmmp-php-cgi-%PCGI_I%"
sc query "%PCGI_SVC%" >nul 2>&1
if not errorlevel 1 call :remove_one "%PCGI_SVC%"
"%NSSM_PATH%" install "%PCGI_SVC%" "!PHP_CGI_PATH!"
"%NSSM_PATH%" set "%PCGI_SVC%" Description "WNMMP PHP FastCGI Server #!PCGI_I!"
"%NSSM_PATH%" set "%PCGI_SVC%" AppDirectory "%HOME_DIR%\php"
"%NSSM_PATH%" set "%PCGI_SVC%" AppParameters "-c ""%HOME_DIR%\etc\php\php.ini"" -b 127.0.0.1:%PCGI_PORT% -d error_log=""%HOME_DIR%\logs\php\error.log"""
"%NSSM_PATH%" set "%PCGI_SVC%" AppExit Default Restart
"%NSSM_PATH%" start "%PCGI_SVC%"
set "MSG1=[%PCGI_I%/%PHP_CGI_PROCESSES%] 服务 %PCGI_SVC% 已注册并启动，端口 %PCGI_PORT%"
echo !MSG1!
goto :eof

REM Args: 1=service name. Does nothing when that service is not registered.
:remove_one
set "PCGI_SVC=%~1"
sc query "%PCGI_SVC%" >nul 2>&1
if errorlevel 1 goto :eof
"%NSSM_PATH%" stop "%PCGI_SVC%" >nul 2>&1
"%NSSM_PATH%" remove "%PCGI_SVC%" confirm >nul 2>&1
set "MSG1=已停止并移除服务：%PCGI_SVC%"
echo !MSG1!
goto :eof
