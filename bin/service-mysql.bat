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

set "MYSQL_PATH=%HOME_DIR%\mysql\bin\mysqld.exe"

echo "install WNMMP MySQL DB Server..."
"%NSSM_PATH%" install wnmmp-mysql "!MYSQL_PATH!"
"%NSSM_PATH%" set wnmmp-mysql Description "WNMMP MySQL DB Server"
"%NSSM_PATH%" set wnmmp-mysql AppDirectory "%HOME_DIR%\mysql\bin"
"%NSSM_PATH%" set wnmmp-mysql AppParameters "--defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log"""
"%NSSM_PATH%" set wnmmp-mysql AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mysql

