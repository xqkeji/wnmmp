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
set "PHP_DIR=%HOME_DIR%\php"
set "PHP_EXT_DIR=%HOME_DIR%\php\ext"
if not exist "%PHP_DIR%" (
	mkdir "%PHP_DIR%"
	wget.exe -O %TMP_DIR%\download\php.zip %PHP_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php.zip -d %TMP_DIR%\download\php
	xcopy "%TMP_DIR%\download\php\*" "%PHP_DIR%" /E /H /Y /I
	
	REM php_mongodb.dll
	wget.exe -O %TMP_DIR%\download\php-mongodb.zip %PHP_MONGODB_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php-mongodb.zip -d %TMP_DIR%\download\php-mongodb
	copy "%TMP_DIR%\download\php-mongodb\php_mongodb.dll" "%PHP_EXT_DIR%" /Y
	
	REM php_apcu.dll
	wget.exe -O %TMP_DIR%\download\php-apcu.zip %PHP_APCU_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php-apcu.zip -d %TMP_DIR%\download\php-apcu
	copy "%TMP_DIR%\download\php-apcu\php_apcu.dll" "%PHP_EXT_DIR%" /Y
	
	REM php_xdebug.dll
	wget.exe -O %TMP_DIR%\download\php-xdebug.zip %PHP_XDEBUG_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php-xdebug.zip -d %TMP_DIR%\download\php-xdebug
	copy "%TMP_DIR%\download\php-xdebug\php_xdebug.dll" "%PHP_EXT_DIR%" /Y
	
	REM php_psr.dll
	wget.exe -O %TMP_DIR%\download\php-psr.zip %PHP_PSR_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php-psr.zip -d %TMP_DIR%\download\php-psr
	copy "%TMP_DIR%\download\php-psr\php_psr.dll" "%PHP_EXT_DIR%" /Y
	
	REM php_xqkeji.dll
	wget.exe -O %TMP_DIR%\download\php-xqkeji.zip %PHP_XQKEJI_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\php-xqkeji.zip -d %TMP_DIR%\download
	copy "%TMP_DIR%\download\%PHP_XQKEJI_ZIP_DIR%\php_xqkeji.dll" "%PHP_EXT_DIR%" /Y
)

