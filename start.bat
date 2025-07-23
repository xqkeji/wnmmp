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
setlocal enabledelayedexpansion

REM find and stop service
tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
tasklist | findstr /i php-cgi.exe && taskkill /f /im php-cgi.exe
tasklist | findstr /i nginx.exe && taskkill /f /im nginx.exe

REM set variable
set PHP_FCGI_MAX_REQUESTS=1000
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=%PATH%;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=%HOME_DIR%\tmp
set INSTALL_FILE=%TMP_DIR%\install.lock

REM check and hide running service
if exist "%INSTALL_FILE%" (
	where mongod.exe >nul 2>&1 && RunHiddenConsole.exe /l mongod.exe --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log --auth
	
	where mysqld.exe >nul 2>&1 && RunHiddenConsole.exe /l mysqld.exe --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --general-log-file="%LOGS_DIR%\mysql\general.log" --slow-query-log-file="%LOGS_DIR%\mysql\slow.log"
	
	where php-cgi.exe >nul 2>&1 && RunHiddenConsole.exe /l php-cgi.exe -c %HOME_DIR%\etc\php\php.ini -b 127.0.0.1:9000 -d error_log="%HOME_DIR%\logs\php\error.log"
	
	where nginx.exe >nul 2>&1 && RunHiddenConsole.exe /l nginx.exe -p %HOME_DIR%\ -c %HOME_DIR%\etc\nginx\nginx.conf
	
	set HOME_DIR=
	set PATH=
	exit
	
) else (
    echo "Please run install.bat first!"
	pause
)

