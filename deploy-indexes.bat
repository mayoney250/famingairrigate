@echo off
echo ================================
echo   Deploying Firebase Indexes
echo ================================
echo.
echo This will deploy Firestore indexes to Firebase...
echo.
firebase deploy --only firestore:indexes
echo.
echo ================================
echo   Done!
echo ================================
echo.
echo Indexes are being built...
echo Check Firebase Console in 2-5 minutes.
echo.
pause

