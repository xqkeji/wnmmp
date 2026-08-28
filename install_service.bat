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

REM ===================== 管理员权限检查 =====================
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo.
	echo "[警告] 安装/注册 Windows 服务需要管理员权限！"
	echo "请右键单击 install_service.bat，选择以管理员身份运行。"
	echo.
	echo 按任意键关闭本窗口...
	pause >nul
	exit /b 1
)

set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=C:\Windows\System32;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx;%PATH%
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=!HOME_DIR!\tmp
set INSTALL_FILE=%TMP_DIR%\install.lock
REM skipped-install record (each line: nginx / mysql / mongodb / php-cgi)
set "SKIP_FILE=%TMP_DIR%\skipped.lst"

REM ---- 预检：确认本脚本所在目录是真正完成安装的目录 ----
REM 常见误操作：在源码目录（尚未下载组件）里直接运行本脚本，会把服务注册到
REM 不存在的路径，表现为"安装成功但启动失败：Unexpected status SERVICE_STOPPED"。
REM 这里统计缺失的组件数，只有四个全缺才判定为目录不对（避免误伤被跳过的组件）。
set "PC_MISS=0"
if not exist "%HOME_DIR%\nginx\nginx.exe" set /a "PC_MISS+=1"
if not exist "%HOME_DIR%\mongodb\bin\mongod.exe" set /a "PC_MISS+=1"
if not exist "%HOME_DIR%\mysql\bin\mysqld.exe" set /a "PC_MISS+=1"
if not exist "%HOME_DIR%\php\php-cgi.exe" set /a "PC_MISS+=1"
if !PC_MISS! equ 4 (
	echo.
	echo **************************************************************
	echo * [错误] 当前目录不是有效的 wnmmp 安装目录！
	echo * 四个组件程序 nginx / mongod / mysqld / php-cgi 均未找到，
	echo * 说明组件尚未下载，或你运行的是源码目录而不是安装目录。
	echo * 当前目录：%HOME_DIR%
	echo * 请先在目标目录运行 install.bat 完成安装，或切换到已安装的目录
	echo * 后，再右键以管理员身份运行本脚本。
	echo **************************************************************
	echo.
	pause
	exit /b 1
)

set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"

if exist !INSTALL_FILE! (

	if not exist "%NSSM_PATH%" (
		echo "未找到 nssm.exe"
		echo 按任意键关闭本窗口...
		pause >nul
		exit /b 1
	)

	REM ---- 汇总将要注册的组件（依据 skipped.lst）----
	echo ==============================================================
	echo  将要安装/注册以下 WNMMP 服务（已记录在跳过清单中的组件不会被处理）：
	for %%K in (nginx mongodb mysql php-cgi) do (
		findstr /x /i /c:"%%K" "%SKIP_FILE%" >nul 2>&1
		if errorlevel 1 (
			echo   - %%K  √ 将安装
		) else (
			echo   - %%K  × 跳过（已在 tmp\skipped.lst）
		)
	)
	echo ==============================================================

	REM ---- nginx ----
	findstr /x /i /c:"nginx" "%SKIP_FILE%" >nul 2>&1
	if not errorlevel 1 (
		echo [skip] nginx：已在跳过清单，不注册服务
	) else (
		call "bin\service-nginx.bat"
	)

	REM ---- mongodb ----
	findstr /x /i /c:"mongodb" "%SKIP_FILE%" >nul 2>&1
	if not errorlevel 1 (
		echo [skip] mongodb：已在跳过清单，不注册服务
	) else (
		call "bin\service-mongodb.bat"
	)

	REM ---- mysql ----
	findstr /x /i /c:"mysql" "%SKIP_FILE%" >nul 2>&1
	if not errorlevel 1 (
		echo [skip] mysql：已在跳过清单，不注册服务
	) else (
		call "bin\service-mysql.bat"
	)

	REM ---- php-cgi ----
	findstr /x /i /c:"php-cgi" "%SKIP_FILE%" >nul 2>&1
	if not errorlevel 1 (
		echo [skip] php-cgi：已在跳过清单，不注册服务
	) else (
		call "bin\service-php-cgi.bat"
	)

	echo "所有 wnmmp 服务已安装完成。"
	echo "可在 Windows 服务面板（services.msc）中查看和管理这些服务。"

	set HOME_DIR=
	set PATH=
	echo 按任意键关闭本窗口...
	pause >nul

) else (
    echo "请先运行 install.bat！"
	echo 按任意键关闭本窗口...
	pause >nul
)


