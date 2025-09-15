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
set "ORIGINAL_DIR=%CD%"
cd /d %~dp0
for %%i in ("%~dp0..\..") do set "HOME_DIR=%%~fi"
set "PHP_DIR=%HOME_DIR%\php"
cd /d "!ORIGINAL_DIR!"

"%PHP_DIR%\php.exe" -c "%HOME_DIR%\etc\php\php.ini" "%HOME_DIR%\bin\composer\composer.phar" %*
