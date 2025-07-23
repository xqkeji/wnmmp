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

set "MONGODB_PATH=%HOME_DIR%\mongodb\bin\mongod.exe"

echo "install WNMMP MongoDB DB Server..."
"%NSSM_PATH%" install wnmmp-mongodb "!MONGODB_PATH!" 
"%NSSM_PATH%" set wnmmp-mongodb Description "WNMMP MongoDB DB Server"
"%NSSM_PATH%" set wnmmp-mongodb AppDirectory %HOME_DIR%\mongodb\bin
"%NSSM_PATH%" set wnmmp-mongodb AppParameters "--config ""%CONFIG_DIR%\mongodb\mongo.conf"" --dbpath ""%DATA_DIR%\mongodb"" --logpath ""%LOGS_DIR%\mongodb\info.log"" --auth"
"%NSSM_PATH%" set wnmmp-mongodb AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mongodb

