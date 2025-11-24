@echo off
echo ========================================
echo   Deploy Cloud Functions to Firebase
echo ========================================
echo.

echo Installing dependencies...
cd functions
call npm install
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Deploying Cloud Functions...
cd ..
call firebase deploy --only functions
if errorlevel 1 (
    echo.
    echo ERROR: Failed to deploy functions
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SUCCESS! Cloud Functions Deployed
echo ========================================
echo.
echo The following functions are now active:
echo   - checkIrrigationNeeds (runs every 2 hours)
echo   - checkWaterLevels (runs every 1 hour)
echo   - sendScheduleReminders (runs every 30 minutes)
echo   - onIrrigationStatusChange (real-time trigger)
echo.
echo Check Firebase Console for function logs
echo.
pause
