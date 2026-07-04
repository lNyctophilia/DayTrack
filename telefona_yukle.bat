@echo off
title Day Track - Telefona Yukle
echo.
echo   ============================================
echo     Day Track - Release Telefona Yukleniyor
echo   ============================================
echo   Telefonun baglanip kilidinin acik oldugundan
echo   emin olun.
echo.

flutter install --release

if errorlevel 1 (
    echo.
    echo   [HATA] Yukleme basarisiz!
    echo   Telefon bagli mi? USB debugging acik mi?
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     YUKLEME BASARILI!
echo   ============================================
echo.
pause
