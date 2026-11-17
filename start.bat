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
REM the shipped config already listens on 443, so the nginx health check below
REM uses that port; after bin\make-ssl.bat disable it reads back 80 by itself.
call bin\ssl-util.bat :nginx_port NGINX_PORT
call bin\ssl-util.bat :https_enabled HTTPS_ON
REM Why the variables above exist: the old script slept a fixed 3 seconds after
REM every launch - seven times (mongodb, mysql, four php-cgi instances, nginx) -
REM and that check only proved a process NAME was in the task list, so a service
REM that exits at once (nginx without a certificate) was still reported as
REM started. Launches are no longer waited on one by one: each records its port
REM here, :snap captures netstat once per round for every port probe, and
REM :wait_all at the end polls the recorded ports until they really listen.
set "SNAP=%TMP_DIR%\ports.lst"
set "WA_PORTS="
set "WA_MAX=8"

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
call :snap

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
	REM ssl.conf reads the pair below from etc\nginx\ssl, which the repository
	REM does not carry; without them nginx exits at once, so name the fix.
	if "!HTTPS_ON!"=="1" if not exist "%HOME_DIR%\etc\nginx\ssl\wnmmp.pem" (
		set "MSG1=%C_WARN%[警告] etc\nginx\ssl 里没有证书，nginx 会起不来；先运行 bin\make-ssl.bat 签发%C_RST%"
		echo !MSG1!
	)
	call :start_svc nginx.exe "Nginx" "nginx.exe -p %HOME_DIR%\ -c %HOME_DIR%\etc\nginx\nginx.conf" !NGINX_PORT!
)

REM Must run before PATH is cleared below: netstat, findstr and taskkill are
REM found through it, and this is where every recorded port gets checked.
call :wait_all

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
call bin\port-util.bat :port_owner_snap "%SNAP%" %SVC_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
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
		call :wait1s
		call :snap
		set "PC_BUSY=0" & set "PC_PID="
		call bin\port-util.bat :port_owner_snap "%SNAP%" %SVC_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
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
REM No sleep is inserted here. Right after a launch the process is running in
REM every case, whether it will still be up in a second is not, so the only
REM proof worth taking is that its port comes up - and that is what :wait_all
REM at the end of this script checks, once for all the components instead of a
REM fixed sleep per component. Both ports and names are recorded below.
set "WA_PORTS=!WA_PORTS! %SVC_PORT%"
set "WA_NAME_%SVC_PORT%=%SVC_NAME%"
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

REM ===================== php-cgi multi-process startup =====================
REM One php-cgi.exe process per port: instance i listens on PHP_CGI_PORT+i-1,
REM so 4 processes means 9000-9003. The count and the first port live in
REM etc\php\php-cgi.conf; nginx spreads the requests over the whole set
REM through the upstream in etc\nginx\php_processes.conf, which is rebuilt
REM here before nginx starts. Each instance registers its port with :start_svc,
REM so :wait_all at the end of this script is the readiness check for all of
REM them; no per-instance sleep and no separate verify pass.
:start_php_cgi
call bin\php-cgi-util.bat :load
call bin\php-cgi-util.bat :gen_nginx
call :php_cgi_preclean
set "MSG1=[PHP-CGI] 计划启动 !PHP_CGI_PROCESSES! 个 php-cgi 进程，端口 !PHP_CGI_PORT!-!PHP_CGI_PORT_END!"
echo !MSG1!
for /L %%i in (1,1,!PHP_CGI_PROCESSES!) do call :php_cgi_start_one "%%i"
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
REM
REM Where the service names come from: the old code asked "sc query" for all 17
REM possible wnmmp-php-cgi names, one cmd process each, whether or not anything
REM ran. One tasklist pass over the php-cgi.exe images that are really up names
REM them instead, so the cost is a single process and a lowered "processes"
REM count still stops leftovers registered above the new range. The names are
REM ASCII, so the padding tasklist writes for its own column headers cannot
REM reach the filter. A service bound to a companion on the same line would be
REM missed, which is why the taskkill and the port check in :start_svc stay.
:php_cgi_preclean
call bin\php-cgi-util.bat :count_procs
if "%PHP_CGI_RUNNING%"=="0" goto :eof
for /f "usebackq tokens=3 delims=," %%s in (`tasklist /svc /fi "IMAGENAME eq php-cgi.exe" /fo csv /nh 2^>nul ^| findstr /i "wnmmp-php-cgi"`) do net stop "%%~s" /y >nul 2>&1
taskkill /f /im php-cgi.exe >nul 2>&1
call :wait1s
call :snap
goto :eof

REM ===================== helper :snap =====================
REM Args: none. Captures the listening sockets so every port probe of this run
REM is a findstr over the file instead of a netstat. cmd.exe starts a fresh
REM process for each netstat, and the previous code paid one per port, several
REM times over. Recapture after anything that can change port ownership.
:snap
netstat -ano 2>nul | findstr "LISTENING" > "%SNAP%" 2>nul
goto :eof

REM ===================== helper :wait1s =====================
REM Args: none. Waits about one second. timeout would be the obvious tool but
REM it refuses to run whenever stdin is redirected - which is the case when
REM start.bat is launched from another script or a pipe - and prints
REM "ERROR: Input redirection is not supported" in place of waiting, so the
REM readiness pass below would burn all of its rounds inside one second and
REM report every component as failed. ping over loopback has no such rule, and
REM the -w cap keeps a firewall that drops ICMP from stretching a round out.
:wait1s
ping -4 -n 2 -w 500 127.0.0.1 >nul 2>&1
goto :eof

REM ===================== readiness pass =====================
REM Args: none. Polls every port :start_svc recorded until it really listens.
REM One round is a fresh capture plus one findstr per pending port, so the
REM components that bind at once are confirmed in the first round and the slow
REM ones (mongod replaying its journal, mysqld opening the buffer pool) keep
REM polling. A port still silent after WA_MAX rounds is reported as not
REM started, which is what the fixed sleep used to call a success. Each port
REM prints its own line, so the php-cgi instances are named individually the
REM way the old verify pass counted them together.
:wait_all
if "!WA_PORTS!"=="" goto :eof
set "WA_TRIED=0"
:wa_round
call :snap
set "WA_NEXT="
set "WA_LEFT=0"
for %%p in (!WA_PORTS!) do call :wa_check %%p
if "!WA_LEFT!"=="0" goto :wa_done
if !WA_TRIED! GEQ %WA_MAX% (
	for %%p in (!WA_PORTS!) do call :wa_msg_timeout %%p
	goto :wa_done
)
set /a "WA_TRIED+=1"
call :wait1s
set "WA_PORTS=!WA_NEXT!"
goto :wa_round
:wa_done
del "%SNAP%" >nul 2>&1
goto :eof

REM Args: 1=port. Listening means done; anything else is carried to WA_NEXT so
REM the next round looks only at what is still pending.
:wa_check
findstr /c:":%~1 " "%SNAP%" >nul 2>&1
if not errorlevel 1 (
	call :wa_msg_ok "%~1"
	goto :eof
)
set "WA_NEXT=!WA_NEXT! %~1"
set /a "WA_LEFT+=1"
goto :eof

REM Args: 1=port. Reads back the display name :start_svc left for this port.
:wa_name
call set "WA_LABEL=%%WA_NAME_%~1%%"
if not defined WA_LABEL set "WA_LABEL=port %~1"
goto :eof

REM Args: 1=port. The port is up.
:wa_msg_ok
call :wa_name "%~1"
set "MSG1=%C_OK%[√] [!WA_LABEL!] 启动成功，端口 %~1 在监听%C_RST%"
echo !MSG1!
goto :eof

REM Args: 1=port. The port never came up within the polling rounds.
:wa_msg_timeout
call :wa_name "%~1"
set "MSG1=%C_WARN%[警告] [!WA_LABEL!] 端口 %~1 经 %WA_MAX% 轮检查后仍未监听，进程可能启动后立即退出，请查看 logs 目录下对应组件的日志%C_RST%"
echo !MSG1!
goto :eof
