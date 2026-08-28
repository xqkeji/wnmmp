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
REM get-latest.bat  --  pure-batch latest-version resolver for wnmmp
REM
REM Called from download-ini.bat. Uses wget.exe (no PowerShell).
REM
REM Robustness notes (2026-08-27, validated against live vendor pages):
REM   * Every wget call uses --timeout=30 --tries=2 and a browser UA, so a
REM     slow/blocked host can NEVER hang the installer (the CTRL+C trap).
REM   * We use findstr in LITERAL mode (/c:"substring"), NEVER regex, and we
REM     NEVER pipe findstr through for/f (OEM-437 vs 65001 codepage bug).
REM   * findstr literals NEVER start with '-' (findstr mis-parses a leading
REM     dash). The PHP anchor is "nts-Win32-vs17-x64.zip", not "-nts-...".
REM   * We download to a FILE, then read that file with for/f (consistent
REM     codepage). All matched content is pure ASCII.
REM   * Each component prints its page size + whether the anchor was found,
REM     so a real-machine failure is self-diagnosing:
REM        page=0B  -> the HTML page could not be downloaded (network/proxy)
REM        ok=1 but no version -> the vendor page structure changed
REM   * On any failure the variable is left UNSET, so the pinned default in
REM     download-ini.bat is used.
REM   * Requires delayed expansion from the caller (setlocal
REM     enabledelayedexpansion). Must NOT call setlocal itself, or exported
REM     variables are lost on return.
REM =====================================================================

set "GL_DIR=%TMP_DIR%\download"
if not exist "%GL_DIR%" mkdir "%GL_DIR%"


REM ===================== helper :fetch =====================
REM %1 = output file, %2 = URL. Sets DL_OK (0/1) and DL_SIZE.
:fetch
set "DL_FILE=%1"
set "DL_URL=%2"
set "DL_OK=0"
set "DL_SIZE=0"
if exist "%DL_FILE%" del "%DL_FILE%" >nul 2>&1
REM --no-config stops wget from reading any wgetrc/HSTS file (a common source
REM of "Invalid argument" under cmd.exe where HOME is unset). The browser UA
REM is dropped too: these are official mirrors that serve wget's default UA.
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate --timeout=30 --tries=2 -q -O "%DL_FILE%" "%DL_URL%" 2>nul
if exist "%DL_FILE%" (
  for %%S in ("%DL_FILE%") do set "DL_SIZE=%%~zS"
  if !DL_SIZE! gtr 0 set "DL_OK=1"
)
goto :eof


REM ============================ NGINX ============================
REM Download links look like: href="/download/nginx-1.31.4.zip"
REM Anchor literal = "/download/nginx-" (relative href, unique on page).
set "NGINX_VERSION="
call :fetch "%GL_DIR%\nginx.html" "https://nginx.org/en/download.html"
echo [get-latest] nginx  page=!DL_SIZE!B ok=!DL_OK!
if "!DL_OK!"=="1" (
  findstr /c:"/download/nginx-" "%GL_DIR%\nginx.html" > "%GL_DIR%\nginx.lines" 2>nul
  if exist "%GL_DIR%\nginx.lines" (
    for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\nginx.lines") do (
      if not defined NGINX_VERSION (
        set "LN=%%l"
        set "LN=!LN:download/nginx-=!"
        for /f "tokens=1,2,3 delims=.-" %%a in ("!LN!") do (
          for /f "delims=-" %%z in ("%%c") do set "NGINX_VERSION=%%a.%%b.%%z"
        )
      )
    )
  )
)
if defined NGINX_VERSION (
  set "NGINX_DOWNLOAD_URL=https://nginx.org/download/nginx-%NGINX_VERSION%.zip"
  set "NGINX_ZIP_DIR=nginx-%NGINX_VERSION%"
  echo [get-latest] nginx = %NGINX_VERSION%
) else (
  echo [get-latest] nginx detection failed, keep pinned default
)


REM ============================ MYSQL ============================
REM Download link: href="/downloads/gpg/?file=mysql-26.7.0-winx64.msi&p=23"
REM Anchor literal = "file=mysql-" (the gpg redirect carries the filename).
set "MYSQL_VERSION="
call :fetch "%GL_DIR%\mysql.html" "https://dev.mysql.com/downloads/mysql/"
echo [get-latest] mysql  page=!DL_SIZE!B ok=!DL_OK!
if "!DL_OK!"=="1" (
  findstr /c:"file=mysql-" "%GL_DIR%\mysql.html" > "%GL_DIR%\mysql.lines" 2>nul
  if exist "%GL_DIR%\mysql.lines" (
    for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\mysql.lines") do (
      if not defined MYSQL_VERSION (
        set "LN=%%l"
        set "LN=!LN:file=mysql-=!"
        for /f "tokens=1,2,3 delims=.-" %%a in ("!LN!") do (
          for /f "delims=-" %%z in ("%%c") do set "MYSQL_VERSION=%%a.%%b.%%z"
        )
      )
    )
  )
)
if defined MYSQL_VERSION (
  for /f "tokens=1,2 delims=." %%x in ("%MYSQL_VERSION%") do set "MYSQL_MM=%%x.%%y"
  set "MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/MySQL-%MYSQL_MM%/mysql-%MYSQL_VERSION%-winx64.zip"
  set "MYSQL_ZIP_DIR=mysql-%MYSQL_VERSION%-winx64"
  echo [get-latest] mysql = %MYSQL_VERSION%
) else (
  echo [get-latest] mysql detection failed, keep pinned default
)


REM ============================= PHP =============================
REM releases.json (pretty-printed, one entry per line) contains entries
REM like: "path": "php-8.5.10-nts-Win32-vs17-x64.zip"
REM Anchor literal = "nts-Win32-vs17-x64.zip" (NO leading dash -- findstr
REM mis-parses a leading '-'). We collect ALL versions into php.vers and
REM let :highest pick the maximum.
REM PHP version is DRIVEN by xqkeji: :xqkeji_targets (below) probes gitee and
REM sets XQ_PHP_MM = the latest PHP major.minor xqkeji supports, plus XQ_TAG.
REM When set, we keep only that major.minor below (instead of absolute latest).
call :xqkeji_targets
set "PHP_VERSION="
call :fetch "%GL_DIR%\php.json" "https://windows.php.net/downloads/releases/releases.json"
echo [get-latest] php    page=!DL_SIZE!B ok=!DL_OK!
if "!DL_OK!"=="1" (
  findstr /c:"nts-Win32-vs17-x64.zip" "%GL_DIR%\php.json" > "%GL_DIR%\php.lines" 2>nul
  if exist "%GL_DIR%\php.lines" (
    if exist "%GL_DIR%\php.vers" del "%GL_DIR%\php.vers"
    for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\php.lines") do (
      set "LN=%%l"
      set "LN=!LN:-nts-Win32-vs17-x64.zip=!"
      REM LN is now like:  "path": "php-8.4.25",   (or "php-debug-pack-8.4.25",)
      REM The X.Y.Z version is ALWAYS the LAST '-' segment. Take it with a
      REM last-wins loop (each iteration overwrites VER), so php-debug-pack
      REM lines yield the same 8.4.25 as the real php-8.4.25 line.
      for /f "delims=-" %%v in ("!LN!") do set "VER=%%v"
      for /f "delims=," %%q in ("!VER!") do set "VER=%%q"
      set "VER=!VER:~0,-1!"
      >>"%GL_DIR%\php.vers" echo !VER!
    )
    REM Keep ONLY the xqkeji-supported major.minor (no-op when XQ_PHP_MM empty).
    if exist "%GL_DIR%\php.vers.xq" del "%GL_DIR%\php.vers.xq"
    if defined XQ_PHP_MM (
      for /f "usebackq" %%v in ("%GL_DIR%\php.vers") do (
        for /f "tokens=1,2 delims=." %%a in ("%%v") do (
          if "%%a.%%b"=="!XQ_PHP_MM!" (>>"%GL_DIR%\php.vers.xq" echo %%v)
        )
      )
    )
    if defined XQ_PHP_MM (
      if exist "%GL_DIR%\php.vers.xq" call :highest "%GL_DIR%\php.vers.xq" PHP_VERSION
    ) else (
      if exist "%GL_DIR%\php.vers" call :highest "%GL_DIR%\php.vers" PHP_VERSION
    )
  )
)
if defined PHP_VERSION (
  set "PHP_DOWNLOAD_URL=https://windows.php.net/downloads/releases/php-%PHP_VERSION%-nts-Win32-vs17-x64.zip"
  if defined XQ_PHP_MM (
    set "PHP_MM=!XQ_PHP_MM!"
    echo [get-latest] php = %PHP_VERSION% (xqkeji php !XQ_PHP_MM!, nts/vs17/x64)
    echo [get-latest] xqkeji 标签 = !XQ_TAG!
  ) else (
    for /f "usebackq tokens=1,2 delims=." %%x in ('%PHP_VERSION%') do set "PHP_MM=%%x.%%y"
    echo [get-latest] php = %PHP_VERSION% (nts / vs17 / x64)
  )
) else (
  echo [get-latest] php detection failed, keep pinned default
)


REM =========================== MONGODB ===========================
REM Download URL: https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.3.8.zip
REM The version string is embedded in window.__serverData (inline JSON).
REM Anchor literal = "mongodb-windows-x86_64-".
set "MONGO_VERSION="
call :fetch "%GL_DIR%\mongo.html" "https://www.mongodb.com/try/download/community"
echo [get-latest] mongo  page=!DL_SIZE!B ok=!DL_OK!
if "!DL_OK!"=="1" (
  findstr /c:"mongodb-windows-x86_64-" "%GL_DIR%\mongo.html" > "%GL_DIR%\mongo.lines" 2>nul
  if exist "%GL_DIR%\mongo.lines" (
    for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\mongo.lines") do (
      if not defined MONGO_VERSION (
        set "LN=%%l"
        set "LN=!LN:mongodb-windows-x86_64-=!"
        for /f "tokens=1,2,3 delims=.-" %%a in ("!LN!") do (
          for /f "delims=-" %%z in ("%%c") do set "MONGO_VERSION=%%a.%%b.%%z"
        )
      )
    )
  )
)
if defined MONGO_VERSION (
  set "MONGODB_DOWNLOAD_URL=https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-%MONGO_VERSION%.zip"
  set "MONGODB_ZIP_DIR=mongodb-win32-x86_64-windows-%MONGO_VERSION%"
  echo [get-latest] mongodb = %MONGO_VERSION%
) else (
  echo [get-latest] mongodb detection failed, keep pinned default
)


REM =========================== MONGOSSH ==========================
REM Download URL: https://downloads.mongodb.com/compass/mongosh-2.10.0-win32-x64.zip
REM Version string embedded in window.__serverData (inline JSON).
REM Anchor literal = "mongosh-".
set "MONGO_SH_VERSION="
call :fetch "%GL_DIR%\mongosh.html" "https://www.mongodb.com/try/download/shell"
echo [get-latest] mongosh page=!DL_SIZE!B ok=!DL_OK!
if "!DL_OK!"=="1" (
  findstr /c:"mongosh-" "%GL_DIR%\mongosh.html" > "%GL_DIR%\mongosh.lines" 2>nul
  if exist "%GL_DIR%\mongosh.lines" (
    for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\mongosh.lines") do (
      if not defined MONGO_SH_VERSION (
        set "LN=%%l"
        set "LN=!LN:mongosh-=!"
        for /f "tokens=1,2,3 delims=.-" %%a in ("!LN!") do (
          for /f "delims=-" %%z in ("%%c") do set "MONGO_SH_VERSION=%%a.%%b.%%z"
        )
      )
    )
  )
)
if defined MONGO_SH_VERSION (
  set "MONGOSH_DOWNLOAD_URL=https://downloads.mongodb.com/compass/mongosh-%MONGO_SH_VERSION%-win32-x64.zip"
  set "MONGOSH_ZIP_DIR=mongosh-%MONGO_SH_VERSION%-win32-x64"
  echo [get-latest] mongosh = %MONGO_SH_VERSION%
) else (
  echo [get-latest] mongosh detection failed, keep pinned default
)


REM ===================== PHP PECL EXTENSIONS =====================
REM NOTE: PECL extension download is resolved at RUNTIME inside
REM bin/download-php.bat. It reads the actually-installed php.exe version
REM and auto-matches the latest vs17/nts/x64 build, so PECL stays in lock-
REM step with the real PHP build instead of the pre-detected one. The block
REM below is intentionally removed to avoid redundant network probes and to
REM keep a single source of truth for the extension -> PHP version mapping.


goto :eof


REM ====================== helper :highest =======================
REM Reads a file with one X.Y.Z version per line, returns the maximum
REM (numeric comparison, not lexical) into the variable named by %2.
REM Caller MUST have delayed expansion enabled.
:highest
set "best="
set "bestkey=0"
for /f "usebackq tokens=1,2,3 delims=." %%a in ("%1") do (
  set "X=%%a"
  if "%%b"=="" (set "Y=0") else (set "Y=%%b")
  if "%%c"=="" (set "Z=0") else (set "Z=%%c")
  set /a "key=%%a*1000000+%%b*10000+%%c*100"
  if !key! gtr !bestkey! (
    set "best=%%a.%%b.%%c"
    set "bestkey=!key!"
  )
)
set "%2=%best%"
goto :eof

REM ===================== helper :xqkeji_targets =====================
REM Drives the PHP version selection. Probes gitee php-xqkeji tags and:
REM   * XQ_PHP_MM  -- the HIGHEST PHP major.minor xqkeji ships a prebuilt DLL
REM                   for (e.g. 8.5). This becomes the PHP we download.
REM   * XQ_TAG    -- the HIGHEST xqkeji X.Y.Z built for that PHP_MM (the
REM                   exact gitee tag we download). download-php.bat reuses it.
REM Needs delayed expansion (caller enabled it). On any failure both vars stay
REM UNSET and the caller keeps its pinned PHP default -- never a hard error.
:xqkeji_targets
set "XQ_TAG="
set "XQ_PHP_MM="
set "XQ_BESTKEY=0"
set "XQ_MMKEY=0"
set "XQ_TAGS=%GL_DIR%\xqkeji.tags"
if exist "%XQ_TAGS%" del "%XQ_TAGS%" >nul 2>&1
wget.exe --no-hsts --hsts-file="%TMP_DIR%\.wget-hsts" --no-config --no-check-certificate --timeout=30 --tries=2 -q -O "%XQ_TAGS%" "https://gitee.com/api/v5/repos/xqkeji/php-xqkeji/tags?per_page=100" 2>nul
if not exist "%XQ_TAGS%" goto :eof
for %%S in ("%XQ_TAGS%") do set "XQSZ=%%~zS"
if "!XQSZ!"=="0" goto :eof
REM gitee returns compact JSON on one line; grep -o emits exactly ONE
REM "name":"..." per line so we can loop tags individually.
grep -o "\"name\":\"[^\"]*\"" "%XQ_TAGS%" 2>nul > "%GL_DIR%\xqkeji.all"
if not exist "%GL_DIR%\xqkeji.all" goto :eof
REM Pass 1: highest php<MM> among all tags = the PHP we will install.
for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\xqkeji.all") do (
  set "LN=%%l"
  REM each line is "name":"<tag>"; take token2 after ':' and strip quotes
  for /f "tokens=2 delims=:" %%t in ("!LN!") do set "TAG=%%~t"
  set "MM=!TAG:*-php=!"
  if not "!MM!"=="!TAG!" (
    for /f "tokens=1,2 delims=." %%a in ("!MM!") do (
      if not "%%b"=="" (
        set /a "K=%%a*1000+%%b" 2>nul
        if !K! gtr !XQ_MMKEY! (
          set "XQ_MMKEY=!K!"
          set "XQ_PHP_MM=%%a.%%b"
        )
      )
    )
  )
)
if not defined XQ_PHP_MM goto :eof
REM Pass 2: among tags for that PHP_MM, highest xqkeji X.Y.Z -> XQ_TAG.
for /f "usebackq eol= delims=" %%l in ("%GL_DIR%\xqkeji.all") do (
  set "LN=%%l"
  REM each line is "name":"<tag>"; take token2 after ':' and strip quotes
  for /f "tokens=2 delims=:" %%t in ("!LN!") do set "TAG=%%~t"
  set "MM=!TAG:*-php=!"
  if "!MM!"=="!XQ_PHP_MM!" (
    set "VER=!TAG:*v=!"
    set "VER=!VER:-php%XQ_PHP_MM%=!"
    for /f "tokens=1,2,3 delims=." %%a in ("!VER!") do (
      if not "%%c"=="" (
        set "VX=%%a" & set "VY=%%b" & set "VZ=%%c"
        set /a "VKEY=!VX!*1000000+!VY!*10000+!VZ!*100" 2>nul
        if !VKEY! gtr !XQ_BESTKEY! (
          set "XQ_BESTKEY=!VKEY!"
          set "XQ_TAG=!TAG!"
        )
      )
    )
  )
)
goto :eof

