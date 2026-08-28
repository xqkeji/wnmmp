@echo off
REM =============================================================
REM WNMMP 共享端口/进程占用检测辅助
REM 调用方必须已 setlocal enabledelayedexpansion（start.bat / stop.bat 均满足）。
REM 本文件不自带 setlocal，以继承调用方环境，使回填的变量能返回调用方。
REM
REM 用法:
REM   call bin\port-util.bat :pid_lookup <PID> <outImgVar> <outSvcVar>
REM       -> 设置 outImgVar=<镜像名>  outSvcVar=<服务名 或 N/A>
REM   call bin\port-util.bat :port_owner <PORT> <outBusy> <outPid> <outImg> <outSvc>
REM       -> 端口处于 LISTENING 时 outBusy=1 并回填 pid/img/svc，否则 outBusy=0
REM =============================================================

REM ===================== helper :pid_lookup =====================
:pid_lookup
set "%~2="
set "%~3=N/A"
for /f "tokens=1,3 delims=," %%a in ('tasklist /svc /fi "PID eq %~1" /fo csv /nh 2^>nul') do (
	set "%~2=%%~a"
	set "%~3=%%~c"
)
goto :eof

REM ===================== helper :port_owner =====================
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
