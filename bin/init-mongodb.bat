:: Copyright xqkeji.cn
@echo off

if not exist "%DATA_DIR%\mongodb\*.wt" (
	start "MongoDB Server" /B "%HOME_DIR%\mongodb\bin\mongod.exe" --config %CONFIG_DIR%\mongodb\mongo.conf --dbpath %DATA_DIR%\mongodb --logpath %LOGS_DIR%\mongodb\info.log
	timeout /t 10 /nobreak >nul
	"%HOME_DIR%\mongodb\bin\mongosh.exe" --port 27017 "%CONFIG_DIR%\mongodb\create_admin.js"
	tasklist | findstr /i mongod.exe && taskkill /f /im mongod.exe
	timeout /t 3 /nobreak >nul
	echo "mongodb init complete!"
)

