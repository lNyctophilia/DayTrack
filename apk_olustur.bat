@echo off
title Day Track - APK Olustur
echo.
echo   ============================================
echo     Day Track - Release APK Olusturuluyor
echo   ============================================
echo.

flutter build apk --release

if errorlevel 1 (
    echo.
    echo   [HATA] Build basarisiz!
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     BUILD BASARILI!
echo     APK: build\app\outputs\flutter-apk\app-release.apk
echo   ============================================
echo.
explorer "build\app\outputs\flutter-apk"
pause
