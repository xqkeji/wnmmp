:: Copyright xqkeji.cn
@echo off
set "NGINX_DIR=%HOME_DIR%\nginx"

if not exist "%NGINX_DIR%" (
	mkdir "%NGINX_DIR%"
	wget.exe -O %TMP_DIR%\download\nginx.zip %NGINX_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\nginx.zip -d %TMP_DIR%\download
	xcopy "%TMP_DIR%\download\%NGINX_ZIP_DIR%\*" "%NGINX_DIR%" /E /H /Y /I
)

