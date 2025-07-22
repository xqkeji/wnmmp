:: Copyright xqkeji.cn
@echo off

set "NGINX_PATH=%HOME_DIR%\nginx\nginx.exe"

echo "install WNMMP Nginx Web Server..."
"%NSSM_PATH%" install wnmmp-nginx "!NGINX_PATH!"
"%NSSM_PATH%" set wnmmp-nginx Description "WNMMP Nginx Web Server"
"%NSSM_PATH%" set wnmmp-nginx AppDirectory "%HOME_DIR%\nginx"
"%NSSM_PATH%" set wnmmp-nginx AppParameters "-p ""%HOME_DIR%"" -c ""%HOME_DIR%\etc\nginx\nginx.conf"""
"%NSSM_PATH%" set wnmmp-nginx AppExit Default Restart
"%NSSM_PATH%" start wnmmp-nginx


