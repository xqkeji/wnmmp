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
REM =====================================================================
REM install-pie.bat -- install PIE (PHP Installer for Extensions)
REM
REM Called from download-php.bat AFTER the PHP core is present (PIE needs
REM PHP 8.1+ to run, which the just-downloaded NTS PHP satisfies).
REM
REM Strategy to avoid GitHub in China:
REM   1) composer + China packagist mirror (mirrors.aliyun.com/composer)
REM      -> the dist download is proxied by the mirror, not GitHub.
REM   2) fallback: download pie.phar directly from GitHub releases
REM         (may be slow / blocked in CN -- only used when composer fails).
REM
REM On success this script sets PIE_BIN (path to the pie launcher) so the
REM caller can run "PIE_BIN install <pkg>". On ANY failure PIE_BIN is left
REM UNSET, and download-php.bat falls back to direct PECL download for every
REM extension -- so a PIE failure never breaks the install.
REM
REM IMPORTANT: do NOT call "setlocal" here. install.bat enables delayed
REM expansion globally and we need PIE_BIN to propagate back to the caller.
REM =====================================================================

set "PIE_DIR=%HOME_DIR%\bin\pie"

REM already installed?
if exist "%PIE_DIR%\pie.bat" (
	set "PIE_BIN=%PIE_DIR%\pie.bat"
	echo [pie] already installed, skip
	goto :pie_done
)
if not exist "%PIE_DIR%" mkdir "%PIE_DIR%"

REM PIE itself needs php to run; if the core is somehow missing, skip PIE.
if not exist "%HOME_DIR%\php\php.exe" (
	echo [WARN] php.exe 未找到，PIE 不可用，扩展将走 PECL 直下。
	goto :pie_done
)

REM ---- 1) composer + China mirror (avoids GitHub) ----
echo [pie] installing via composer (mirror: mirrors.aliyun.com/composer)...
echo {"require":{"php/pie":"*"}}>"%PIE_DIR%\composer.json"
"%HOME_DIR%\bin\composer\composer.bat" --working-dir="%PIE_DIR%" config repos.packagist composer https://mirrors.aliyun.com/composer/ 2>nul
"%HOME_DIR%\bin\composer\composer.bat" --working-dir="%PIE_DIR%" install --no-interaction --timeout=120 2>&1
if exist "%PIE_DIR%\vendor\bin\pie.bat" (
	set "PIE_BIN=%PIE_DIR%\vendor\bin\pie.bat"
	echo [pie] installed via composer
	goto :pie_done
)

REM ---- 2) GitHub phar fallback (may be slow / blocked in CN) ----
echo [WARN] composer 安装 PIE 失败，回退到 GitHub phar（国内可能较慢/被墙）...
wget.exe --no-hsts --no-config --no-check-certificate -c -O "%PIE_DIR%\pie.phar" https://github.com/php/pie/releases/latest/download/pie.phar
if exist "%PIE_DIR%\pie.phar" (
	echo @php "%%~dp0pie.phar" %%*>"%PIE_DIR%\pie.bat"
	set "PIE_BIN=%PIE_DIR%\pie.bat"
	echo [pie] installed via GitHub phar
	goto :pie_done
)

echo.
echo [ERROR] PIE 安装失败！PHP 扩展将回退为直接 PECL 下载。
echo %DATE% %TIME% [pie] install FAILED >> "%TMP_DIR%\install.errors.log"

:pie_done


