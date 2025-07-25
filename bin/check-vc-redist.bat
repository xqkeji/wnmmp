:: Copyright (c) xqkeji.cn. All rights reserved.
:: Author: Zhang Wenhao
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::     http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
@echo off
setlocal enabledelayedexpansion

:: Configuration
set "req_major=14"
set "req_minor=44"
set "vc_installer=%HOME_DIR%\bin\VC_redist.x64.exe"  :: Replace with your installer path
set "found_version="
set "is_compatible=0"

echo Checking VC++ Redistributable version...

:: Search registry for VC++ installations
for %%p in (
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
) do (
    reg query "%%~p" /v DisplayName 2>nul | findstr /i "VC\+\+ 2015 2017 2019 2022" >nul && (
        for /f "tokens=2*" %%a in ('reg query "%%~p" /v DisplayName 2^>nul') do (
            :: Extract version number
            for /f "tokens=3 delims=() " %%v in ("%%b") do set "ver=%%v"
            if "!ver!"=="" (
                for /f "tokens=4 delims= " %%v in ("%%b") do set "ver=%%v"
            )
            
            if "!ver!" neq "" (
                set "found_version=!ver!"
                goto check_version
            )
        )
    )
)

:check_version
if "!found_version!"=="" (
    echo No VC++ Redistributable found. Need to install.
    set "is_compatible=0"
) else (
    :: Parse version
    for /f "tokens=1,2 delims=." %%a in ("!found_version!") do (
        if %%a gtr !req_major! (
            set "is_compatible=1"
        ) else (
            if %%a equ !req_major! (
                if %%b geq !req_minor! (
                    set "is_compatible=1"
                ) else (
                    set "is_compatible=0"
                )
            )
        )
    )
)

:: Execute installation if needed
if !is_compatible! equ 1 (
    echo VC++ Redistributable version !found_version! is compatible. No installation needed.
) else (
    echo VC++ Redistributable is incompatible or missing. Installing...
    if exist "%vc_installer%" (
        start /wait "" "%vc_installer%" /quiet /norestart
        echo Installation VC++ Redistributable completed.
    ) else (
        echo Error: Installer "%vc_installer%" not found!
        exit /b 1
    )
)

endlocal
