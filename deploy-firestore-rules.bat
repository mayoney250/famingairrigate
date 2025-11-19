@echo off
echo Deploying Firestore Security Rules...
firebase deploy --only firestore:rules
echo.
echo Done! Check the output above for any errors.
pause
