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
echo [init] 正在检查 MongoDB 数据目录是否已初始化 ...
if not exist "%DATA_DIR%\mongodb" (
	mkdir "%DATA_DIR%\mongodb"
)
if exist "%DATA_DIR%\mongodb\*.wt" (
	echo [init] MongoDB 数据目录已存在（%DATA_DIR%\mongodb），之前已初始化过，跳过初始化。
	goto :eof
)
echo [init] 开始初始化 MongoDB（创建管理员账号，约需 10 秒，请稍候）...
start "MongoDB Server" /B "%HOME_DIR%\mongodb\bin\mongod.exe" --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log >nul 2>nul
timeout /t 10 /nobreak >nul
"%HOME_DIR%\mongodb\bin\mongosh.exe" --port 27017 "%CONFIG_DIR%\mongodb\create_admin.js" >nul 2>nul
tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
timeout /t 3 /nobreak >nul
echo [init] MongoDB 初始化完成！
echo [init] 默认账号：root    默认密码：xqkeji.cn   （监听端口 27017）



