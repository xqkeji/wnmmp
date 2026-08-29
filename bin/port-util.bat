@echo off
set "_PU_LABEL=%~1"
if not defined _PU_LABEL goto :eof
shift /1
goto %_PU_LABEL%
REM -------------------------------------------------------------
REM WNMMP shared port / process ownership helper.
REM
REM This file is deliberately kept 100% ASCII. It is CALLed from
REM inside parenthesized blocks; non-ASCII REM lines in such a
REM helper can be mis-tokenized by cmd.exe and run as commands.
REM Keep every character here plain ASCII. Do not add Chinese.
REM
REM Prerequisite: the caller must have run setlocal enabledelayedexpansion.
REM This file must NOT setlocal, so the variables it fills in are
REM returned to the caller.
REM
REM Dispatch: arg 1 is the target label. It is captured first, then
REM shift /1 removes it, so inside each helper args start at 1.
REM
REM Usage:
REM   call bin\port-util.bat :pid_lookup PID OUT_IMAGE OUT_SERVICE
REM       sets OUT_IMAGE=image.exe, OUT_SERVICE=service name or N/A
REM   call bin\port-util.bat :port_owner PORT OUT_BUSY OUT_PID OUT_IMAGE OUT_SERVICE
REM       sets OUT_BUSY=1 and fills pid/image/service when that port is
REM       LISTENING, otherwise OUT_BUSY=0
REM -------------------------------------------------------------

REM ===================== helper :pid_lookup =====================
REM Args: 1=PID  2=out image var  3=out service var
:pid_lookup
set "%~2="
set "%~3=N/A"
REM tokens=1,2* and not 1,3: the service column may itself contain
REM commas, e.g. "svchost.exe","1780","BrokerInfrastructure,DcomLaunch",
REM so it must be captured as *rest of line* into %%c. With tokens=1,3 only
REM %%a and %%b are allocated, %%c is never set and the value is chopped.
for /f "tokens=1,2* delims=," %%a in ('tasklist /svc /fi "PID eq %~1" /fo csv /nh 2^>nul') do (
	set "%~2=%%~a"
	set "%~3=%%~c"
)
REM tasklist writes in the SYSTEM ANSI code page (936 on Chinese Windows),
REM NOT the 65001 page the caller switched to, so its localized no-service
REM marker is invalid UTF-8 there and echoes back as garbage. Service names
REM are plain ASCII, so anything else is reported as N/A instead.
if not defined %~3 set "%~3=N/A"
if not "!%~3!"=="N/A" (
	if defined TMP_DIR ( set "_PU_TMP=%TMP_DIR%" ) else ( set "_PU_TMP=%TEMP%" )
	if not exist "!_PU_TMP!" md "!_PU_TMP!" >nul 2>&1
	> "!_PU_TMP!\pc_svc.txt" echo(!%~3!
	findstr /r "^[a-zA-Z0-9_.,-][a-zA-Z0-9_.,-]*$" "!_PU_TMP!\pc_svc.txt" >nul 2>&1
	if errorlevel 1 set "%~3=N/A"
)
goto :eof

REM ===================== helper :port_owner =====================
REM Args: 1=PORT  2=out busy  3=out pid  4=out image  5=out service
:port_owner
set "%~2=0"
set "%~3="
set "%~4="
set "%~5=N/A"
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| findstr /c:":%~1 " ^| findstr "LISTENING"') do (
	set "%~2=1"
	set "%~3=%%P"
)
if "!%~2!"=="1" (
	if not "!%~3!"=="" call :pid_lookup "!%~3!" "%~4" "%~5"
)
goto :eof
