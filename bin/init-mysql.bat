:: Copyright xqkeji.cn
@echo off

if not exist "%DATA_DIR%\mysql\mysql" (
    "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --initialize-insecure --console
 	start "MySQL Server" /B "%HOME_DIR%\mysql\bin\mysqld.exe" --defaults-file="%CONFIG_DIR%\mysql\my.ini" --datadir="%DATA_DIR%\mysql" --log-error="%LOGS_DIR%\mysql\error.log" --console
 	timeout /t 10 /nobreak >nul
 	"%HOME_DIR%\mysql\bin\mysql.exe" -u root --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY 'xqkeji.cn'; FLUSH PRIVILEGES;"
 	tasklist | findstr /i mysqld.exe && taskkill /f /im mysqld.exe
	echo "mysql init complete!"
)
