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

REM This script lives in <root>\bin, so the installer exe sits in the same folder.
REM Delayed expansion is required by the "set MSGn / echo !MSGn!" pattern used for
REM every Chinese message below. install.bat already enables it, but enabling it
REM here as well keeps the script correct when it is started directly. Nothing is
REM exported back to the caller, so the implicit endlocal at exit is harmless.
setlocal enabledelayedexpansion
set "vc_installer=%~dp0VC_redist.x64.exe"

if not exist "%vc_installer%" (
    set "MSG1=[警告] 未找到 VC_redist 安装程序: %vc_installer%"
    set "MSG2=[警告] PHP 运行需要 Microsoft Visual C++ 运行库，请确认 bin\VC_redist.x64.exe 存在。"
    echo !MSG1!
    echo !MSG2!
    goto :eof
)

REM ---- 已安装则询问是否跳过 ----
set "VC_ALREADY=0"
for %%K in (
  "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
  "HKLM\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
) do (
  reg query %%K /v Installed 2>nul | find "0x1" >nul
  if not errorlevel 1 set "VC_ALREADY=1"
)
if "%VC_ALREADY%"=="1" (
  set "MSG1=[VC_redist] 检测到 Microsoft Visual C++ 运行库（x64）已安装。"
  echo !MSG1!
  set "REINSTALL=N"
  set /p "REINSTALL=VC_redist 已安装，是否重新安装？（输入 Y 重装，回车跳过）："
  if /i "%REINSTALL%"=="Y" goto :vc_install
  goto :vc_skip
)

:vc_install
echo 正在安装 VC_redist.x64.exe（Microsoft Visual C++ 运行库）……
"%vc_installer%" /quiet /norestart
if errorlevel 3010 (
    set "MSG1=[提示] VC_redist 安装完成，但需要重启系统才能生效（退出码 3010）。"
    echo !MSG1!
) else if errorlevel 1 (
    set "MSG1=[警告] VC_redist 安装可能未成功（退出码非零），请手动运行: %vc_installer%"
    echo !MSG1!
)
set "MSG1=VC_redist 安装程序已结束。"
echo !MSG1!
goto :eof

REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:vc_skip
echo [skip] VC_redist 已安装，跳过安装。
