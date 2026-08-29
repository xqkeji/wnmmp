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
REM This shim is what makes `php` work after bin\composer was added to PATH:
REM it forwards to this install's php.exe with this install's php.ini.
REM Without @echo off on line 1 cmd echoes every line below onto the console.
setlocal enabledelayedexpansion
set "ORIGINAL_DIR=%CD%"
cd /d %~dp0
for %%i in ("%~dp0..\..") do set "HOME_DIR=%%~fi"
set "PHP_DIR=%HOME_DIR%\php"
cd /d "!ORIGINAL_DIR!"

"%PHP_DIR%\php.exe" -c "%HOME_DIR%\etc\php\php.ini" %*


