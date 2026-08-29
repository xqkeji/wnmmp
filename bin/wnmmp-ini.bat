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

REM ===========================================================================
REM bin/wnmmp-ini.bat -- declarative version loader.
REM
REM Reads wnmmp.ini from the wnmmp root and exports one variable per key,
REM prefixed with CFG_ (so "mysql=26.7.0" becomes CFG_mysql=26.7.0).
REM bin/download-ini.bat then derives every download URL and zip folder name
REM from those values. No network access happens anywhere in this path.
REM
REM NO setlocal on purpose: the caller MUST see the exported CFG_* variables.
REM ASCII-only on purpose: this file is CALLed, and cmd tokenises non-ASCII
REM bytes inside a called script unreliably (they can be mis-split and then
REM executed as commands -- the classic "is not recognized" phantom error).
REM
REM Parsing notes:
REM   * "eol=;" drops ';' comment lines; a leading '#' is filtered in :ini_set.
REM   * delims are BOTH '=' and SPACE, so "key = value" and "key=value" both
REM     parse, and stray spaces never end up inside a key or a value.
REM   * tokens=1,2 (NOT 1,*): a second '=' would truncate the value, which is
REM     exactly why wnmmp.ini forbids '=' inside values.
REM   * A key with an EMPTY value is skipped rather than exported as an empty
REM     variable. "if defined" cannot distinguish an empty var from a set one,
REM     and that ambiguity is what once let a failed probe masquerade as a
REM     valid version and build a broken download URL.
REM ===========================================================================

REM Same %~dp0 caveat as in download-ini.bat: if this script is ever reached by
REM a bare name, %0 has no path and %~dp0 degrades to the current directory, so
REM "%~dp0.." would resolve to the PARENT of the wnmmp root. HOME_DIR is
REM normally already exported by install.bat; %CD% is the safe fallback because
REM install.bat does `cd /d %~dp0` (CWD = wnmmp root).
if not defined HOME_DIR set "HOME_DIR=%CD%"
set "WNMMP_INI=%HOME_DIR%\wnmmp.ini"
if not exist "%WNMMP_INI%" if exist "%CD%\wnmmp.ini" set "WNMMP_INI=%CD%\wnmmp.ini"

if not exist "%WNMMP_INI%" goto ini_missing

for /f "usebackq eol=; tokens=1,2 delims== " %%A in ("%WNMMP_INI%") do (
	call :ini_set "%%A" "%%B"
)

echo [ini] versions: nginx=%CFG_nginx% mysql=%CFG_mysql% mongodb=%CFG_mongodb% mongosh=%CFG_mongosh% php=%CFG_php% xqkeji=%CFG_xqkeji%
goto :eof

:ini_set
set "_K=%~1"
if not defined _K goto :eof
if "%_K:~0,1%"=="#" goto :eof
if "%~2"=="" goto :eof
set "CFG_%_K%=%~2"
goto :eof

:ini_missing
echo.
echo [ERROR] version manifest not found: %WNMMP_INI%
echo [ERROR] wnmmp.ini must ship with wnmmp. Re-download the full package,
echo [ERROR] or restore that file before running install.bat.
echo.
pause
exit 1
