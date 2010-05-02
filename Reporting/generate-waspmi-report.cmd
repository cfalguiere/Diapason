@echo off

set CURRENT_DIR=%~dp0
echo %CURRENT_DIR%

set DIAPASON_HOME=%CURRENT_DIR%
set R_HOME=%DIAPASON_HOME%\..\..\R-2.9.0-win32
set SCRIPT_DIR=scripts

set R_OPTIONS=--slave --no-save --no-restore --no-environ
rem # --slave --silent

echo =========== WAS PMI reports =============

set R_SCRIPT_TR=%DIAPASON_HOME%\%SCRIPT_DIR%\waspmi\process_waspmi.r
set R_OUTPUT_TR=%DIAPASON_HOME%\reports\process_waspmi.log

%R_HOME%\bin\R.exe CMD BATCH %R_SCRIPT_TR% %R_OUTPUT_TR%
