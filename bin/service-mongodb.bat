@echo off
chcp 65001 >nul
REM Copyright (c) xqkeji.cn. All rights reserved.
REM Author: Zhang Wenhao
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Affero General Public License as
REM published by the Free Software Foundation, version 3 only.
REM SPDX-License-Identifier: AGPL-3.0-only
REM
REM This program is distributed in the hope that it will be useful, but
REM WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
REM Affero General Public License for more details.
REM
REM You should have received a copy of the GNU Affero General Public
REM License along with this program. If not, see
REM     https://www.gnu.org/licenses/
setlocal enabledelayedexpansion

set "MONGODB_PATH=%HOME_DIR%\mongodb\bin\mongod.exe"

set "MSG1=正在安装 WNMMP MongoDB 服务..."
echo !MSG1!
"%NSSM_PATH%" install wnmmp-mongodb "!MONGODB_PATH!" 
"%NSSM_PATH%" set wnmmp-mongodb Description "WNMMP MongoDB DB Server"
"%NSSM_PATH%" set wnmmp-mongodb AppDirectory %HOME_DIR%\mongodb\bin
"%NSSM_PATH%" set wnmmp-mongodb AppParameters "--config ""%CONFIG_DIR%\mongodb\mongo.conf"" --dbpath ""%DATA_DIR%\mongodb"" --logpath ""%LOGS_DIR%\mongodb\info.log"" --auth"
"%NSSM_PATH%" set wnmmp-mongodb AppExit Default Restart
"%NSSM_PATH%" start wnmmp-mongodb



