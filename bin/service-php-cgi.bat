@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM Licensed under the Apache License, Version 2.0 (the "License");
REM you may not use this file except in compliance with the License.
REM You may obtain a copy of the License at
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS,
REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM See the License for the specific language governing permissions and
REM limitations under the License.

set "PHP_CGI_PATH=%HOME_DIR%\php\php-cgi.exe"

echo "正在安装 WNMMP php-cgi 服务..."
"%NSSM_PATH%" install wnmmp-php-cgi "!PHP_CGI_PATH!"
"%NSSM_PATH%" set wnmmp-php-cgi Description "WNMMP PHP FastCGI Server"
"%NSSM_PATH%" set wnmmp-php-cgi AppDirectory "%HOME_DIR%\php"
"%NSSM_PATH%" set wnmmp-php-cgi AppParameters "-c ""%HOME_DIR%\etc\php\php.ini"" -b 127.0.0.1:9000 -d error_log=""%HOME_DIR%\logs\php\error.log"""
"%NSSM_PATH%" set wnmmp-php-cgi AppExit Default Restart
"%NSSM_PATH%" start wnmmp-php-cgi



