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
set "MSG1=[init] 正在检查 MySQL 数据目录是否已初始化 ..."
echo !MSG1!
if not exist "%DATA_DIR%\mysql" (
	mkdir "%DATA_DIR%\mysql"
)
if exist "%DATA_DIR%\mysql\mysql" (
	set "MSG1=[init] MySQL 数据目录已存在（%DATA_DIR%\mysql），之前已初始化过，跳过初始化。"
	echo !MSG1!
	goto :eof
)
set "MSG1=[init] 开始初始化 MySQL 数据库（首次启动约需 10 秒，请稍候）..."
echo !MSG1!
"%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --initialize-insecure >nul 2>nul
start "MySQL Server" /B "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" >nul 2>nul
timeout /t 10 /nobreak >nul
"%HOME_DIR%\mysql\bin\mysql.exe" -u root --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY 'xqkeji.cn'; FLUSH PRIVILEGES;" >nul 2>nul
tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
set "MSG1=[init] MySQL 初始化完成！"
set "MSG2=[init] 默认账号：root    默认密码：xqkeji.cn   （监听端口 3306）"
echo !MSG1!
echo !MSG2!


