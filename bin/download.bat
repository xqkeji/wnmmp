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

call "download-ini.bat"
if not exist "!DOWNLOAD_DIR!" mkdir "!DOWNLOAD_DIR!"
call "download-nginx.bat"
echo "nginx download complete!"
call "download-mongodb.bat"
echo "mongodb download complete!"
call "download-mysql.bat"
echo "mysql download complete!"
call "download-php.bat"
echo "php download complete!"
rd /s /q "!DOWNLOAD_DIR!"
echo "download files clear complete!"