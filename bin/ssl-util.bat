@echo off
set "_SU_LABEL=%~1"
if not defined _SU_LABEL goto :eof
shift /1
goto %_SU_LABEL%
REM -------------------------------------------------------------
REM WNMMP shared HTTPS state helper.
REM
REM This file is deliberately kept 100% ASCII. It is CALLed from
REM inside parenthesized blocks; non-ASCII REM lines in such a
REM helper can be mis-tokenized by cmd.exe and run as commands.
REM Keep every character here plain ASCII. Do not add Chinese.
REM
REM Prerequisite: the caller must have run setlocal enabledelayedexpansion
REM and must have HOME_DIR pointing at the wnmmp root.
REM This file must NOT setlocal, so the variables it fills in are
REM returned to the caller.
REM
REM Usage:
REM   call bin\ssl-util.bat :nginx_port OUT_VAR
REM       sets OUT_VAR to 443 when any site under
REM       etc\nginx\conf.d listens on 443 with ssl, otherwise 80.
REM       That is the port wnmmp's health checks, stop handling and
REM       install-time port probing must use for nginx; the answer
REM       comes from the site files themselves, so there is no
REM       second state file to keep in sync when a user edits the
REM       config by hand.
REM
REM   call bin\ssl-util.bat :https_enabled OUT_VAR
REM       sets OUT_VAR to 1 or 0, same question, boolean answer.
REM -------------------------------------------------------------

REM ===================== helper :nginx_port =====================
REM Args: 1=out port var
:nginx_port
set "%~1=80"
call :scan_443
if "!_SU_HTTPS!"=="1" set "%~1=443"
goto :eof

REM ===================== helper :https_enabled =====================
REM Args: 1=out flag var
:https_enabled
call :scan_443
set "%~1=!_SU_HTTPS!"
goto :eof

REM ===================== internal :scan_443 =====================
REM Sets _SU_HTTPS to 1 when a site listens on 443 with ssl.
REM Two patterns: the plain "listen 443 ssl" form (any amount of
REM spacing, which is how ssl-enable.ps1 leaves the text it was given)
REM and the IPv6 form "listen [::]:443 ssl", where the port sits behind
REM a closing bracket. Comments are not filtered out, but a site file
REM that mentions 443 ssl in a comment while actually listening on 80
REM is a hand-made edge case; the port only drives a health check.
:scan_443
set "_SU_HTTPS=0"
set "_SU_DIR=%HOME_DIR%\etc\nginx\conf.d"
if not exist "!_SU_DIR!\" goto :eof
findstr /r /c:"listen *443 *ssl" /c:"]:443 *ssl" "!_SU_DIR!\*.conf" >nul 2>&1
if not errorlevel 1 set "_SU_HTTPS=1"
goto :eof
