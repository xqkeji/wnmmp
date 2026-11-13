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

REM set variable
set PHP_FCGI_MAX_REQUESTS=1000
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=%HOME_DIR%\tmp
set INSTALL_FILE=%TMP_DIR%\install.lock
REM skipped-install record (each line: nginx / mysql / mongodb / php-cgi)
set "SKIP_FILE=%TMP_DIR%\skipped.lst"
REM nginx listens on 443 once bin\make-ssl.bat switched the sites over, so the
REM nginx health check below uses that port instead of a hard-coded 80.
call bin\ssl-util.bat :nginx_port NGINX_PORT

if not exist "%INSTALL_FILE%" (
    echo "请先运行 install.bat！"
	echo 按任意键关闭本窗口...
	pause >nul
	exit /b 1
)

echo ==============================================================
echo  WNMMP 启动清单（仅启动已安装组件，跳过清单见 tmp\skipped.lst）
for %%K in (nginx mongodb mysql php-cgi) do (
	findstr /x /i /c:"%%K" "%SKIP_FILE%" >nul 2>&1
	if errorlevel 1 (
		set "MSG1=  - %%K  将启动"
		echo !MSG1!
	) else (
		set "MSG1=  - %%K  跳过（已在 tmp\skipped.lst）"
		echo !MSG1!
	)
)
echo ==============================================================

REM ---- mongodb ----
findstr /x /i /c:"mongodb" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] mongodb：已在跳过清单，不启动%C_RST%"
	echo !MSG1!
) else (
	call :start_svc mongod.exe "MongoDB" "mongod.exe --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log --auth" 27017
)

REM ---- mysql ----
findstr /x /i /c:"mysql" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] mysql：已在跳过清单，不启动%C_RST%"
	echo !MSG1!
) else (
	call :start_svc mysqld.exe "MySQL" "mysqld.exe --defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log""" 3306
)

REM ---- php-cgi ----
findstr /x /i /c:"php-cgi" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] php-cgi：已在跳过清单，不启动%C_RST%"
	echo !MSG1!
) else (
	call :start_php_cgi
)

REM ---- nginx ----
findstr /x /i /c:"nginx" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	set "MSG1=%C_SKIP%[×] [skip] nginx：已在跳过清单，不启动%C_RST%"
	echo !MSG1!
) else (
	call :start_svc nginx.exe "Nginx" "nginx.exe -p %HOME_DIR%\ -c %HOME_DIR%\etc\nginx\nginx.conf" !NGINX_PORT!
)

set HOME_DIR=
set PATH=
echo.
echo 启动完成。按任意键关闭本窗口（各服务在后台继续运行）...
pause >nul
exit

REM ===================== helper :start_svc =====================
REM Args: 1=process image  2=display name  3=start command line  4=port
REM
REM Before starting, the port is checked: when a wnmmp component holds it
REM that component is stopped (service first, then process) and the port is
REM rechecked. When an external component holds it, the component is only
REM reported and its start is skipped - external services are never stopped.
REM
REM NOTE: these lines must stay 100% ASCII. cmd.exe locates a CALL target
REM label by byte offset inside the batch file, and in a UTF-8 file that
REM contains Chinese text that offset can land a few lines ABOVE the
REM label. Execution then falls through whatever sits in front of the
REM label, so every line here must be a harmless ASCII remark.
:start_svc
set "SVC_PROC=%~1"
set "SVC_NAME=%~2"
set "SVC_CMD=%~3"
set "SVC_PORT=%~4"
echo ------------------------------------------------------------
set "PC_BUSY=0" & set "PC_PID=" & set "PC_IMG=" & set "PC_SVC=N/A" & set "PC_OURS=0"
call bin\port-util.bat :port_owner %SVC_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
if "!PC_BUSY!"=="1" (
	if /i "!PC_IMG!"=="nginx.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mysqld.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mongod.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="php-cgi.exe" set "PC_OURS=1"
	if "!PC_OURS!"=="1" (
		call :svc_msg_occupied
		if not "!PC_SVC!"=="N/A" (
			for /f "tokens=1 delims=," %%s in ("%PC_SVC%") do net stop "%%s" /y >nul 2>&1
		)
		taskkill /f /im "%SVC_PROC%" >nul 2>&1
		timeout /t 1 >nul 2>&1
		set "PC_BUSY=0" & set "PC_PID="
		call bin\port-util.bat :port_owner %SVC_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
		if "!PC_BUSY!"=="1" (
			call :svc_msg_still_held
			goto :start_svc_done
		)
		call :svc_msg_released
	) else (
		call :svc_msg_external
		goto :start_svc_done
	)
) else (
	call :svc_msg_free
)
where "%SVC_PROC%" >nul 2>&1 && RunHiddenConsole.exe /l %SVC_CMD%
if errorlevel 1 (
	call :svc_msg_start_failed
	goto :start_svc_done
)
REM Health check: wait 3 seconds then verify the process is still alive.
REM If it exited immediately (crash / config error), report the failure.
timeout /t 3 /nobreak >nul
tasklist /fi "IMAGENAME eq %SVC_PROC%" /nh 2>nul | findstr /i "%SVC_PROC%" >nul 2>&1
if errorlevel 1 (
	call :svc_msg_start_failed
	goto :start_svc_done
)
call :svc_msg_start_ok
:start_svc_done
goto :eof

REM ===================== messages for :start_svc =====================
REM
REM Chinese text is first stored into a variable (inside quotes, so it is
REM safe) and then printed by a pure ASCII ECHO line. Reason: cmd.exe tracks
REM line boundaries by character count while this file is UTF-8 where one CJK
REM character is 3 bytes, so that count drifts. Inside a parenthesized block
REM the drift accumulates and a long Chinese ECHO line gets cut in the middle;
REM its tail then runs as a new command and prints "'...' is not recognized".
REM An ECHO line holding only !MSGn! carries no CJK bytes, so it is never cut.
REM Keep the remarks in front of each label 100% ASCII.
:svc_msg_occupied
set "MSG1=[!SVC_NAME!] 端口 !SVC_PORT! 被 wnmmp 自身组件占用（!PC_IMG! PID=!PC_PID! 服务=!PC_SVC!），先停止再启动..."
echo !MSG1!
goto :eof

REM Args: none. Port stayed busy after stopping the owner.
:svc_msg_still_held
set "MSG1=%C_WARN%[警告] !SVC_NAME! 端口 !SVC_PORT! 停止后仍未释放（可能服务自动重启或权限不足），跳过启动。%C_RST%"
echo !MSG1!
goto :eof

REM Args: none. Port was released, starting now.
:svc_msg_released
set "MSG1=%C_OK%[√] [!SVC_NAME!] 端口 !SVC_PORT! 已释放，正在启动...%C_RST%"
echo !MSG1!
goto :eof

REM Args: none. External owner - reported only, never stopped.
:svc_msg_external
set "MSG1=%C_WARN%[警告] !SVC_NAME! 端口 !SVC_PORT! 被外部组件占用（!PC_IMG! PID=!PC_PID! 服务=!PC_SVC!）%C_RST%"
set "MSG2=[提示] 该进程/服务非 wnmmp 组件，请先手动停止该外部组件（可在 Windows 服务 services.msc 中处理），再运行 start.bat。"
set "MSG3=[提示] 本次跳过 !SVC_NAME! 启动。"
echo !MSG1!
echo !MSG2!
echo !MSG3!
goto :eof

REM Args: none. Port is free, starting now.
:svc_msg_free
set "MSG1=%C_OK%[√] [!SVC_NAME!] 端口 !SVC_PORT! 空闲，正在启动...%C_RST%"
echo !MSG1!
goto :eof

REM Args: none. Service failed to start or exited immediately.
:svc_msg_start_failed
set "MSG1=%C_WARN%[警告] !SVC_NAME! 启动失败或进程立即退出，请检查日志文件%C_RST%"
echo !MSG1!
goto :eof

REM Args: none. Service started successfully and process is running.
:svc_msg_start_ok
set "MSG1=%C_OK%[√] [!SVC_NAME!] 启动成功，进程运行中%C_RST%"
echo !MSG1!
goto :eof

REM ===================== php-cgi multi-process startup =====================
REM One php-cgi.exe process per port: instance i listens on PHP_CGI_PORT+i-1,
REM so 4 processes means 9000-9003. The count and the first port live in
REM etc\php\php-cgi.conf; nginx spreads the requests over the whole set
REM through the upstream in etc\nginx\php_processes.conf, which is rebuilt
REM here before nginx starts.
:start_php_cgi
call bin\php-cgi-util.bat :load
call bin\php-cgi-util.bat :gen_nginx
call :php_cgi_preclean
set "MSG1=[PHP-CGI] 计划启动 !PHP_CGI_PROCESSES! 个 php-cgi 进程，端口 !PHP_CGI_PORT!-!PHP_CGI_PORT_END!"
echo !MSG1!
for /L %%i in (1,1,!PHP_CGI_PROCESSES!) do call :php_cgi_start_one "%%i"
call :php_cgi_verify
goto :eof

REM Args: 1=instance index. Command line is the old single-process one with
REM the per-instance port substituted.
:php_cgi_start_one
set "PCGI_I=%~1"
set /a "PCGI_PORT=%PHP_CGI_PORT%+%PCGI_I%-1"
set "PCGI_NAME=PHP-CGI #%PCGI_I%"
set "PCGI_CMD=php-cgi.exe -c %HOME_DIR%\etc\php\php.ini -b 127.0.0.1:%PCGI_PORT% -d error_log=""%HOME_DIR%\logs\php\error.log"""
call :start_svc php-cgi.exe "%PCGI_NAME%" "%PCGI_CMD%" %PCGI_PORT%
goto :eof

REM No-arg helper. Leftovers must go before the loop, because :start_svc only
REM ever frees one port and would otherwise kill the instances started before
REM it. Registered services go first (AppExit Restart would respawn the
REM process), then any php-cgi.exe that is still up. Skipped when nothing runs
REM yet, so an unrelated php-cgi.exe is never killed for no reason.
:php_cgi_preclean
call bin\php-cgi-util.bat :count_procs
if "%PHP_CGI_RUNNING%"=="0" goto :eof
for /L %%i in (1,1,%PHP_CGI_SVC_MAX%) do call :php_cgi_stop_svc "%%i"
call :php_cgi_stop_svc "0"
taskkill /f /im php-cgi.exe >nul 2>&1
timeout /t 1 /nobreak >nul
goto :eof

REM Args: 1=instance index. Index 0 is the unsuffixed wnmmp-php-cgi service
REM registered by older wnmmp builds; it binds the first port and must not
REM compete with the new per-port instances.
:php_cgi_stop_svc
set "PCGI_SVC=wnmmp-php-cgi-%~1"
if "%~1"=="0" set "PCGI_SVC=wnmmp-php-cgi"
sc query "%PCGI_SVC%" >nul 2>&1
if errorlevel 1 goto :eof
net stop "%PCGI_SVC%" /y >nul 2>&1
goto :eof

REM No-arg helper. Counts the ports that really listen, which is the only
REM proof that the process is alive AND bound: :start_svc can only check that
REM some php-cgi.exe exists, and with several instances that says nothing
REM about this one.
:php_cgi_verify
set "PCGI_OK=0"
set "PCGI_BAD="
for /L %%i in (1,1,%PHP_CGI_PROCESSES%) do call :php_cgi_check_port "%%i"
set "MSG1=%C_OK%[√] [PHP-CGI] 多进程就绪：!PCGI_OK!/!PHP_CGI_PROCESSES! 个端口在监听（!PHP_CGI_PORT!-!PHP_CGI_PORT_END!）%C_RST%"
echo !MSG1!
if "!PCGI_OK!"=="!PHP_CGI_PROCESSES!" goto :eof
set "MSG1=%C_WARN%[警告] 这些端口上没有 php-cgi 进程：%PCGI_BAD%，该实例未启动或端口被外部占用，请检查 logs\php\error.log%C_RST%"
echo !MSG1!
goto :eof

REM Args: 1=instance index. A port counts only when our own php-cgi.exe holds
REM it; a free port or an external owner is collected in PCGI_BAD.
:php_cgi_check_port
set /a "PCGI_PORT=%PHP_CGI_PORT%+%~1-1"
set "PC_BUSY=0" & set "PC_PID=" & set "PC_IMG=" & set "PC_SVC=N/A"
call bin\port-util.bat :port_owner %PCGI_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
if not "!PC_BUSY!"=="1" goto :php_cgi_check_missing
if /i not "!PC_IMG!"=="php-cgi.exe" goto :php_cgi_check_missing
set /a "PCGI_OK+=1"
goto :eof

REM Args: none. Reached with PCGI_PORT holding the port that is not ours.
:php_cgi_check_missing
set "PCGI_BAD=!PCGI_BAD! %PCGI_PORT%"
goto :eof
