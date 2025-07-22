:: Copyright xqkeji.cn
@echo off
set "MYSQL_DIR=%HOME_DIR%\mysql"

if not exist "%MYSQL_DIR%" (
	mkdir "%MYSQL_DIR%"
	wget.exe -O %TMP_DIR%\download\mysql.zip %MYSQL_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\mysql.zip -d %TMP_DIR%\download
	xcopy "%TMP_DIR%\download\%MYSQL_ZIP_DIR%\*" "%MYSQL_DIR%" /E /H /Y /I
)

