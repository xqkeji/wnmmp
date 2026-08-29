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
set "COMPOSER_DIR=%HOME_DIR%\bin\composer"

REM Register %COMPOSER_DIR% at the FRONT of the user PATH so this fresh install
REM wins over older wnmmp installs that are still on disk.
REM The old code APPENDED to the end, which let e.g. D:\wnmmp-1.0.17 keep
REM shadowing a freshly installed D:\wnmmp-1.1.3 -- php.bat / composer.bat from
REM the OLD version ran instead of the new one.
REM Everything lives in bin\register-path.bat, which is idempotent, backs the
REM old value up and rolls back on failure.
REM This is NON-ESSENTIAL for the install -- any failure here must never abort
REM the whole installer, so it is a plain best-effort call.
call "%HOME_DIR%\bin\register-path.bat"

:composer_cfg
REM composer.phar / pie.phar 由用户自行下载后放入 bin\composer，脚本不自动下载
REM （GitHub 等通道在国内不稳定）。这里只做「就位检测」+ 配置 + PATH 注册。
set "COMPOSER_PHAR=%COMPOSER_DIR%\composer.phar"
if exist "%COMPOSER_PHAR%" (
	call "%COMPOSER_DIR%\composer.bat" config --global use-parent-dir true >nul 2>&1
	echo [composer] 检测到 composer.phar（请确保已自行放入 bin\composer），已就绪。
) else (
	echo [WARN] 未找到 bin\composer\composer.phar，请自行下载并放入该目录，否则 composer 命令不可用。
)

