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
REM register-path.bat -- put %HOME_DIR%\bin\composer at the FRONT of PATH so
REM the install we just performed WINS over older wnmmp installs still on disk.
REM
REM Requires (from caller): HOME_DIR        -- wnmmp root
REM Optional:              TMP_DIR          -- backup dir, defaults to %TEMP%
REM                        PC_ADMIN         -- 1 when running elevated
REM                        WNMMP_PATH_SYSTEM=1 -- write the SYSTEM path (admin)
REM                        WNMMP_PATH_DRYRUN=1 -- preview only, write nothing
REM
REM Why PREPEND instead of append:
REM   Windows resolves PATH left to right. The old code appended the new entry
REM   to the END, so an older wnmmp still on disk, e.g. D:\wnmmp-1.0.17, kept
REM   shadowing a fresh D:\wnmmp-1.1.3 -- php.bat / composer.bat from the OLD
REM   version ran instead of the new one.
REM
REM Stale entries dropped while rebuilding:
REM   1. anything already pointing inside %HOME_DIR%   -- keeps us idempotent
REM   2. any ...\composer dir that holds our php.bat shim -- an older wnmmp
REM
REM Why reg add instead of setx:
REM   setx TRUNCATES values longer than 1024 chars and would silently eat the
REM   user's PATH. reg add has no such limit and keeps the REG_EXPAND_SZ type.
REM   The trailing dummy setx is only there to broadcast WM_SETTINGCHANGE so
REM   new consoles see the change without a logoff.
REM
REM NOTE: Windows searches the SYSTEM path BEFORE the user path. Prepending to
REM the user path beats every other user entry, but NOT a php.exe that lives in
REM the system path. Set WNMMP_PATH_SYSTEM=1 and run elevated to win that too.
REM ===========================================================================

set "RP_DE=1"
if not "!RP_DE!"=="1" (
	echo "[path] 需要 enabledelayedexpansion，已跳过 PATH 注册"
	goto :eof
)
if not defined HOME_DIR goto :eof
if not defined TMP_DIR set "TMP_DIR=%TEMP%"
set "RP_DIR=%HOME_DIR%\bin\composer"
if not exist "%RP_DIR%" goto :eof
if not exist "%TMP_DIR%" md "%TMP_DIR%" >nul 2>&1

set "RP_HIVE=HKCU\Environment"
set "RP_SCOPE=用户"
if "%WNMMP_PATH_SYSTEM%"=="1" if "%PC_ADMIN%"=="1" (
	set "RP_HIVE=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
	set "RP_SCOPE=系统"
)
if "%WNMMP_PATH_SYSTEM%"=="1" if not "%PC_ADMIN%"=="1" echo "[path] WNMMP_PATH_SYSTEM=1 需要管理员权限，本次仍写入用户 PATH"

REM ---- read the current value with delayed expansion OFF: a literal bang in
REM ---- PATH must not be eaten by the !var! rewriting performed further below.
set "RP_OLD="
setlocal disabledelayedexpansion
for /f "skip=1 tokens=2*" %%a in ('reg query "%RP_HIVE%" /v "Path" 2^>nul') do set "RP_OLD=%%b"
endlocal & set "RP_OLD=%RP_OLD%"

REM ---- parse-safe backup: set VAR prints the raw value, nothing is re-parsed
set "RP_BAK=%TMP_DIR%\path-backup.txt"
set RP_OLD > "%RP_BAK%"

REM ---- bail out rather than corrupt an environment we cannot round-trip
findstr /c:"!" "%RP_BAK%" >nul 2>&1
if not errorlevel 1 (
	echo "[path] 检测到 PATH 中含感叹号，脚本无法安全改写，已跳过"
	echo "[path] 请手动把 %RP_DIR% 移动到 PATH 的最前面"
	goto :eof
)

call :rp_len "!RP_OLD!" RP_OLDLEN
if !RP_OLDLEN! GTR 6000 (
	echo "[path] 原 PATH 长度 !RP_OLDLEN! 过长，已跳过改写"
	goto :eof
)

REM ---- rebuild: new dir first, then every surviving old entry. Using !var!
REM ---- here and NOT %var% keeps the ) of Program Files (x86) from closing
REM ---- the for-in clause, because delayed expansion runs after parsing.
REM ---- Loop var is %%E on purpose: E is not one of the %%~ modifiers
REM ---- (d p n x f s a t z), so %%~E unambiguously means strip quotes.
set "RP_NEW=%RP_DIR%"
set "RP_TOTAL=0"
set "RP_DROP=0"
set "RP_LIST=!RP_OLD:;=";"!"
for %%E in ("!RP_LIST!") do (
	set "RP_P=%%~E"
	set "RP_KEEP=1"
	if defined RP_P (
		set /a RP_TOTAL+=1
		if /i not "!RP_P:%HOME_DIR%=!"=="!RP_P!" set "RP_KEEP=0"
		if "!RP_KEEP!"=="1" if /i "%%~nxE"=="composer" (
			set "RP_T=%%~E"
			if /i not "!RP_T:wnmmp=!"=="!RP_T!" set "RP_KEEP=0"
			if exist "%%~E\php.bat" set "RP_KEEP=0"
		)
	) else (
		set "RP_KEEP=0"
	)
	if "!RP_KEEP!"=="1" (
		set "RP_NEW=!RP_NEW!;!RP_P!"
	) else (
		if defined RP_P set /a RP_DROP+=1
	)
)

call :rp_len "!RP_NEW!" RP_LEN
if !RP_LEN! GTR 2048 (
	echo "[path] 新 PATH 长度 !RP_LEN! 超过 2048，已放弃改写以免损坏环境变量"
	goto :eof
)

if "%WNMMP_PATH_DRYRUN%"=="1" (
	set RP_NEW > "%TMP_DIR%\path-new.txt"
	echo "[path] DRYRUN 未写入注册表。预览已存到 %TMP_DIR%\path-new.txt"
	echo "[path] 将置为%RP_SCOPE% PATH 第一项：%RP_DIR%，长度 !RP_LEN!，清掉 !RP_DROP! 条旧记录"
	goto :eof
)

reg add "%RP_HIVE%" /v Path /t REG_EXPAND_SZ /d "!RP_NEW!" /f >nul 2>&1
if errorlevel 1 (
	echo "[path] 写入 PATH 失败，可能权限不足，已保持原 PATH 不变"
	goto :eof
)

REM ---- verify by reading back; roll back if it does not match what we sent
set "RP_CHK="
setlocal disabledelayedexpansion
for /f "skip=1 tokens=2*" %%a in ('reg query "%RP_HIVE%" /v "Path" 2^>nul') do set "RP_CHK=%%b"
endlocal & set "RP_CHK=%RP_CHK%"
if not "!RP_CHK!"=="!RP_NEW!" (
	reg add "%RP_HIVE%" /v Path /t REG_EXPAND_SZ /d "!RP_OLD!" /f >nul 2>&1
	echo "[path] 写回校验失败，已还原原 PATH"
	goto :eof
)

REM ---- broadcast WM_SETTINGCHANGE so new consoles pick it up (setx does it)
setx WNMMP_PATH_TOUCH 1 >nul 2>&1
reg delete "HKCU\Environment" /v WNMMP_PATH_TOUCH /f >nul 2>&1

echo "[path] 已把 %RP_DIR% 置于%RP_SCOPE% PATH 的最前面"
echo "[path] 共扫描 !RP_TOTAL! 条，清掉 !RP_DROP! 条旧 wnmmp 记录，备份见 %RP_BAK%"
goto :eof


REM ===================== helper :rp_len =====================
REM Args: %1=<string>  %2=<out var>   -- count characters in %1
:rp_len
set "RP_S=%~1"
set "%~2=0"
:rp_len_loop
if not defined RP_S goto :eof
set "RP_S=!RP_S:~1!"
set /a "%~2+=1"
goto :rp_len_loop
