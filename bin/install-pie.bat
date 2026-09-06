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
REM =====================================================================
REM install-pie.bat -- 检测 PIE 是否就绪（不下载）
REM
REM PIE 是一个独立 PHAR，用于从源码编译 PHP 扩展。它和 Composer 一起放在
REM bin\composer 目录里，启动器为：
REM     bin\composer\pie.bat   （用本项目 php.exe + etc\php\php.ini 运行）
REM
REM 由于 GitHub 等下载通道在国内不稳定，pie.phar / composer.phar 均由用户
REM 自行下载后放入 bin\composer，本脚本 **不自动下载**。这里只做就位检测：
REM   - 若 bin\composer\pie.phar 存在，则设置 PIE_BIN 供 download-php.bat 使用；
REM   - 若不存在，则提示用户手动放入，PIE_BIN 保持未定义，扩展走 PECL 直下。
REM
REM 不论检测结果如何，都不会阻断安装流程。
REM
REM IMPORTANT: do NOT call "setlocal" here. install.bat enables delayed
REM expansion globally and we need PIE_BIN to propagate back to the caller.
REM =====================================================================

set "PIE_DIR=%HOME_DIR%\bin\composer"
set "PIE_PHAR=%PIE_DIR%\pie.phar"
set "PIE_BAT=%PIE_DIR%\pie.bat"

REM PIE itself needs php to run; if the core is somehow missing, skip PIE.
if not exist "%HOME_DIR%\php\php.exe" (
	set "MSG1=[WARN] php.exe 未找到，PIE 不可用，扩展将走 PECL 直下。"
	echo !MSG1!
	goto :pie_done
)

if exist "%PIE_PHAR%" (
	set "MSG1=[pie] 检测到 pie.phar（请确保已自行放入 bin\composer），已就绪。"
	echo !MSG1!
	set "PIE_BIN=%PIE_BAT%"
) else (
	set "MSG1=[WARN] 未找到 bin\composer\pie.phar，请自行下载并放入该目录；扩展将走 PECL 直下。"
	echo !MSG1!
)

REM ---- keep the lines above this label 100% ASCII: cmd.exe locates a
REM ---- CALL/GOTO target label by byte offset inside a UTF-8 batch file,
REM ---- and the Chinese text elsewhere in this file makes that offset
REM ---- drift, so execution can land a few lines ABOVE the label. Whatever
REM ---- sits there then runs, so it has to stay a harmless ASCII remark.
REM ----
REM ----
REM ----
:pie_done
