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
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"
set "EXT_OCC=0"

echo ==============================================================
echo  WNMMP 停止：停止 wnmmp 组件，并检测外部端口占用
echo ==============================================================

call :stop_one nginx.exe wnmmp-nginx 80
call :stop_one mysqld.exe wnmmp-mysql 3306
call :stop_one mongod.exe wnmmp-mongodb 27017
call :stop_one php-cgi.exe wnmmp-php-cgi 9000

echo.
if "!EXT_OCC!"=="1" (
    echo [注意] 部分组件停止后端口仍被外部组件占用，或自身服务配置了自动重启。
    echo [注意] 这些项需你手动处理：请停止对应外部进程或服务后，重试 stop.bat。
) else (
    echo 已完成。所有 wnmmp 组件均已停止。
)
echo.
echo 按任意键关闭本窗口...
pause >nul
exit /b

REM ===================== helper :stop_one =====================
REM 参数: 进程名  服务名  端口
REM 已知组件先停服务（若存在）再结束进程；端口复查若被外部组件占用则仅提示，不自动处理。
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
if not errorlevel 1 ( echo [%P%] 进程已停止 ) else ( echo [%P%] 进程未运行或无需停止 )
set "PC_BUSY=0" & set "PC_PID=" & set "PC_IMG=" & set "PC_SVC=N/A" & set "PC_OURS=0"
call bin\port-util.bat :port_owner %PORT% PC_BUSY PC_PID PC_IMG PC_SVC
if "!PC_BUSY!"=="1" (
	if /i "!PC_IMG!"=="nginx.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mysqld.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="mongod.exe" set "PC_OURS=1"
	if /i "!PC_IMG!"=="php-cgi.exe" set "PC_OURS=1"
	if "!PC_OURS!"=="1" (
		echo [!] 端口 %PORT% 仍被 wnmmp 自身组件 %PC_IMG% 占用（可能服务配置了自动重启），请检查。
		set "EXT_OCC=1"
	) else (
		echo [!!] 端口 %PORT% 被外部组件占用（%PC_IMG% PID=%PC_PID% 服务=%PC_SVC%）
		echo [!!] 该进程/服务非 wnmmp 组件，停止脚本不会自动处理，请手动停止该外部组件后再重试 stop.bat。
		set "EXT_OCC=1"
	)
)
goto :eof
