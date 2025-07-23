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

set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"

set PATH=%PATH%;%HOME_DIR%\bin;%HOME_DIR%\mongodb\bin;%HOME_DIR%\mysql\bin;%HOME_DIR%\php;%HOME_DIR%\nginx
set DATA_DIR=%HOME_DIR%\data
set CONFIG_DIR=%HOME_DIR%\etc
set LOGS_DIR=%HOME_DIR%\logs
set TMP_DIR=!HOME_DIR!\tmp
set INSTALL_FILE=%TMP_DIR%\install.lock

set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"

if exist !INSTALL_FILE! (

	if not exist "%NSSM_PATH%" (
		echo "error not found nssm.exe"
		pause
		exit /b 1
	)

	call "bin\service-nginx.bat"
	call "bin\service-mongodb.bat"
	call "bin\service-mysql.bat"
	call "bin\service-php-cgi.bat"

	echo "All wnmmp services install complete."
	echo "These services can be viewed and managed in the Services panel (services.msc)."
	
	set HOME_DIR=
	set PATH=
	pause
	
) else (
    echo "Please run install.bat first!"
	pause
)


