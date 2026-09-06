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
		echo   - %%K  √ 将启动
	) else (
		echo   - %%K  × 跳过（已在 tmp\skipped.lst）
	)
)
echo ==============================================================

REM ---- mongodb ----
findstr /x /i /c:"mongodb" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] mongodb：已在跳过清单，不启动
) else (
	call :start_svc mongod.exe "MongoDB" "mongod.exe --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log --auth" 27017
)

REM ---- mysql ----
findstr /x /i /c:"mysql" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] mysql：已在跳过清单，不启动
) else (
	call :start_svc mysqld.exe "MySQL" "mysqld.exe --defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log""" 3306
)

REM ---- php-cgi ----
findstr /x /i /c:"php-cgi" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] php-cgi：已在跳过清单，不启动
) else (
	call :start_svc php-cgi.exe "PHP-CGI" "php-cgi.exe -c %HOME_DIR%\etc\php\php.ini -b 127.0.0.1:9000 -d error_log=""%HOME_DIR%\logs\php\error.log""" 9000
)

REM ---- nginx ----
findstr /x /i /c:"nginx" "%SKIP_FILE%" >nul 2>&1
if not errorlevel 1 (
	echo [skip] nginx：已在跳过清单，不启动
) else (
	call :start_svc nginx.exe "Nginx" "nginx.exe -p %HOME_DIR%\ -c %HOME_DIR%\etc\nginx\nginx.conf" 80
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
set "MSG1=[警告] !SVC_NAME! 端口 !SVC_PORT! 停止后仍未释放（可能服务自动重启或权限不足），跳过启动。"
echo !MSG1!
goto :eof

REM Args: none. Port was released, starting now.
:svc_msg_released
set "MSG1=[!SVC_NAME!] 端口 !SVC_PORT! 已释放，正在启动..."
echo !MSG1!
goto :eof

REM Args: none. External owner - reported only, never stopped.
:svc_msg_external
set "MSG1=[警告] !SVC_NAME! 端口 !SVC_PORT! 被外部组件占用（!PC_IMG! PID=!PC_PID! 服务=!PC_SVC!）"
set "MSG2=[提示] 该进程/服务非 wnmmp 组件，请先手动停止该外部组件（可在 Windows 服务 services.msc 中处理），再运行 start.bat。"
set "MSG3=[提示] 本次跳过 !SVC_NAME! 启动。"
echo !MSG1!
echo !MSG2!
echo !MSG3!
goto :eof

REM Args: none. Port is free, starting now.
:svc_msg_free
set "MSG1=[!SVC_NAME!] 端口 !SVC_PORT! 空闲，正在启动..."
echo !MSG1!
goto :eof
