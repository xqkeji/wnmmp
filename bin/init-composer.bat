REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM Licensed under the Apache License, Version 2.0 (the "License");
REM You may not use this file except in compliance with the License.
REM You may obtain a copy of the License at
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS,
REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM See the License for the specific language governing permissions and
REM limitations under the License.
set "COMPOSER_DIR=%HOME_DIR%\bin\composer"
set "NEW_PATH=%COMPOSER_DIR%"

REM Best-effort: prepend composer dir to the user PATH so `composer` is
REM callable. This is NON-ESSENTIAL for the install -- any failure here must
REM never abort the whole installer, so every step is guarded.
set "OLD_PATH="
for /f "skip=1 tokens=2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>nul') do set "OLD_PATH=%%b"
if defined OLD_PATH (
	echo !OLD_PATH! | find /i "%NEW_PATH%" >nul 2>&1
	if not errorlevel 1 goto :composer_cfg
	setx PATH "%OLD_PATH%;%NEW_PATH%" >nul 2>&1
) else (
	setx PATH "%NEW_PATH%" >nul 2>&1
)

:composer_cfg
call "%COMPOSER_DIR%\composer.bat" config --global use-parent-dir true >nul 2>&1
