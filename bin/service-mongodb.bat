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

set "MONGODB_PATH=%HOME_DIR%\mongodb\bin\mongod.exe"

echo "正在安装 WNMMP MongoDB 服务..."
"%NSSM_PATH%" install wnmmp-mongodb "!MONGODB_PATH!" 
"%NSSM_PATH%" set wnmmp-mongodb Description "WNMMP MongoDB DB Server"
"%NSSM_PATH%" set wnmmp-mongodb AppDirectory %HOME_DIR%\mongodb\bin
"%NSSM_PATH%" set wnmmp-mongodb AppParameters "--config ""%CONFIG_DIR%\mongodb\mongo.conf"" --dbpath ""%DATA_DIR%\mongodb"" --logpath ""%LOGS_DIR%\mongodb\info.log"" --auth"
"%NSSM_PATH%" set wnmmp-mongodb AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mongodb



