@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
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

REM mingw32 wget reads ~/.wgetrc and ~/.wget-hsts from HOME. When run from
REM cmd.exe (double-click) HOME is often unset and that '~' expansion fails
REM with "Invalid argument". Point HOME at our writable tmp dir so wget never
REM hits an invalid path. Inherited by every call'd child script too.
if not defined HOME set "HOME=%TMP_DIR%"
if not defined TMP_DIR set "TMP_DIR=%~dp0tmp"
if not defined DOWNLOAD_DIR set "DOWNLOAD_DIR=%TMP_DIR%\download"
if not defined GL_DIR set "GL_DIR=%TMP_DIR%\download"
set "PHP_DIR=%HOME_DIR%\php"
set "PHP_EXT_DIR=%HOME_DIR%\php\ext"


REM ---- resume guard: skip core only when finalized with sentinel ----
set "PHP_INSTALLED=0"
if exist "%PHP_DIR%\_installed" set "PHP_INSTALLED=1"
if "%PHP_INSTALLED%"=="1" goto php_core_done
REM incomplete previous run (dir exists but not finalized) -> clean and retry
if exist "%PHP_DIR%" (
	echo [php] incomplete previous install detected, cleaning...
	rd /s /q "%PHP_DIR%" 2>nul
)
mkdir "%PHP_DIR%"
call :download_core
:php_core_done


REM ---- derive installed PHP major.minor (source of truth for PECL builds) ----
REM `php -r "echo phpversion();"` prints exactly "X.Y.Z" on one line (no Zend
REM banner, no multiline). Capture to a temp file and read the FIRST line with
REM set /p (sidesteps every for/f quoting/parsing pitfall), then split X.Y.Z
REM into major.minor. NOTE: a double-quoted string in for/f WITHOUT usebackq is
REM parsed as LITERAL TEXT (not a filename) -- that is what we want here.
"%PHP_DIR%\php.exe" -r "echo phpversion();" > "%TMP_DIR%\php_ver.txt" 2>nul
set /p PHP_FULL=<"%TMP_DIR%\php_ver.txt"
for /f "tokens=1,2 delims=." %%a in ("!PHP_FULL!") do set "PHP_MM=%%a.%%b"
echo [php] installed PHP major.minor = %PHP_MM%


REM ---- 检测 PIE 是否就绪（不下载，phar 由用户自行放入 bin\composer） ----
REM PIE 是独立 PHAR（bin\composer\pie.phar），与 Composer 同处 bin\composer，
REM 因而 `pie` 命令在 bin\composer 加入 PATH 后即可用（无需额外配置环境变量）。
REM 由于 GitHub 等通道国内不稳定，pie.phar / composer.phar 均由用户自行下载放入，
REM 本脚本不自动下载，仅做就位检测。从源码编译已关闭（Windows 走 PECL 预编译
REM DLL via :install_pecl_ext），故 PIE 缺失也不会阻断扩展安装——走 PECL 直下。
call "bin\install-pie.bat"


REM ===========================================================================
REM PHP extensions. Every failure is logged to install.errors.log AND printed
REM as [ERROR] so the user always gets a visible prompt instead of a silent
REM skip. Branching is FLAT (goto-based) on purpose: nested if/else/for blocks
REM in cmd.exe are a classic source of "else was unexpected" parse crashes.
REM ===========================================================================
REM Active extensions: mongodb, apcu, xdebug (zend), psr, xqkeji.
REM NOTE: zephir_parser is intentionally NOT installed -- xqkeji's prebuilt DLL
REM is self-contained and no longer depends on it.

call :install_pecl_ext mongodb php_mongodb.dll 2.4.0 php-mongodb ext
call :install_pecl_ext apcu php_apcu.dll 5.1.28 php-apcu ext
call :install_pecl_ext xdebug php_xdebug.dll 3.5.3 php-xdebug zend
call :install_pecl_ext psr php_psr.dll 1.2.0 php-psr ext
call :install_xqkeji

call "bin\init-composer.bat"
goto :eof


REM ===================== helper :download_core =====================
:download_core
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -c -O "%TMP_DIR%\download\php.zip" %PHP_DOWNLOAD_URL%
if not "!errorlevel!"=="0" (
	echo.
	echo [ERROR] PHP 核心下载失败！安装未完成。
	echo [ERROR] URL: %PHP_DOWNLOAD_URL%
	echo [ERROR] 请检查网络后重新运行 install.bat（已下载部分支持断点续传）。
	echo %DATE% %TIME% [php] CORE download FAILED >> "%TMP_DIR%\install.errors.log"
	pause
	exit
)
unzip -o "%TMP_DIR%\download\php.zip" -d "%TMP_DIR%\download\php"
if not "!errorlevel!"=="0" (
	del "%TMP_DIR%\download\php.zip"
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -O "%TMP_DIR%\download\php.zip" %PHP_DOWNLOAD_URL%
	unzip -o "%TMP_DIR%\download\php.zip" -d "%TMP_DIR%\download\php"
	if not "!errorlevel!"=="0" (
		echo.
		echo [ERROR] PHP 核心解压失败！安装未完成。
		echo [ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。
		echo %DATE% %TIME% [php] CORE extract FAILED >> "%TMP_DIR%\install.errors.log"
		pause
		exit
	)
)
xcopy "%TMP_DIR%\download\php\*" "%PHP_DIR%" /E /H /Y /I
echo done > "%PHP_DIR%\_installed"
echo %DATE% %TIME% [php] core installed (%PHP_DOWNLOAD_URL%) >> "%TMP_DIR%\install.progress.log"
goto :eof


REM ===================== helper :install_pecl_ext =====================
REM Directly download a PECL extension DLL, matched to the ACTUALLY INSTALLED
REM PHP version (PHP_MM). Args: %1=ext name %2=dll name %3=ver %4=zip basename.
REM The version is pinned (verified to ship a php 8.5 vs17/nts/x64 build) so we
REM never depend on scraping the PECL listing page at runtime.
:install_pecl_ext
set "FB_EXT=%~1"
set "FB_DLL=%~2"
set "FB_VER=%~3"
set "FB_ZIP=%~4"
set "FB_KIND=%~5"
if exist "%PHP_EXT_DIR%\%FB_DLL%" (
	echo [php] %FB_EXT% already present, skip
	goto :eof
)
set "FB_URL=https://downloads.php.net/~windows/pecl/releases/%FB_EXT%/%FB_VER%/php_%FB_EXT%-%FB_VER%-%PHP_MM%-nts-vs17-x64.zip"
echo [php] %FB_EXT% PECL 直下 (ext %FB_VER% / php %PHP_MM%)...
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate -c -O "%TMP_DIR%\download\php-%FB_ZIP%.zip" "%FB_URL%"
if not "!errorlevel!"=="0" goto pecl_failed
if not exist "%TMP_DIR%\download\php-%FB_ZIP%.zip" goto pecl_failed
unzip -o "%TMP_DIR%\download\php-%FB_ZIP%.zip" -d "%TMP_DIR%\download\php-%FB_ZIP%"
set "FOUND_DLL="
for /r "%TMP_DIR%\download\php-%FB_ZIP%" %%d in (%FB_DLL%) do (
	if not defined FOUND_DLL set "FOUND_DLL=%%d"
)
if not defined FOUND_DLL goto pecl_dllmiss
copy "%FOUND_DLL%" "%PHP_EXT_DIR%" /Y
if exist "%PHP_EXT_DIR%\%FB_DLL%" (
	call :enable_ext %FB_EXT% %FB_KIND%
	echo %DATE% %TIME% [php] %FB_EXT% installed via PECL (%FB_VER% / php %PHP_MM%) >> "%TMP_DIR%\install.progress.log"
	goto :eof
)
:pecl_dllmiss
echo [ERROR] %FB_EXT% 解压后未找到 %FB_DLL%，该扩展未安装。
echo %DATE% %TIME% [php] %FB_EXT% FAILED (dll missing in zip) >> "%TMP_DIR%\install.errors.log"
goto pecl_disable
:pecl_failed
echo [ERROR] %FB_EXT% 下载失败（php %PHP_MM% / ext %FB_VER%）！该扩展未安装。
echo %DATE% %TIME% [php] %FB_EXT% FAILED (PECL download) >> "%TMP_DIR%\install.errors.log"
:pecl_disable
call :disable_ext %FB_EXT%
goto :eof


REM ===================== helper :install_xqkeji =====================
REM xqkeji is a custom gitee extension whose prebuilt DLL is PHP-version
REM specific. The PHP version we installed was chosen FROM xqkeji's gitee tags
REM (get-latest.bat :xqkeji_targets set XQ_PHP_MM + XQ_TAG). We reuse XQ_TAG
REM directly so the DLL always fits the running build; if that probe failed we
REM fall back to a runtime :xqkeji_detect, then to the pinned URL. Flat goto
REM branching throughout (no nested if/for/else).
:install_xqkeji
echo [php] ===^> step: xqkeji
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" (
	echo [php] xqkeji already present, skip
	goto :eof
)
REM ---- resolve the gitee tag for the PHP we just installed ----
REM Prefer XQ_TAG from get-latest.bat (:xqkeji_targets), which already picked
REM BOTH the PHP_MM we downloaded and the matching xqkeji build. Fall back to
REM a runtime :xqkeji_detect only if that probe failed (gitee unreachable).
if defined XQ_TAG (
	set "PHP_XQKEJI_DOWNLOAD_URL=https://gitee.com/xqkeji/php-xqkeji/repository/archive/%XQ_TAG%.zip"
	echo [php] xqkeji 标签 = %XQ_TAG% ^(gitee 探测得到, php %PHP_MM%^)
) else (
	set "XQ_BESTKEY=0"
	call :xqkeji_detect
	if defined XQ_TAG (
		set "PHP_XQKEJI_DOWNLOAD_URL=https://gitee.com/xqkeji/php-xqkeji/repository/archive/%XQ_TAG%.zip"
		echo [php] xqkeji 自动选标签 = %XQ_TAG% ^(php %PHP_MM%^)
	) else (
		if not defined PHP_XQKEJI_DOWNLOAD_URL goto xqkeji_nourl
		echo [php] xqkeji 使用固定地址 ^(gitee 标签探测失败，回退^)
	)
)
echo [php] downloading xqkeji ^(gitee^)...
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -c -O "%TMP_DIR%\download\php-xqkeji.zip" "%PHP_XQKEJI_DOWNLOAD_URL%"
if not "!errorlevel!"=="0" goto xqkeji_failed
if not exist "%TMP_DIR%\download\php-xqkeji.zip" goto xqkeji_failed
if exist "%TMP_DIR%\download\php-xqkeji" rd /s /q "%TMP_DIR%\download\php-xqkeji" 2>nul
unzip -o "%TMP_DIR%\download\php-xqkeji.zip" -d "%TMP_DIR%\download\php-xqkeji"
REM IMPORTANT: the gitee archive nests the DLL one level deep under a versioned
REM folder (php-xqkeji-<tag>/php_xqkeji.dll). `for /r` with a LITERAL filename
REM does NOT recurse into that subfolder, so we use a WILDCARD mask which
REM forces full recursion and reliably finds the DLL at any depth.
set "FOUND_DLL="
for /r "%TMP_DIR%\download\php-xqkeji" %%d in (*php_xqkeji.dll) do (
	if not defined FOUND_DLL set "FOUND_DLL=%%d"
)
if not defined FOUND_DLL goto xqkeji_dllmiss
copy "%FOUND_DLL%" "%PHP_EXT_DIR%" /Y
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" (
	call :enable_ext xqkeji ext
	echo %DATE% %TIME% [php] xqkeji installed (%XQ_TAG%) >> "%TMP_DIR%\install.progress.log"
	goto :eof
)
:xqkeji_dllmiss
echo [ERROR] php_xqkeji 解压后未找到 php_xqkeji.dll，该扩展未安装。
echo %DATE% %TIME% [php] xqkeji FAILED (dll missing) >> "%TMP_DIR%\install.errors.log"
goto xqkeji_disable
:xqkeji_failed
echo [ERROR] php_xqkeji 下载失败！该扩展未安装。
echo %DATE% %TIME% [php] xqkeji FAILED (download) >> "%TMP_DIR%\install.errors.log"
goto xqkeji_disable
:xqkeji_nourl
echo [ERROR] php_xqkeji 未配置下载地址，跳过。
echo %DATE% %TIME% [php] xqkeji SKIPPED (no url) >> "%TMP_DIR%\install.errors.log"
:xqkeji_disable
call :disable_ext xqkeji
goto :eof


REM ===================== helper :xqkeji_detect =====================
REM Queries the public gitee tags API and keeps the HIGHEST X.Y.Z whose tag
REM ends in -php%PHP_MM% (the PHP version the prebuilt DLL targets). Sets
REM XQ_TAG on success. Needs delayed expansion (enabled by caller). Does NOT
REM call setlocal -- the caller owns the environment. The gitee API may be
REM rate-limited/unreachable; on any failure we simply leave XQ_TAG unset and
REM the caller falls back to its pinned URL.
:xqkeji_detect
set "XQ_TAG="
set "XQ_BESTKEY=0"
set "XQ_TAGS=%GL_DIR%\xqkeji.tags"
if exist "%XQ_TAGS%" del "%XQ_TAGS%" >nul 2>&1
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate --timeout=30 --tries=2 -q -O "%XQ_TAGS%" "https://gitee.com/api/v5/repos/xqkeji/php-xqkeji/tags?per_page=100" 2>nul
if not exist "%XQ_TAGS%" goto :eof
for %%S in ("%XQ_TAGS%") do set "XQ_SIZE=%%~zS"
if "!XQ_SIZE!"=="0" goto :eof
REM gitee returns COMPACT JSON on ONE line, so a literal name search matches the
REM whole line and would otherwise capture the WRONG (first) tag. grep -o emits
REM exactly ONE "name":"..." match per line; we then keep only the tags that
REM target the installed PHP (php%PHP_MM%). If grep is unavailable the .lines
REM file stays empty and we fall back to the pinned URL (v1.1.1-php8.5).
grep -o "\"name\":\"[^\"]*\"" "%XQ_TAGS%" 2>nul | findstr /c:"php%PHP_MM%" > "%GL_DIR%\xqkeji.lines" 2>nul
if not exist "%GL_DIR%\xqkeji.lines" goto :eof
for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\xqkeji.lines") do (
	set "LN=%%l"
	set "LN=!LN:*":"=!"
	set "TAG=!LN:"=!"
	set "VER=!TAG:*v=!"
	set "VER=!VER:-php%PHP_MM%=!"
	for /f "tokens=1,2,3 delims=." %%a in ("!VER!") do (
		set "VX=%%a" & set "VY=%%b" & set "VZ=%%c"
	)
	set /a "VKEY=!VX!*1000000+!VY!*10000+!VZ!*100" 2>nul
	if !VKEY! gtr !XQ_BESTKEY! (
		set "XQ_BESTKEY=!VKEY!"
		set "XQ_TAG=!TAG!"
	)
)
goto :eof


REM ===================== helper :disable_ext =====================
REM Called when an extension DLL could NOT be installed. Removes its active
REM enable line from etc/php/php.ini so php.exe no longer tries to load a
REM missing module (which otherwise prints "Unable to load dynamic library"
REM warnings at every php invocation). Uses findstr /v (exact-line match) which
REM safely preserves blank lines and existing ";" comments -- it only drops the
REM one active line. Args: %1 = extension short name.
:disable_ext
set "DE_NAME=%~1"
set "INI=%HOME_DIR%\etc\php\php.ini"
if not exist "%INI%" goto :eof
set "TMPINI=%TMP_DIR%\_phpini.tmp"
findstr /v /x /c:"extension=%DE_NAME%" "%INI%" > "%TMPINI%"
findstr /v /x /c:"zend_extension=%DE_NAME%" "%TMPINI%" > "%INI%"
if exist "%TMPINI%" del "%TMPINI%" >nul
echo [php] 已移除扩展 %DE_NAME% 的启用行（DLL 未安装，避免 php 启动告警）
echo %DATE% %TIME% [php] %DE_NAME% removed from php.ini (dll missing) >> "%TMP_DIR%\install.progress.log"
goto :eof


REM ===================== helper :enable_ext =====================
REM Called AFTER an extension DLL has been successfully placed in php/ext.
REM (Re-)adds its active enable line to etc/php/php.ini so php.exe actually
REM loads it. Idempotent: if the line already exists it is left untouched.
REM Args: %1 = extension short name   %2 = "ext" (extension=) or "zend" (zend_extension=)
:enable_ext
set "EN_NAME=%~1"
set "EN_KIND=%~2"
set "INI=%HOME_DIR%\etc\php\php.ini"
if not exist "%INI%" goto :eof
if "%EN_KIND%"=="zend" (
	set "EN_LINE=zend_extension=%EN_NAME%"
) else (
	set "EN_LINE=extension=%EN_NAME%"
)
findstr /x /c:"%EN_LINE%" "%INI%" >nul 2>&1
if errorlevel 1 (
	echo %EN_LINE%>>"%INI%"
	echo [php] 已启用扩展 %EN_NAME% ^(%EN_KIND%^)
	echo %DATE% %TIME% [php] %EN_NAME% enabled in php.ini >> "%TMP_DIR%\install.progress.log"
) else (
	echo [php] %EN_NAME% 启用行已存在，skip
)
goto :eof
