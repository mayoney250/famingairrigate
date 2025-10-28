@echo off
echo ================================================
echo   Deploying Firestore Security Rules
echo ================================================
echo.
echo This will update your Firebase Firestore security rules.
echo Make sure you have Firebase CLI installed and logged in.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Checking Firebase CLI...
firebase --version
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Firebase CLI not found!
    echo.
    echo Please install Firebase CLI first:
    echo npm install -g firebase-tools
    echo.
    echo Then login:
    echo firebase login
    echo.
    pause
    exit /b 1
)

echo.
echo Firebase CLI found! ✓
echo.
echo Deploying Firestore rules...
echo.

firebase deploy --only firestore:rules

if %ERRORLEVEL% EQ 0 (
    echo.
    echo ================================================
    echo   ✅ Firestore Rules Deployed Successfully!
    echo ================================================
    echo.
    echo Your database rules are now updated.
    echo Users can now save data to your database.
    echo.
    echo Next steps:
    echo 1. Restart your Flutter app
    echo 2. Test data saving (register, add field, etc.)
    echo 3. Use the "Test DB" button in dashboard to verify
    echo.
) else (
    echo.
    echo ================================================
    echo   ❌ Deployment Failed!
    echo ================================================
    echo.
    echo Common issues:
    echo 1. Not logged in: Run 'firebase login'
    echo 2. Wrong project: Run 'firebase use [project-id]'
    echo 3. No internet connection
    echo.
    echo Try running these commands manually:
    echo   firebase login
    echo   firebase use ngairrigate
    echo   firebase deploy --only firestore:rules
    echo.
)

pause

