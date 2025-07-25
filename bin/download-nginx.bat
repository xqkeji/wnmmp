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
set "NGINX_DIR=%HOME_DIR%\nginx"

if not exist "%NGINX_DIR%" (
	mkdir "%NGINX_DIR%"
	wget.exe -O %TMP_DIR%\download\nginx.zip %NGINX_DOWNLOAD_URL%
	if !errorlevel! neq 0 (
		echo "NGINX download failed; installation is not complete."
		rd "%NGINX_DIR%" 2>nul
		pause
		exit
	)
	unzip -o %TMP_DIR%\download\nginx.zip -d %TMP_DIR%\download
	xcopy "%TMP_DIR%\download\%NGINX_ZIP_DIR%\*" "%NGINX_DIR%" /E /H /Y /I
)

