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
cd /d %~dp0
REM find and stop service
tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
tasklist | findstr /i php-cgi.exe && taskkill /f /im php-cgi.exe
tasklist | findstr /i nginx.exe && taskkill /f /im nginx.exe

REM set variable
set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"
set PATH=%PATH%;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=%HOME_DIR%\tmp
set DOWNLOAD_DIR=%TMP_DIR%\download

call "bin\install-vc-redist.bat"
call "bin\download.bat"
REM mongodb init
call "bin\init-mongodb.bat"
REM mysql init
call "bin\init-mysql.bat"
copy nul %TMP_DIR%\install.lock > nul
echo "install complete!"
REM clear variable
set HOME_DIR=
set PATH=

pause