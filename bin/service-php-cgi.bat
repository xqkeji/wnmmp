:: Copyright xqkeji.cn
@echo off

set "PHP_CGI_PATH=%HOME_DIR%\php\php-cgi.exe"

echo "install WNMMP php-cgi Server..."
"%NSSM_PATH%" install wnmmp-php-cgi "!PHP_CGI_PATH!"
"%NSSM_PATH%" set wnmmp-php-cgi Description "WNMMP PHP FastCGI Server"
"%NSSM_PATH%" set wnmmp-php-cgi AppDirectory "%HOME_DIR%\php"
"%NSSM_PATH%" set wnmmp-php-cgi AppParameters "-c ""%HOME_DIR%\etc\php\php.ini"" -b 127.0.0.1:9000 -d error_log=""%HOME_DIR%\logs\php\error.log"""
"%NSSM_PATH%" set wnmmp-php-cgi AppExit Default Restart
"%NSSM_PATH%" start wnmmp-php-cgi

