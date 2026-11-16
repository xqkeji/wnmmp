@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Affero General Public License as
REM published by the Free Software Foundation, version 3 only.
REM SPDX-License-Identifier: AGPL-3.0-only
REM
REM This program is distributed in the hope that it will be useful, but
REM WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
REM Affero General Public License for more details.
REM
REM You should have received a copy of the GNU Affero General Public
REM License along with this program. If not, see
REM     https://www.gnu.org/licenses/
setlocal enabledelayedexpansion

set "NGINX_PATH=%HOME_DIR%\nginx\nginx.exe"

set "MSG1=正在安装 WNMMP Nginx 服务..."
echo !MSG1!
"%NSSM_PATH%" install wnmmp-nginx "!NGINX_PATH!"
"%NSSM_PATH%" set wnmmp-nginx Description "WNMMP Nginx Web Server"
"%NSSM_PATH%" set wnmmp-nginx AppDirectory "%HOME_DIR%\nginx"
"%NSSM_PATH%" set wnmmp-nginx AppParameters "-p ""%HOME_DIR%"" -c ""%HOME_DIR%\etc\nginx\nginx.conf"""
"%NSSM_PATH%" set wnmmp-nginx AppExit Default Restart
"%NSSM_PATH%" start wnmmp-nginx




