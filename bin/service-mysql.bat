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

set "MYSQL_PATH=%HOME_DIR%\mysql\bin\mysqld.exe"

set "MSG1=正在安装 WNMMP MySQL 服务..."
echo !MSG1!
"%NSSM_PATH%" install wnmmp-mysql "!MYSQL_PATH!"
"%NSSM_PATH%" set wnmmp-mysql Description "WNMMP MySQL DB Server"
"%NSSM_PATH%" set wnmmp-mysql AppDirectory "%HOME_DIR%\mysql\bin"
"%NSSM_PATH%" set wnmmp-mysql AppParameters "--defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log"""
"%NSSM_PATH%" set wnmmp-mysql AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mysql



