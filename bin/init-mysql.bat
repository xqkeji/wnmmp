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
if not exist "%DATA_DIR%\mysql" (
	mkdir "%DATA_DIR%\mysql"
)
if not exist "%DATA_DIR%\mysql\mysql" (
    "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --initialize-insecure --console
 	start "MySQL Server" /B "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --console
 	timeout /t 10 /nobreak >nul
 	"%HOME_DIR%\mysql\bin\mysql.exe" -u root --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY 'xqkeji.cn'; FLUSH PRIVILEGES;"
 	tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
	echo "mysql init complete!"
)
