:: Copyright xqkeji.cn
@echo off
setlocal enabledelayedexpansion

set "script_dir_with_slash=%~dp0"
set "HOME_DIR=%script_dir_with_slash:~0,-1%"

set "NSSM_PATH=%HOME_DIR%\bin\nssm.exe"

if not exist "%NSSM_PATH%" (
	echo "error not found nssm.exe"
	pause
	exit /b 1
)

%NSSM_PATH% stop wnmmp-nginx
%NSSM_PATH% remove wnmmp-nginx confirm

%NSSM_PATH% stop wnmmp-mongodb
%NSSM_PATH% remove wnmmp-mongodb confirm

%NSSM_PATH% stop wnmmp-mysql
%NSSM_PATH% remove wnmmp-mysql confirm

%NSSM_PATH% stop wnmmp-php-cgi
%NSSM_PATH% remove wnmmp-php-cgi confirm