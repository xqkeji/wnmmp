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

set "MYSQL_PATH=%HOME_DIR%\mysql\bin\mysqld.exe"

echo "正在安装 WNMMP MySQL 服务..."
"%NSSM_PATH%" install wnmmp-mysql "!MYSQL_PATH!"
"%NSSM_PATH%" set wnmmp-mysql Description "WNMMP MySQL DB Server"
"%NSSM_PATH%" set wnmmp-mysql AppDirectory "%HOME_DIR%\mysql\bin"
"%NSSM_PATH%" set wnmmp-mysql AppParameters "--defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log"""
"%NSSM_PATH%" set wnmmp-mysql AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mysql



