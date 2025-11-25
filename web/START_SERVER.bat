@echo off
echo ========================================
echo   Sensor Test Interface Server
echo ========================================
echo.
echo Starting local server...
echo.

cd /d "%~dp0"
node serve_test.js

pause

