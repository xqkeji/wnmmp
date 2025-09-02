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
set "COMPOSER_DIR=%HOME_DIR%\bin\composer"

for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>nul') do (
    set "OLD_PATH=%%b"
)

set "NEW_PATH=%COMPOSER_DIR%"

if defined OLD_PATH (
	if "!OLD_PATH:%NEW_PATH%=!" neq "!OLD_PATH!" (
		set "UPDATED_PATH=%OLD_PATH%"
	) else (
		set "UPDATED_PATH=%OLD_PATH%;%NEW_PATH%"
	)  
) else (
    set "UPDATED_PATH=%NEW_PATH%"
)

setx PATH "%UPDATED_PATH%"