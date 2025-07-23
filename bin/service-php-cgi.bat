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

set "PHP_CGI_PATH=%HOME_DIR%\php\php-cgi.exe"

echo "install WNMMP php-cgi Server..."
"%NSSM_PATH%" install wnmmp-php-cgi "!PHP_CGI_PATH!"
"%NSSM_PATH%" set wnmmp-php-cgi Description "WNMMP PHP FastCGI Server"
"%NSSM_PATH%" set wnmmp-php-cgi AppDirectory "%HOME_DIR%\php"
"%NSSM_PATH%" set wnmmp-php-cgi AppParameters "-c ""%HOME_DIR%\etc\php\php.ini"" -b 127.0.0.1:9000 -d error_log=""%HOME_DIR%\logs\php\error.log"""
"%NSSM_PATH%" set wnmmp-php-cgi AppExit Default Restart
"%NSSM_PATH%" start wnmmp-php-cgi

