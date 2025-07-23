:: Copyright (c) xqkeji.cn. All rights reserved.
:: Author: Zhang Wenhao
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::     http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
@echo off
if not exist "%DATA_DIR%\mongodb" (
	mkdir "%DATA_DIR%\mongodb"
)
if not exist "%DATA_DIR%\mongodb\*.wt" (
	start "MongoDB Server" /B "%HOME_DIR%\mongodb\bin\mongod.exe" --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log
	timeout /t 10 /nobreak >nul
	"%HOME_DIR%\mongodb\bin\mongosh.exe" --port 27017 "%CONFIG_DIR%\mongodb\create_admin.js"
	tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
	timeout /t 3 /nobreak >nul
	echo "mongodb init complete!"
)

