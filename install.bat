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
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=%HOME_DIR%\tmp
REM mingw32 wget resolves ~/.wgetrc and ~/.wget-hsts from HOME. When install.bat
REM is double-clicked (cmd.exe), HOME is usually unset and that '~' expansion
REM fails with "Invalid argument". Point HOME at our writable tmp dir so wget
REM never hits an invalid path. This is inherited by every call'd child script.
if not defined HOME set "HOME=%TMP_DIR%"
set DOWNLOAD_DIR=%TMP_DIR%\download
REM skipped-install record: each line is a component key (nginx / mysql / mongodb / php-cgi)
set "SKIP_FILE=%TMP_DIR%\skipped.lst"

REM ---- admin (elevation) check: required to stop Windows services ----
REM net session needs admin; on non-admin it errors -> PC_ADMIN=0
net session >nul 2>&1
if errorlevel 1 ( set "PC_ADMIN=0" ) else ( set "PC_ADMIN=1" )

if exist "%TMP_DIR%\install.errors.log" del "%TMP_DIR%\install.errors.log"
echo === wnmmp install started %DATE% %TIME% === >> "%TMP_DIR%\install.progress.log"


REM find and stop service (so wnmmp's own running services free their ports first)
tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
tasklist | findstr /i php-cgi.exe && taskkill /f /im php-cgi.exe
tasklist | findstr /i nginx.exe && taskkill /f /im nginx.exe


REM ============== PORT PRE-CHECK (detect already-running / installed services) ==============
echo === 端口占用预检（检测 nginx/mysql/mongodb/php-cgi 是否已被占用）===
if "%WNMMP_SKIP_PORTCHECK%"=="1" (
	echo [port] 已设置 WNMMP_SKIP_PORTCHECK=1，跳过端口预检
	goto :portcheck_done
)
call :portcheck nginx 80 "Nginx" SKIP_NGINX
call :portcheck mysql 3306 "MySQL" SKIP_MYSQL
call :portcheck mongodb 27017 "MongoDB" SKIP_MONGODB
call :portcheck php-cgi 9000 "PHP-CGI" SKIP_PHP_CGI
:portcheck_done


call "bin\install-vc-redist.bat"
call "bin\download.bat"
echo === 初始化数据库（MySQL / MongoDB）===
REM mongodb init (skip if mongodb was skipped)
if not "%SKIP_MONGODB%"=="1" call "bin\init-mongodb.bat"
REM mysql init (skip if mysql was skipped)
if not "%SKIP_MYSQL%"=="1" call "bin\init-mysql.bat"
copy nul %TMP_DIR%\install.lock > nul
echo "安装完成！"
echo %DATE% %TIME% [bootstrap] vc-redist + downloads + init done >> "%TMP_DIR%\install.progress.log"
echo === wnmmp install complete %DATE% %TIME% === >> "%TMP_DIR%\install.progress.log"

REM ---- failure summary (if any component failed during download/install) ----
set "ERR_FILE=%TMP_DIR%\install.errors.log"
if exist "%ERR_FILE%" (
	for %%F in ("%ERR_FILE%") do set "ERR_SIZE=%%~zF"
	if !ERR_SIZE! gtr 0 (
		echo.
		echo **************************************************************
		echo * [警告] 以下组件在安装过程中下载/安装失败：
		echo **************************************************************
		type "%ERR_FILE%"
		echo * 可重新运行 install.bat 进行断点续传重试。
		echo.
	)
)

REM ---- skipped-install summary ----
if exist "%SKIP_FILE%" (
	echo.
	echo ==============================================================
	echo * [跳过安装记录] 本次以下组件未安装（端口被占用，用户选择跳过）：
	for /f "usebackq tokens=*" %%L in ("%SKIP_FILE%") do echo *   - %%L
	echo * 说明：nginx / mysql / mongodb 跳过 = 不下载、不初始化、不注册服务；
	echo *       php-cgi 跳过 = 不注册 FastCGI 服务（PHP 运行时仍正常安装）。
	echo * 如需补装被跳过的组件：释放对应端口后，删除 tmp\skipped.lst 中对应行，
	echo * 再重新运行 install.bat 即可。
	echo ==============================================================
)

echo Progress log: %TMP_DIR%\install.progress.log
REM clear variable
set HOME_DIR=
set PATH=

echo 安装完成。按任意键关闭本窗口...
pause >nul
goto :eof


REM ===================== helper :portcheck =====================
REM Args: %1=component key  %2=port  %3=display name  %4=output skip-flag var
:portcheck
set "PC_KEY=%~1"
set "PC_PORT=%~2"
set "PC_NAME=%~3"
set "PC_SKIPVAR=%~4"
set "%PC_SKIPVAR%=0"
REM honor a previously recorded skip (do not re-prompt on re-run)
if exist "%SKIP_FILE%" (
	findstr /x /i /c:"%PC_KEY%" "%SKIP_FILE%" >nul 2>&1
	if not errorlevel 1 (
		echo [skip] %PC_NAME% 已在跳过清单（tmp\skipped.lst），本次不安装/不检测
		set "%PC_SKIPVAR%=1"
		goto :eof
	)
)
REM is the port occupied by a LISTENING process? capture the owning PID.
set "PC_BUSY=0"
set "PC_PID="
for /f "tokens=*" %%L in ('netstat -ano 2^>nul ^| findstr /c:":%PC_PORT% " ^| findstr "LISTENING"') do (
	set "PC_BUSY=1"
	for /f "tokens=5" %%P in ("%%L") do set "PC_PID=%%P"
)
if "%PC_BUSY%"=="0" (
	echo [port] %PC_NAME% 端口 %PC_PORT% 空闲，可继续安装
	goto :eof
)
REM ---- port busy: reverse-lookup owner image + service; decide if it is ours ----
set "PC_IMG="
set "PC_SVC=N/A"
call :pid_lookup "%PC_PID%" PC_IMG PC_SVC
set "PC_SVC=!PC_SVC:Services: =!"
REM tasklist writes its output in the SYSTEM ANSI code page (936 on Chinese
REM Windows), NOT the 65001 page we switched to. When a process hosts no
REM service, column 3 is that page's bytes for the N/A marker, which are
REM invalid UTF-8 here and echo back as garbage. Service names are plain
REM ASCII, so anything outside the safe set is reported as N/A instead.
if not defined PC_SVC set "PC_SVC=N/A"
if not "!PC_SVC!"=="N/A" (
	> "%TMP_DIR%\pc_svc.txt" echo(!PC_SVC!
	findstr /x /r "[a-zA-Z0-9_.,-]*" "%TMP_DIR%\pc_svc.txt" >nul 2>&1
	if errorlevel 1 set "PC_SVC=N/A"
)
if /i "%PC_IMG%"=="nginx.exe" ( set "PC_OURS=1" ) else ( set "PC_OURS=0" )
if /i "%PC_IMG%"=="mysqld.exe" set "PC_OURS=1"
if /i "%PC_IMG%"=="mongod.exe" set "PC_OURS=1"
if /i "%PC_IMG%"=="php-cgi.exe" set "PC_OURS=1"
if "%PC_OURS%"=="1" (
	echo [port] !PC_NAME! 端口被 wnmmp 自身组件占用（!PC_IMG! PID=!PC_PID!, 服务=!PC_SVC!）
	if "%PC_ADMIN%"=="1" (
		if not "!PC_SVC!"=="N/A" (
			for /f "tokens=1 delims=," %%s in ("%PC_SVC%") do (
				echo [port] 尝试停止服务 %%s ...
				net stop "%%s" /y >nul 2>&1
			)
		)
		taskkill /f /pid !PC_PID! >nul 2>&1
	) else (
		echo [port] 非管理员权限，尝试结束进程 PID=!PC_PID! ...
		taskkill /f /pid !PC_PID! >nul 2>&1
	)
	REM re-check whether the port is now free
	set "PC_BUSY=0"
	for /f "tokens=*" %%L in ('netstat -ano 2^>nul ^| findstr /c:":%PC_PORT% " ^| findstr "LISTENING"') do set "PC_BUSY=1"
	if "!PC_BUSY!"=="0" (
		echo [port] !PC_NAME! 端口 !PC_PORT! 已释放，继续安装
		goto :eof
	)
	echo [port] 自动释放失败（服务可能设了自动重启或权限不足），转为手动处理。
)
echo.
echo **************************************************************
echo * [警告] !PC_NAME! 的端口 !PC_PORT! 已被占用！
REM PC_IMG/PC_PID/PC_SVC come from tasklist and are NOT under our control.
REM Interpolating them with %var% would expand them at PARSE time, so any
REM quote / paren / ampersand in the value would break the block and make
REM cmd treat the tail of a later line as a new command. !var! expands at
REM RUN time, after parsing, so it cannot do that. Hence: no block here.
echo * 占用者：!PC_IMG!，PID=!PC_PID!，服务=!PC_SVC!
if "%PC_OURS%"=="1" echo * 属于 wnmmp 自身组件，可安全停止。
if not "%PC_OURS%"=="1" echo * 非 wnmmp 组件，安装程序不会自动停止它，以免误停你依赖的关键服务（如 IIS、SQL Server 等）。
echo * 建议：在 Windows 服务 services.msc 中找到上述服务/进程并停止，再运行 install.bat。
echo **************************************************************
choice /C AS /N /M "请选择 [A] 中止安装稍后手动处理  或  [S] 跳过 !PC_NAME! 安装："
if errorlevel 2 (
	echo %DATE% %TIME% [skip] !PC_NAME! 安装被用户跳过（端口 !PC_PORT! 被占用） >> "%TMP_DIR%\install.progress.log"
	>>"%SKIP_FILE%" echo %PC_KEY%
	echo [skip] 已记录：跳过 %PC_NAME% 安装（详见 tmp\skipped.lst）
	set "%PC_SKIPVAR%=1"
	goto :eof
)
echo [abort] 安装已中止。请处理端口 %PC_PORT% 占用后，重新运行 install.bat。
echo %DATE% %TIME% [port-check] ABORTED: !PC_NAME! port !PC_PORT! occupied >> "%TMP_DIR%\install.progress.log"
echo 安装已中止。按任意键关闭本窗口...
pause >nul
exit
goto :eof

REM ===================== helper :pid_lookup =====================
REM Args: %1=PID  %2=out image-var  %3=out service-var
REM Sets %2=<image.exe>; %3="Services: <svc>" or "N/A"
:pid_lookup
set "%~2="
set "%~3=N/A"
REM tokens=1,2* and not 1,3: the service column may itself contain commas
REM (e.g. "svchost.exe","1780","BrokerInfrastructure,DcomLaunch,PlugPlay"),
REM so field 3 must be captured as *rest of line* into %%c. With tokens=1,3
REM only %%a/%%b are allocated and the column is chopped at the first comma.
for /f "tokens=1,2* delims=," %%a in ('tasklist /svc /fi "PID eq %~1" /fo csv /nh 2^>nul') do (
	set "%~2=%%~a"
	set "%~3=%%~c"
)
goto :eof


