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
for /f "tokens=1,3 delims=," %%a in ('tasklist /svc /fi "PID eq %~1" /fo csv /nh 2^>nul') do (
	set "%~2=%%~a"
	set "%~3=%%~c"
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
