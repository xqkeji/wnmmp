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

set "NGINX_PATH=%HOME_DIR%\nginx\nginx.exe"

echo "正在安装 WNMMP Nginx 服务..."
"%NSSM_PATH%" install wnmmp-nginx "!NGINX_PATH!"
"%NSSM_PATH%" set wnmmp-nginx Description "WNMMP Nginx Web Server"
"%NSSM_PATH%" set wnmmp-nginx AppDirectory "%HOME_DIR%\nginx"
"%NSSM_PATH%" set wnmmp-nginx AppParameters "-p ""%HOME_DIR%"" -c ""%HOME_DIR%\etc\nginx\nginx.conf"""
"%NSSM_PATH%" set wnmmp-nginx AppExit Default Restart
"%NSSM_PATH%" start wnmmp-nginx




