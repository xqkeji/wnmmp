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

