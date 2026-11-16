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
set "MSG1=[init] 正在检查 MongoDB 数据目录是否已初始化 ..."
echo !MSG1!
if not exist "%DATA_DIR%\mongodb" (
	mkdir "%DATA_DIR%\mongodb"
)
if exist "%DATA_DIR%\mongodb\*.wt" (
	set "MSG1=[init] MongoDB 数据目录已存在（%DATA_DIR%\mongodb），之前已初始化过，跳过初始化。"
	echo !MSG1!
	goto :eof
)
set "MSG1=[init] 开始初始化 MongoDB（创建管理员账号，约需 10 秒，请稍候）..."
echo !MSG1!
start "MongoDB Server" /B "%HOME_DIR%\mongodb\bin\mongod.exe" --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log >nul 2>nul
timeout /t 10 /nobreak >nul
"%HOME_DIR%\mongodb\bin\mongosh.exe" --port 27017 "%CONFIG_DIR%\mongodb\create_admin.js" >nul 2>nul
tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
timeout /t 3 /nobreak >nul
set "MSG1=[init] MongoDB 初始化完成！"
set "MSG2=[init] 默认账号：root    默认密码：xqkeji.cn   （监听端口 27017）"
echo !MSG1!
echo !MSG2!



