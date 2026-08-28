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

set MONGODB_DOWNLOAD_URL=https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.3.2.zip
set MONGODB_ZIP_DIR=mongodb-win32-x86_64-windows-8.3.2
set MONGODB_OLD_DOWNLOAD_URL=https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-5.0.33.zip
set MONGODB_OLD_ZIP_DIR=mongodb-win32-x86_64-windows-5.0.33
set MONGOSH_DOWNLOAD_URL=https://downloads.mongodb.com/compass/mongosh-2.8.3-win32-x64.zip
set MONGOSH_ZIP_DIR=mongosh-2.8.3-win32-x64
set MONGOSH_OLD_DOWNLOAD_URL=https://downloads.mongodb.com/compass/mongosh-1.10.6-win32-x64.zip
set MONGOSH_OLD_ZIP_DIR=mongosh-1.10.6-win32-x64
set MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/MySQL-9.7/mysql-9.7.0-winx64.zip
set MYSQL_ZIP_DIR=mysql-9.7.0-winx64
set NGINX_DOWNLOAD_URL=https://nginx.org/download/nginx-1.31.0.zip
set NGINX_ZIP_DIR=nginx-1.31.0
set PHP_DOWNLOAD_URL=https://downloads.php.net/~windows/releases/archives/php-8.5.6-nts-Win32-vs17-x64.zip
REM The 4 PECL extension URLs (mongodb/apcu/xdebug/psr) are
REM no longer pinned here. bin/download-php.bat resolves them at RUNTIME from
REM the actually-installed php.exe version and auto-matches the latest vs17/
REM nts/x64 build; if none exists it reports an [ERROR] instead of a silent
REM skip. Only php_xqkeji (gitee) is pinned below.
REM Auto-detected at RUNTIME in download-php.bat (:xqkeji_detect) -- this is
REM only the safe FALLBACK used when the gitee tags API is unreachable.
set PHP_XQKEJI_DOWNLOAD_URL=https://gitee.com/xqkeji/php-xqkeji/repository/archive/v1.1.1-php8.5.zip
set PHP_XQKEJI_ZIP_DIR=php-xqkeji-v1.1.1-php8.5

REM ---------------------------------------------------------------------------
REM Resolve latest versions for every component. get-latest.bat overrides the
REM pinned defaults above ONLY when detection succeeds; on failure the pinned
REM values remain as a safe fallback.
REM ---------------------------------------------------------------------------
call get-latest.bat


