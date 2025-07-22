:: Copyright xqkeji.cn
@echo off

set "MONGODB_PATH=%HOME_DIR%\mongodb\bin\mongod.exe"

echo "install WNMMP MongoDB DB Server..."
"%NSSM_PATH%" install wnmmp-mongodb "!MONGODB_PATH!" 
"%NSSM_PATH%" set wnmmp-mongodb Description "WNMMP MongoDB DB Server"
"%NSSM_PATH%" set wnmmp-mongodb AppDirectory %HOME_DIR%\mongodb\bin
"%NSSM_PATH%" set wnmmp-mongodb AppParameters "--config ""%CONFIG_DIR%\mongodb\mongo.conf"" --dbpath ""%DATA_DIR%\mongodb"" --logpath ""%LOGS_DIR%\mongodb\info.log"" --auth"
"%NSSM_PATH%" set wnmmp-mongodb AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mongodb

