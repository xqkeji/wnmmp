:: Copyright xqkeji.cn
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