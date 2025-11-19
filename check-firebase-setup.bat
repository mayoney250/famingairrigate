@echo off
echo ================================================
echo   Firebase CLI Setup Checker
echo ================================================
echo.

REM Check if Node.js is installed
echo Checking Node.js...
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js not found!
    echo.
    echo You need Node.js to install Firebase CLI.
    echo Download from: https://nodejs.org/
    echo.
    echo After installing Node.js, restart this script.
    pause
    exit /b 1
)
echo ✅ Node.js found: 
node --version
echo.

REM Check if Firebase CLI is installed
echo Checking Firebase CLI...
firebase --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI not found!
    echo.
    echo Installing Firebase CLI...
    echo This may take a few minutes...
    echo.
    npm install -g firebase-tools
    echo.
    if %ERRORLEVEL% EQ 0 (
        echo ✅ Firebase CLI installed successfully!
    ) else (
        echo ❌ Installation failed!
        echo Try running as Administrator or manually:
        echo npm install -g firebase-tools
        pause
        exit /b 1
    )
) else (
    echo ✅ Firebase CLI found:
    firebase --version
)
echo.

REM Check if logged in
echo Checking Firebase login status...
firebase projects:list >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ Not logged in to Firebase!
    echo.
    echo Attempting to login...
    echo A browser window will open for authentication.
    echo.
    pause
    firebase login
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Login failed!
        echo Try again: firebase login
        pause
        exit /b 1
    )
)
echo ✅ Logged in to Firebase!
echo.

REM List projects
echo Your Firebase projects:
firebase projects:list
echo.

REM Check current project
echo Current project:
firebase use
echo.

REM Verify correct project
echo ================================================
echo   Setup Check Complete!
echo ================================================
echo.
echo Current project should be: ngairrigate
echo.
echo If incorrect, run:
echo   firebase use ngairrigate
echo.
echo To deploy rules, run:
echo   firebase deploy --only firestore:rules
echo.
echo Or double-click: deploy-firestore-rules.bat
echo.
pause

