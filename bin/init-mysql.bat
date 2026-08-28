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
if not exist "%DATA_DIR%\mysql" (
	mkdir "%DATA_DIR%\mysql"
)
if not exist "%DATA_DIR%\mysql\mysql" (
    "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --initialize-insecure --console
 	start "MySQL Server" /B "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --console
 	timeout /t 10 /nobreak >nul
 	"%HOME_DIR%\mysql\bin\mysql.exe" -u root --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY 'xqkeji.cn'; FLUSH PRIVILEGES;"
 	tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
	echo "mysql 初始化完成！"
)


