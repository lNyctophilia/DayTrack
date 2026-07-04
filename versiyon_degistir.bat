@echo off
chcp 65001 >nul
title Day Track - Versiyon Degistir

echo.
echo   ============================================
echo     Day Track - Versiyon Degistirici
echo   ============================================
echo.
echo   Format: X.Y.Z (ornek: 1.2.0)
echo.

set /p "VERSION=  Yeni versiyon: "

if "%VERSION%"=="" (
    echo.
    echo   [HATA] Versiyon bos olamaz!
    pause
    exit /b 1
)

:: PowerShell ile format kontrolu ve dosya guncelleme
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_update_version.ps1" "%VERSION%"

if errorlevel 1 (
    echo.
    echo   [HATA] Versiyon guncellenemedi!
    pause
    exit /b 1
)

echo.
echo   ============================================
echo.
pause
