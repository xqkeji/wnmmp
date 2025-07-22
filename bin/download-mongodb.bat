:: Copyright xqkeji.cn
@echo off
set "MONGODB_DIR=%HOME_DIR%\mongodb"

if not exist "%MONGODB_DIR%" (
	mkdir "%MONGODB_DIR%"
	wget.exe -O %TMP_DIR%\download\mongodb.zip %MONGODB_DOWNLOAD_URL%
	wget.exe -O %TMP_DIR%\download\mongosh.zip %MONGOSH_DOWNLOAD_URL%
	unzip -o %TMP_DIR%\download\mongodb.zip -d %TMP_DIR%\download
	unzip -o %TMP_DIR%\download\mongosh.zip -d %TMP_DIR%\download
	xcopy "%TMP_DIR%\download\%MONGODB_ZIP_DIR%\*" "%MONGODB_DIR%" /E /H /Y /I
	copy "%TMP_DIR%\download\%MONGOSH_ZIP_DIR%\bin\mongosh.exe" "%MONGODB_DIR%\bin\mongosh.exe" /Y
)

