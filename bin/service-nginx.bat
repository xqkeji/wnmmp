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

set "NGINX_PATH=%HOME_DIR%\nginx\nginx.exe"

echo "install WNMMP Nginx Web Server..."
"%NSSM_PATH%" install wnmmp-nginx "!NGINX_PATH!"
"%NSSM_PATH%" set wnmmp-nginx Description "WNMMP Nginx Web Server"
"%NSSM_PATH%" set wnmmp-nginx AppDirectory "%HOME_DIR%\nginx"
"%NSSM_PATH%" set wnmmp-nginx AppParameters "-p ""%HOME_DIR%"" -c ""%HOME_DIR%\etc\nginx\nginx.conf"""
"%NSSM_PATH%" set wnmmp-nginx AppExit Default Restart
"%NSSM_PATH%" start wnmmp-nginx


