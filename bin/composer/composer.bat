@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Affero General Public License as
REM published by the Free Software Foundation, version 3 only.
REM SPDX-License-Identifier: AGPL-3.0-only
REM
REM This program is distributed in the hope that it will be useful, but
REM WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
REM Affero General Public License for more details.
REM
REM You should have received a copy of the GNU Affero General Public
REM License along with this program. If not, see
REM     https://www.gnu.org/licenses/
setlocal enabledelayedexpansion
set "ORIGINAL_DIR=%CD%"
cd /d %~dp0
for %%i in ("%~dp0..\..") do set "HOME_DIR=%%~fi"
set "PHP_DIR=%HOME_DIR%\php"
cd /d "!ORIGINAL_DIR!"

"%PHP_DIR%\php.exe" -c "%HOME_DIR%\etc\php\php.ini" "%HOME_DIR%\bin\composer\composer.phar" %*

