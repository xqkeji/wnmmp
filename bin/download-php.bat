@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
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

REM mingw32 wget reads ~/.wgetrc and ~/.wget-hsts from HOME. When run from
REM cmd.exe (double-click) HOME is often unset and that '~' expansion fails
REM with "Invalid argument". Point HOME at our writable tmp dir so wget never
REM hits an invalid path. Inherited by every call'd child script too.
if not defined HOME set "HOME=%TMP_DIR%"
if not defined TMP_DIR set "TMP_DIR=%~dp0tmp"
if not defined DOWNLOAD_DIR set "DOWNLOAD_DIR=%TMP_DIR%\download"
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
REM Active extensions: mongodb, apcu, xdebug (zend), xqkeji.
REM NOTE: zephir_parser is intentionally NOT installed -- xqkeji's prebuilt DLL
REM is self-contained and no longer depends on it.

call :install_pecl_ext mongodb php_mongodb.dll 2.4.0 php-mongodb ext
call :install_pecl_ext apcu php_apcu.dll 5.1.28 php-apcu ext
call :install_pecl_ext xdebug php_xdebug.dll 3.5.3 php-xdebug zend
call :install_xqkeji

call "bin\init-composer.bat"
goto :eof


REM ===================== helper :download_core =====================
:download_core
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -c -O "%TMP_DIR%\download\php.zip" %PHP_DOWNLOAD_URL%
if not "!errorlevel!"=="0" (
	echo.
	set "MSG1=[ERROR] PHP 核心下载失败！安装未完成。"
	echo !MSG1!
	echo [ERROR] URL: %PHP_DOWNLOAD_URL%
	set "MSG1=[ERROR] 请检查网络后重新运行 install.bat（已下载部分支持断点续传）。"
	echo !MSG1!
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
		set "MSG1=[ERROR] PHP 核心解压失败！安装未完成。"
		set "MSG2=[ERROR] 可能是 zip 损坏，已删除损坏包，请重新运行 install.bat 重试。"
		echo !MSG1!
		echo !MSG2!
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
REM Skip only when the DLL is present AND the version php.exe reports for it
REM equals the pin. Existence alone would keep a DLL from an older wnmmp
REM forever, so raising the pin in wnmmp.ini never reached the machine.
REM The mismatch notice spells out "but pin is" rather than using !=: under
REM delayed expansion cmd reads those bangs as variable delimiters and eats them.
if exist "%PHP_EXT_DIR%\%FB_DLL%" call :ext_version %FB_EXT%
if exist "%PHP_EXT_DIR%\%FB_DLL%" if "!EXT_VER!"=="%FB_VER%" (
	echo [php] %FB_EXT% already present, skip
	goto :eof
)
if exist "%PHP_EXT_DIR%\%FB_DLL%" echo [php] %FB_EXT% installed version [!EXT_VER!] but pin is %FB_VER%, reinstalling
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
copy "%FOUND_DLL%" "%PHP_EXT_DIR%" /Y >nul 2>nul

if exist "%PHP_EXT_DIR%\%FB_DLL%" (
	call :enable_ext %FB_EXT% %FB_KIND%
	echo %DATE% %TIME% [php] %FB_EXT% installed via PECL（%FB_VER% / php %PHP_MM%） >> "%TMP_DIR%\install.progress.log"
	goto :eof
)
:pecl_dllmiss
set "MSG1=[ERROR] %FB_EXT% 解压后未找到 %FB_DLL%，该版本未安装。"
echo !MSG1!
echo %DATE% %TIME% [php] %FB_EXT% FAILED (dll missing in zip) >> "%TMP_DIR%\install.errors.log"
goto pecl_disable
:pecl_failed
set "MSG1=[ERROR] %FB_EXT% 下载失败（php %PHP_MM% / ext %FB_VER%）！该版本未安装。"
echo !MSG1!
echo %DATE% %TIME% [php] %FB_EXT% FAILED (PECL download) >> "%TMP_DIR%\install.errors.log"
REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:pecl_disable
call :disable_ext %FB_EXT%
goto :eof


REM ===================== helper :install_xqkeji =====================
REM xqkeji is a custom extension whose prebuilt DLL is PHP-version specific.
REM It comes from a tag SOURCE archive/clone, which carries php_xqkeji.dll,
REM xqkeji.so, LICENSE.md and NOTICES together. Tags are plain versions
REM (v1.2.2): the target PHP minor is declared by the repo's Dockerfile ARG
REM PHP_BRANCH, NOT by a -phpMM tag suffix. The tag is declared in wnmmp.ini
REM (key: xqkeji) and arrives here as CFG_xqkeji via download-ini.bat, so
REM NOTHING probes the network for a version. Three sources are tried in order:
REM gitcode archive -> gitcode git clone -> GitHub archive (see the ladder below
REM for why the archive alone is not enough). The old :xqkeji_detect (gitee tags
REM API) was removed: gitee rate limits anonymous calls, a failed probe used to
REM leave an EMPTY tag which then built a URL with no tag in it and 404'd, and
REM gitee no longer carries the current tags at all.
REM
REM PHP_MM comes from the ACTUALLY installed php.exe (see main flow). A legacy
REM -phpMM tag that disagrees with it is still reported before downloading;
REM a plain tag carries no PHP minor, so there is nothing to compare.
:install_xqkeji
echo [php] ===^> step: xqkeji
if "%CFG_xqkeji%"=="" goto xqkeji_nourl
set "XQ_TAG=%CFG_xqkeji%"
REM phpversion('xqkeji') reports a bare version (1.2.2) while the pin may carry
REM a leading v and a legacy -phpMM suffix, so normalize the pin before comparing.
set "XQ_WANT=%XQ_TAG%"
if /i "%XQ_WANT:~0,1%"=="v" set "XQ_WANT=%XQ_WANT:~1%"
for /f "tokens=1 delims=-" %%v in ("%XQ_WANT%") do set "XQ_WANT=%%v"
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" call :ext_version xqkeji
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" if "!EXT_VER!"=="!XQ_WANT!" (
	echo [php] xqkeji already present, skip
	goto :eof
)
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" echo [php] xqkeji installed version [!EXT_VER!] but pin is !XQ_WANT!, reinstalling
REM Last-resort source only: rungs 1-2 below use the gitcode URLs inline.
set "PHP_XQKEJI_DOWNLOAD_URL=https://github.com/xqkeji/php-xqkeji/archive/refs/tags/%XQ_TAG%.zip"
set "MSG1=[php] xqkeji 标签 = %XQ_TAG% (wnmmp.ini, php %PHP_MM%)"
echo !MSG1!
echo %XQ_TAG%| findstr /i /c:"-php" >nul
if errorlevel 1 goto xqkeji_tag_ok
echo %XQ_TAG%| findstr /i /c:"-php%PHP_MM%" >nul
if not errorlevel 1 goto xqkeji_tag_ok
set "MSG1=[WARN] xqkeji 标签 %XQ_TAG% 与已安装 PHP %PHP_MM% 不匹配"
set "MSG2=[WARN] 请检查 wnmmp.ini 里 xqkeji 与 php 两项是否配套"
echo !MSG1!
echo !MSG2!
REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:xqkeji_tag_ok
REM ---- source ladder: gitcode first, GitHub last. Every rung downloads a ZIP
REM ---- and extracts with the bundled unzip.exe, so nothing depends on tar.exe
REM ---- being present in Windows. gitcode has two channels that behave very
REM ---- differently:
REM ----   1) archive (raw.gitcode.com) is the same URL the site's "download zip"
REM ----      button uses: /archive/refs/heads/<ref>.zip. It is served by a queue
REM ----      that answers scripts with an HTML page (anti-bot SPA, or a redirect
REM ----      to gitcode.com/download-error "queue busy, retry in 30s"). wget can
REM ----      therefore exit 0 and still have written HTML, NOT a package -- only
REM ----      "DLL found after extraction" counts as success.
REM ----   2) git clone (smart HTTP) does not pass that queue/WAF and works on
REM ----      machines where the archive is blocked, yielding identical bytes.
REM ---- No -c on these downloads: resuming is only meaningful for the SAME url
REM ---- and each rung writes its own file; -O truncates, so a leftover body from
REM ---- a previous run can never be appended to.
set "FOUND_DLL="
set "XQ_SRC="
set "XQ_DIR_TMP=%TMP_DIR%\download\php-xqkeji"
echo [php] xqkeji source 1/3: gitcode zip archive
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -O "%TMP_DIR%\download\php-xqkeji-gitcode.zip" "https://raw.gitcode.com/xqkeji/php-xqkeji/archive/refs/heads/%XQ_TAG%.zip"
if exist "%TMP_DIR%\download\php-xqkeji-gitcode.zip" (
	if exist "%XQ_DIR_TMP%" rd /s /q "%XQ_DIR_TMP%" 2>nul
	mkdir "%XQ_DIR_TMP%" 2>nul
	unzip -o "%TMP_DIR%\download\php-xqkeji-gitcode.zip" -d "%XQ_DIR_TMP%" >nul 2>&1
	call :xqkeji_find_dll
	if defined FOUND_DLL set "XQ_SRC=gitcode-archive"
)
if not defined FOUND_DLL (
	echo [php] xqkeji source 2/3: gitcode git clone
	where git >nul 2>&1
	if not errorlevel 1 (
		if exist "%XQ_DIR_TMP%" rd /s /q "%XQ_DIR_TMP%" 2>nul
		git -c advice.detachedHead=false clone --quiet --depth 1 --branch %XQ_TAG% https://gitcode.com/xqkeji/php-xqkeji.git "%XQ_DIR_TMP%"
		call :xqkeji_find_dll
		if defined FOUND_DLL set "XQ_SRC=gitcode-clone"
	) else (
		echo [php] git not found, skip gitcode clone
	)
)
if not defined FOUND_DLL (
	echo [php] xqkeji source 3/3: github archive
	wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config -O "%TMP_DIR%\download\php-xqkeji.zip" "%PHP_XQKEJI_DOWNLOAD_URL%"
	if exist "%TMP_DIR%\download\php-xqkeji.zip" (
		if exist "%XQ_DIR_TMP%" rd /s /q "%XQ_DIR_TMP%" 2>nul
		mkdir "%XQ_DIR_TMP%" 2>nul
		unzip -o "%TMP_DIR%\download\php-xqkeji.zip" -d "%XQ_DIR_TMP%"
		call :xqkeji_find_dll
		if defined FOUND_DLL set "XQ_SRC=github-archive"
	)
)
if not defined FOUND_DLL goto xqkeji_failed
set "MSG1=[php] xqkeji %XQ_TAG% source = !XQ_SRC!"
echo !MSG1!
REM IMPORTANT: the archives nest the DLL one level deep under a versioned folder
REM (gitcode keeps the tag's leading v, GitHub strips it; a clone puts it at the
REM top). `for /r` with a LITERAL filename does NOT recurse into that subfolder,
REM so :xqkeji_find_dll uses a WILDCARD mask which forces full recursion and
REM reliably finds the DLL at any depth.
copy "%FOUND_DLL%" "%PHP_EXT_DIR%" /Y >nul 2>nul
REM Carry php-xqkeji's license files alongside the DLL (dual-license / proprietary).
REM They ship in the same versioned folder as the DLL; copy them best-effort so the
REM binary distribution always includes LICENSE.md + NOTICES (must not be removed).
set "XQ_DIR="
for %%p in ("%FOUND_DLL%") do set "XQ_DIR=%%~dpp"
if exist "%XQ_DIR%LICENSE.md" copy "%XQ_DIR%LICENSE.md" "%PHP_EXT_DIR%" /Y >nul 2>nul
if exist "%XQ_DIR%NOTICES" copy "%XQ_DIR%NOTICES" "%PHP_EXT_DIR%" /Y >nul 2>nul
if exist "%PHP_EXT_DIR%\LICENSE.md" (
	set "MSG1=[php] xqkeji 许可证文件 (LICENSE.md / NOTICES) 已随扩展安装到 php/ext/"
	echo !MSG1!
)
if exist "%PHP_EXT_DIR%\php_xqkeji.dll" (
	call :enable_ext xqkeji ext
	echo %DATE% %TIME% [php] xqkeji installed（%XQ_TAG%） >> "%TMP_DIR%\install.progress.log"
	goto :eof
)
REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:xqkeji_failed
set "MSG1=[ERROR] php_xqkeji 三个源（gitcode 归档 / gitcode 克隆 / GitHub 归档）都未取到 DLL，该版本未安装。"
echo !MSG1!
echo %DATE% %TIME% [php] xqkeji FAILED (all sources) >> "%TMP_DIR%\install.errors.log"
goto xqkeji_disable
:xqkeji_nourl
set "MSG1=[ERROR] php_xqkeji 未配置下载地址，跳过。"
echo !MSG1!
echo %DATE% %TIME% [php] xqkeji SKIPPED (no url) >> "%TMP_DIR%\install.errors.log"
REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:xqkeji_disable
call :disable_ext xqkeji
goto :eof




REM ===================== helper :disable_ext =====================
REM Called when an extension DLL could NOT be installed. Removes its active
REM enable line from etc/php/php.ini so php.exe no longer tries to load a
REM missing module (which otherwise prints "Unable to load dynamic library"
REM warnings at every php invocation). Uses findstr /v (exact-line match) which
REM safely preserves blank lines and existing ";" comments -- it only drops the
REM one active line. Args: %1 = extension short name.
REM Keeps the line when php.exe still reports a version for the extension, so a
REM failed upgrade cannot disable an older DLL that still works.
:disable_ext
set "DE_NAME=%~1"
set "INI=%HOME_DIR%\etc\php\php.ini"
if not exist "%INI%" goto :eof
REM A failed upgrade leaves the OLD DLL in place (it is only overwritten on
REM success), so ask php.exe whether the extension still loads before pulling
REM its enable line: a working older build beats a disabled extension.
call :ext_version %DE_NAME%
if not "!EXT_VER!"=="" (
	set "MSG1=[php] 扩展 %DE_NAME% 旧版本 !EXT_VER! 仍可用，保留启用行（新版本未取到）"
	echo !MSG1!
	echo %DATE% %TIME% [php] %DE_NAME% kept enabled at !EXT_VER! >> "%TMP_DIR%\install.progress.log"
	goto :eof
)
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
	set "MSG1=[php] 已启用扩展 %EN_NAME% (%EN_KIND%)"
	echo !MSG1!
	echo %DATE% %TIME% [php] %EN_NAME% enabled in php.ini >> "%TMP_DIR%\install.progress.log"
) else (
	set "MSG1=[php] %EN_NAME% 启用行已存在，skip"
	echo !MSG1!
)
goto :eof


REM ===================== helper :xqkeji_find_dll =====================
REM Sets FOUND_DLL to the first php_xqkeji.dll anywhere under XQ_DIR_TMP.
REM Shared by all three download rungs, so each of them is judged by the same
REM criterion: a DLL actually on disk. An archive that downloaded fine but is
REM really an anti-bot HTML page simply extracts nothing and leaves FOUND_DLL
REM undefined, which sends the caller to the next rung.
REM ---- keep the lines above this label 100% ASCII (see :xqkeji_tag_ok).
REM ----
REM ----
:xqkeji_find_dll
for /r "%XQ_DIR_TMP%" %%d in (*php_xqkeji.dll) do (
	if not defined FOUND_DLL set "FOUND_DLL=%%d"
)
goto :eof


REM ===================== helper :ext_version =====================
REM Sets EXT_VER to the version php.exe actually reports for extension %1.
REM Empty means "not loaded" (DLL missing, enable line removed by :disable_ext,
REM or php.exe unavailable); the caller then re-installs instead of skipping.
REM display_errors is off and stderr dropped so a PHP startup warning can never
REM become the first line that set /p reads.
REM ---- keep the lines above this label 100% ASCII (see :xqkeji_tag_ok).
REM ----
REM ----
REM ----
:ext_version
set "EXT_VER="
if not exist "%PHP_DIR%\php.exe" goto :eof
"%PHP_DIR%\php.exe" -d display_errors=0 -r "echo phpversion('%~1');" > "%TMP_DIR%\ext_ver.txt" 2>nul
if not exist "%TMP_DIR%\ext_ver.txt" goto :eof
set /p EXT_VER=<"%TMP_DIR%\ext_ver.txt"
goto :eof
