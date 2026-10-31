@echo off
set "_PC_LABEL=%~1"
if not defined _PC_LABEL goto :eof
shift /1
goto %_PC_LABEL%
REM -------------------------------------------------------------
REM WNMMP shared php-cgi multi-process helper.
REM
REM Keep this file 100% ASCII and DO NOT add setlocal. It is CALLed
REM from inside parenthesized blocks and it returns the PHP_CGI_*
REM variables to the caller -- same contract as bin\port-util.bat.
REM
REM Prerequisite: the caller runs setlocal enabledelayedexpansion and
REM has HOME_DIR pointing at the wnmmp root.
REM
REM Windows php-cgi.exe binds one port per process, so the process
REM count equals the port count: process i listens on
REM PHP_CGI_PORT+i-1 and is registered as service wnmmp-php-cgi-i.
REM The single source of truth for those numbers is
REM etc\php\php-cgi.conf.
REM
REM Usage:
REM   call bin\php-cgi-util.bat :load
REM       reads etc\php\php-cgi.conf and exports PHP_CGI_PROCESSES,
REM       PHP_CGI_PORT, PHP_CGI_PORT_END, PHP_CGI_SVC_MAX,
REM       PHP_CGI_WARN (1 when a value was invalid or clamped).
REM       A missing file or a broken value falls back to the defaults
REM       below and says so on stdout.
REM   call bin\php-cgi-util.bat :gen_nginx
REM       rebuilds etc\nginx\php_processes.conf so that the nginx
REM       upstream lists exactly one backend per php-cgi process. The
REM       target is only replaced when the content really differs.
REM       Calls :load itself when the caller has not loaded yet.
REM   call bin\php-cgi-util.bat :count_procs
REM       sets PHP_CGI_RUNNING to how many php-cgi.exe processes are up.
REM -------------------------------------------------------------

REM ===================== helper :load =====================
:load
set "PHP_CGI_SVC_MAX=16"
set "PHP_CGI_PROCESSES=4"
set "PHP_CGI_PORT=9000"
set "PHP_CGI_WARN=0"
set "PHP_CGI_KEYS=0"
if not defined HOME_DIR set "HOME_DIR=%CD%"
set "PHP_CGI_CONF=%HOME_DIR%\etc\php\php-cgi.conf"
if not exist "%PHP_CGI_CONF%" goto :load_sanitize
for /f "usebackq eol=# tokens=1,2 delims== " %%A in ("%PHP_CGI_CONF%") do call :cgi_set "%%A" "%%B"
REM A file that yields no key at all is broken, not empty: most of the time
REM it was saved as UTF-8 with BOM, whose bytes glue onto the first key. Say
REM it out loud instead of silently running on the defaults.
if "!PHP_CGI_KEYS!"=="0" (
	set "PHP_CGI_WARN=1"
	echo [php-cgi] no readable key in php-cgi.conf, using the defaults
)
:load_sanitize
call :cgi_number PHP_CGI_PROCESSES 4 1 %PHP_CGI_SVC_MAX%
call :cgi_number PHP_CGI_PORT 9000 1024 65534
set /a "PHP_CGI_PORT_END=PHP_CGI_PORT+PHP_CGI_PROCESSES-1"
REM The whole range must stay inside the usable port space; shrink the
REM process count rather than start instances that cannot bind.
if !PHP_CGI_PORT_END! gtr 65534 (
	set /a "PHP_CGI_PROCESSES=65535-PHP_CGI_PORT"
	set "PHP_CGI_PORT_END=65534"
	set "PHP_CGI_WARN=1"
	echo [php-cgi] port range does not fit, processes reduced to !PHP_CGI_PROCESSES!
)
echo [php-cgi] processes=!PHP_CGI_PROCESSES! ports=!PHP_CGI_PORT!-!PHP_CGI_PORT_END!
goto :eof

REM ===================== helper :cgi_set =====================
REM Args: 1=key  2=value. Unknown keys and comment leftovers are
REM ignored, so the config file can hold any note the user likes.
:cgi_set
set "_PC_K=%~1"
if not defined _PC_K goto :eof
if "%_PC_K:~0,1%"=="#" goto :eof
if "%~2"=="" goto :eof
if /i "!_PC_K!"=="processes" (
	set "PHP_CGI_PROCESSES=%~2"
	set /a "PHP_CGI_KEYS+=1"
)
if /i "!_PC_K!"=="port" (
	set "PHP_CGI_PORT=%~2"
	set /a "PHP_CGI_KEYS+=1"
)
goto :eof

REM ===================== helper :cgi_number =====================
REM Args: 1=variable name  2=default  3=min  4=max.
REM A value that is not a plain integer falls back to the default,
REM an integer outside the range is clamped. Either case is reported
REM and raises PHP_CGI_WARN.
:cgi_number
set "_PC_N=%~1"
set "_PC_V=!%~1!"
for /f "delims=0123456789" %%D in ("!_PC_V!") do set "_PC_V="
if not defined _PC_V (
	set "_PC_V=%~2"
	set "PHP_CGI_WARN=1"
	echo [php-cgi] !_PC_N! is not an integer in etc\php\php-cgi.conf, using !_PC_V!
)
if !_PC_V! lss %~3 (
	set "_PC_V=%~3"
	set "PHP_CGI_WARN=1"
	echo [php-cgi] !_PC_N! is below %~3, using %~3
)
if !_PC_V! gtr %~4 (
	set "_PC_V=%~4"
	set "PHP_CGI_WARN=1"
	echo [php-cgi] !_PC_N! is above %~4, using %~4
)
set "%~1=!_PC_V!"
goto :eof

REM ===================== helper :count_procs =====================
REM Args: none. Sets PHP_CGI_RUNNING to the number of php-cgi.exe processes on
REM the machine. The count is taken from tasklist itself instead of piping
REM through find, so it does not depend on what else is in PATH.
:count_procs
set "PHP_CGI_RUNNING=0"
for /f "tokens=1" %%p in ('tasklist /fi "IMAGENAME eq php-cgi.exe" /nh 2^>nul') do if /i "%%p"=="php-cgi.exe" set /a "PHP_CGI_RUNNING+=1"
goto :eof

REM ===================== helper :gen_nginx =====================
:gen_nginx
if not defined PHP_CGI_PROCESSES call :load
if not exist "%HOME_DIR%\etc\nginx" (
	set "PHP_CGI_WARN=1"
	echo [php-cgi] nginx config dir is missing, upstream list not updated
	goto :eof
)
set "_PC_TMP=%TMP_DIR%"
if not defined _PC_TMP set "_PC_TMP=%TEMP%"
if not defined _PC_TMP set "_PC_TMP=%HOME_DIR%\tmp"
if not exist "!_PC_TMP!" md "!_PC_TMP!" >nul 2>&1
set "_PC_NEW=!_PC_TMP!\php_processes.conf.new"
set "_PC_DST=%HOME_DIR%\etc\nginx\php_processes.conf"
(
	echo # DO NOT EDIT BY HAND - this file is generated by the wnmmp scripts.
	echo # Source of truth: etc\php\php-cgi.conf, keys processes and port
	echo # start.bat and install_service.bat rebuild this upstream list
	echo # through bin\php-cgi-util.bat :gen_nginx.
	echo.
	echo upstream php_processes {
	for /L %%i in (1,1,!PHP_CGI_PROCESSES!) do (
		set /a "_PC_PORT=PHP_CGI_PORT+%%i-1"
		echo     server 127.0.0.1:!_PC_PORT! weight=1;
	)
	echo }
) > "!_PC_NEW!"
if not exist "!_PC_NEW!" goto :gen_nginx_failed
set "_PC_DIFF=1"
if exist "!_PC_DST!" (
	fc /b "!_PC_DST!" "!_PC_NEW!" >nul 2>&1
	if not errorlevel 1 set "_PC_DIFF=0"
)
if "!_PC_DIFF!"=="1" (
	copy /y "!_PC_NEW!" "!_PC_DST!" >nul 2>&1
	echo [php-cgi] php_processes.conf rebuilt: !PHP_CGI_PROCESSES! backends on ports !PHP_CGI_PORT!-!PHP_CGI_PORT_END!
)
del "!_PC_NEW!" >nul 2>&1
if not exist "!_PC_DST!" goto :gen_nginx_failed
goto :eof

:gen_nginx_failed
del "!_PC_NEW!" >nul 2>&1
set "PHP_CGI_WARN=1"
echo [php-cgi] ERROR: cannot write !_PC_DST!
goto :eof
