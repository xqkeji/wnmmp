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
setlocal enabledelayedexpansion
set "ORIGINAL_DIR=%CD%"
cd /d %~dp0
for %%i in ("%~dp0..\..") do set "HOME_DIR=%%~fi"
set "PHP_DIR=%HOME_DIR%\php"
cd /d "!ORIGINAL_DIR!"

REM PIE 是 Symfony/Box 打包的 PHAR，其依赖的 symfony/service-contracts 与
REM psr 扩展冲突：加载 psr 时 PIE 会拒绝启动。
REM 这里生成一份去掉 psr 的临时 ini 专供 PIE 使用，不改动用户主 php.ini，
REM 其他程序仍可正常使用 psr。
REM 前提：php.ini 必须是 CRLF，否则 findstr 认不出行边界（见 .gitattributes）。
set "PHP_INI=%HOME_DIR%\etc\php\php.ini"
set "PIE_INI=%TEMP%\wnmmp-pie-php.ini"
set "PIE_SZ=0"
findstr /v /x /c:"extension=psr" "%PHP_INI%" > "%PIE_INI%" 2>nul
if exist "%PIE_INI%" for %%S in ("%PIE_INI%") do set "PIE_SZ=%%~zS"
if "%PIE_SZ%"=="0" set "PIE_INI=%PHP_INI%"

"%PHP_DIR%\php.exe" -c "%PIE_INI%" "%HOME_DIR%\bin\composer\pie.phar" %*

