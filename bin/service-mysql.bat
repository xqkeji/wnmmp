:: Copyright xqkeji.cn
@echo off

set "MYSQL_PATH=%HOME_DIR%\mysql\bin\mysqld.exe"

echo "install WNMMP MySQL DB Server..."
"%NSSM_PATH%" install wnmmp-mysql "!MYSQL_PATH!"
"%NSSM_PATH%" set wnmmp-mysql Description "WNMMP MySQL DB Server"
"%NSSM_PATH%" set wnmmp-mysql AppDirectory "%HOME_DIR%\mysql\bin"
"%NSSM_PATH%" set wnmmp-mysql AppParameters "--defaults-file=""%CONFIG_DIR%\mysql\my.ini"" --datadir=""%DATA_DIR%\mysql"" --log-error=""%LOGS_DIR%\mysql\error.log"" --general-log-file=""%LOGS_DIR%\mysql\general.log"" --slow-query-log-file=""%LOGS_DIR%\mysql\slow.log"""
"%NSSM_PATH%" set wnmmp-mysql AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mysql

