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
set "PHP_DIR=%HOME_DIR%\php"
set "PHP_EXE=%HOME_DIR%\php\php.exe"
set "PHP_INI=%HOME_DIR%\etc\php\php.ini"
set "TMP_DIR=%HOME_DIR%\tmp"
set "COMPOSER_PATH=%HOME_DIR%\php\composer.bat"

"%PHP_EXE%" -c %PHP_INI% -r "copy('https://getcomposer.org/installer', '%TMP_DIR%\composer-setup.php');"
"%PHP_EXE%" -c %PHP_INI% -r "if (hash_file('sha384', '%TMP_DIR%\composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('%TMP_DIR%\composer-setup.php'); exit(1); }"
"%PHP_EXE%" -c %PHP_INI% %TMP_DIR%\composer-setup.php --install-dir=%PHP_DIR% --filename=composer.phar
"%PHP_EXE%" -c %PHP_INI% -r "unlink('%TMP_DIR%\composer-setup.php');"


(
    echo @echo off
    echo "%PHP_EXE%" -c %PHP_INI% "%PHP_DIR%\composer.phar" %%*
) > "%COMPOSER_PATH%"


if exist "%COMPOSER_PATH%" (
	echo Successfully generated composer.bat at:
    echo %COMPOSER_PATH%
) else (
    echo Generation failed! Please check if the path is valid.
)

for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v "Path" 2^>nul') do (
    set "OLD_PATH=%%b"
)


set "NEW_PATH=%PHP_DIR%"


if defined OLD_PATH (
    set "UPDATED_PATH=%OLD_PATH%;%NEW_PATH%"
) else (
    set "UPDATED_PATH=%NEW_PATH%"
)
setx PATH "%UPDATED_PATH%"