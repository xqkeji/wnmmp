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
if not exist "%DATA_DIR%\mongodb" (
	mkdir "%DATA_DIR%\mongodb"
)
if not exist "%DATA_DIR%\mongodb\*.wt" (
	start "MongoDB Server" /B "%HOME_DIR%\mongodb\bin\mongod.exe" --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log
	timeout /t 10 /nobreak >nul
	"%HOME_DIR%\mongodb\bin\mongosh.exe" --port 27017 "%CONFIG_DIR%\mongodb\create_admin.js"
	tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
	timeout /t 3 /nobreak >nul
	echo "mongodb 初始化完成！"
)



