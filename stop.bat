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
REM ---- ANSI status colours (harmless if the console lacks VT support:
REM ---- C_OK/C_SKIP stay empty and the [OK]/[SKIP] glyph just shows plain).
set "C_OK=[92m"
set "C_SKIP=[91m"
set "C_WARN=[93m"
set "C_RST=[0m"
cd /d %~dp0
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"
set "EXT_OCC=0"
REM After bin\make-ssl.bat the sites listen on 443, so nginx must be looked up
REM on that port instead of a hard-coded 80.
call bin\ssl-util.bat :nginx_port NGINX_PORT

echo ==============================================================
echo  WNMMP 停止：停止 wnmmp 组件，并检测外部端口占用
echo ==============================================================

call :stop_one nginx.exe wnmmp-nginx !NGINX_PORT!
call :stop_one mysqld.exe wnmmp-mysql 3306
call :stop_one mongod.exe wnmmp-mongodb 27017
call :stop_php_cgi

echo.
if "!EXT_OCC!"=="1" (
    set "MSG1=%C_SKIP%[×] [注意] 部分组件停止后端口仍被外部组件占用，或自身服务配置了自动重启。%C_RST%"
    set "MSG2=[注意] 这些项需你手动处理：请停止对应外部进程或服务后，重试 stop.bat。"
) else (
    set "MSG1=%C_OK%[√] 已完成。所有 wnmmp 组件均已停止。%C_RST%"
    set "MSG2="
)
echo !MSG1!
if defined MSG2 echo !MSG2!
echo.
echo 按任意键关闭本窗口...
pause >nul
exit /b

REM ===================== helper :stop_one =====================
REM Args: 1=process image  2=service name  3=port
REM
REM Known wnmmp components are stopped in two steps: stop the Windows
REM service when it exists, then kill any remaining process. If the port
REM is still held afterwards, the owner is reported and EXT_OCC is set.
REM An external owner is only reported, never stopped automatically.
REM
REM NOTE: these lines must stay 100% ASCII. cmd.exe locates a CALL target
REM label by byte offset inside the batch file, and in a UTF-8 file that
REM contains Chinese text that offset can land a few lines ABOVE the
REM label. Execution then falls through whatever sits in front of the
REM label, so every line here must be a harmless ASCII remark.
:stop_one
set "P=%~1"
set "SVC=%~2"
set "PORT=%~3"
echo ------------------------------------------------------------
sc query "%SVC%" >nul 2>&1
if not errorlevel 1 (
	echo [%P%] 停止服务 %SVC% ...
	net stop "%SVC%" /y >nul 2>&1
)
taskkill /f /im "%P%" >nul 2>&1
REM The message body is stored first: cmd counts line boundaries in characters
REM while CJK takes 3 bytes here, so a raw Chinese ECHO can be cut mid-line.
if not errorlevel 1 (
	set "MSG1=%C_OK%[√] [%P%] 进程已停止%C_RST%"
) else (
	set "MSG1=%C_OK%[√] [%P%] 进程未运行或无需停止%C_RST%"
)
echo !MSG1!
set "PC_BUSY=0" & set "PC_PID=" & set "PC_IMG=" & set "PC_SVC=N/A" & set "PC_OURS=0"
call bin\port-util.bat :port_owner %PORT% PC_BUSY PC_PID PC_IMG PC_SVC
if "!PC_BUSY!"=="1" (
	if /i "!PC_IMG!"=="nginx.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mysqld.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mongod.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="php-cgi.exe" set "PC_OURS=1"
	if "!PC_OURS!"=="1" (
		call :stop_msg_self
		set "EXT_OCC=1"
	) else (
		call :stop_msg_ext
		set "EXT_OCC=1"
	)
)
goto :eof

REM ===================== messages for :stop_one =====================
REM
REM Chinese text is first stored into a variable (inside quotes, so it is
REM safe) and then printed by a pure ASCII ECHO line. Reason: cmd.exe tracks
REM line boundaries by character count while this file is UTF-8 where one CJK
REM character is 3 bytes, so that count drifts. Inside a parenthesized block
REM the drift accumulates and a long Chinese ECHO line gets cut in the middle;
REM its tail then runs as a new command and prints "'...' is not recognized".
REM An ECHO line holding only !MSGn! carries no CJK bytes, so it is never cut.
REM Keep the remarks in front of each label 100% ASCII.
:stop_msg_self
set "MSG1=%C_WARN%[警告] 端口 !PORT! 仍被 wnmmp 自身组件 !PC_IMG! 占用（可能服务配置了自动重启），请检查。%C_RST%"
echo !MSG1!
set "EXT_OCC=1"
goto :eof

REM Args: none. Reports an external port owner; never stops other services.
:stop_msg_ext
set "MSG1=%C_WARN%[警告] 端口 !PORT! 被外部组件占用（!PC_IMG! PID=!PC_PID! 服务=!PC_SVC!）%C_RST%"
set "MSG2=[提示] 该进程/服务非 wnmmp 组件，停止脚本不会自动处理，请手动停止该外部组件后再重试 stop.bat。"
echo !MSG1!
echo !MSG2!
set "EXT_OCC=1"
goto :eof

REM ===================== helper :stop_php_cgi =====================
REM php-cgi runs one process per port (PHP_CGI_PORT+i-1, count from
REM etc\php\php-cgi.conf), so every registered instance is stopped by service
REM name first: nssm restarts a php-cgi.exe that is only killed, and the
REM respawned process would hold its port again.
:stop_php_cgi
call bin\php-cgi-util.bat :load
call bin\php-cgi-util.bat :count_procs
for /L %%i in (1,1,%PHP_CGI_SVC_MAX%) do call :stop_php_svc "%%i"
call :stop_php_svc "0"
taskkill /f /im php-cgi.exe >nul 2>&1
set "MSG1=[PHP-CGI] 已结束 !PHP_CGI_RUNNING! 个 php-cgi 进程（配置 !PHP_CGI_PROCESSES! 个，端口 !PHP_CGI_PORT!-!PHP_CGI_PORT_END!）"
echo !MSG1!
for /L %%i in (1,1,%PHP_CGI_PROCESSES%) do call :stop_php_port "%%i"
goto :eof

REM Args: 1=instance index. Index 0 is the unsuffixed wnmmp-php-cgi service of
REM the older single-process layout, stopped too so an upgrade leaves nothing
REM running behind.
:stop_php_svc
set "PCGI_SVC=wnmmp-php-cgi-%~1"
if "%~1"=="0" set "PCGI_SVC=wnmmp-php-cgi"
sc query "%PCGI_SVC%" >nul 2>&1
if errorlevel 1 goto :eof
set "MSG1=停止服务 %PCGI_SVC% ..."
echo !MSG1!
net stop "%PCGI_SVC%" /y >nul 2>&1
goto :eof

REM Args: 1=instance index. A port that is still held after the stop is
REM reported, never taken over by force when the owner is foreign.
:stop_php_port
set /a "PCGI_PORT=%PHP_CGI_PORT%+%~1-1"
set "PC_BUSY=0" & set "PC_PID=" & set "PC_IMG=" & set "PC_SVC=N/A"
call bin\port-util.bat :port_owner %PCGI_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
if not "!PC_BUSY!"=="1" goto :eof
call :stop_php_port_msg
goto :eof

REM Args: none. Runs with PCGI_PORT / PC_IMG / PC_PID / PC_SVC filled in.
:stop_php_port_msg
set "MSG1=%C_WARN%[警告] php-cgi 端口 !PCGI_PORT! 停止后仍被占用（!PC_IMG! PID=!PC_PID! 服务=!PC_SVC!）%C_RST%"
set "MSG2=[提示] 占用者若是外部进程，stop.bat 不会强行停止它，请手动处理后重试。"
echo !MSG1!
echo !MSG2!
set "EXT_OCC=1"
goto :eof
