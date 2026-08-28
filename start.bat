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
	pause
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
exit

REM ===================== helper :start_svc =====================
REM Args: %1=进程名  %2=显示名  %3=启动命令行  %4=端口
REM 启动前检测端口：被自身组件占用->停掉(服务/进程)后复查再启动；
REM 被外部组件占用->提示手动停止并跳过该组件启动（保守策略，不擅自停外部服务）。
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
		echo [%SVC_NAME%] 端口 %SVC_PORT% 被 wnmmp 自身组件占用（%PC_IMG% PID=%PC_PID% 服务=%PC_SVC%），先停止再启动...
		if not "!PC_SVC!"=="N/A" (
			for /f "tokens=1 delims=," %%s in ("!PC_SVC!") do net stop "%%s" /y >nul 2>&1
		)
		taskkill /f /im "%SVC_PROC%" >nul 2>&1
		timeout /t 1 >nul 2>&1
		set "PC_BUSY=0" & set "PC_PID="
		call bin\port-util.bat :port_owner %SVC_PORT% PC_BUSY PC_PID PC_IMG PC_SVC
		if "!PC_BUSY!"=="1" (
			echo [%SVC_NAME%] 端口 %SVC_PORT% 停止后仍未释放（可能服务自动重启或权限不足），跳过启动。
			goto :start_svc_done
		)
		echo [%SVC_NAME%] 端口 %SVC_PORT% 已释放，正在启动...
	) else (
		echo [!!] %SVC_NAME% 端口 %SVC_PORT% 被外部组件占用（%PC_IMG% PID=%PC_PID% 服务=%PC_SVC%）
		echo [!!] 该进程/服务非 wnmmp 组件，请先手动停止该外部组件（可在 服务(services.msc) 中处理），再运行 start.bat。
		echo [!!] 本次跳过 %SVC_NAME% 启动。
		goto :start_svc_done
	)
) else (
	echo [%SVC_NAME%] 端口 %SVC_PORT% 空闲，正在启动...
)
where "%SVC_PROC%" >nul 2>&1 && RunHiddenConsole.exe /l %SVC_CMD%
:start_svc_done
goto :eof


