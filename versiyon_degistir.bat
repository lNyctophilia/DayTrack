@echo off
chcp 65001 >nul
title Day Track - Versiyon Degistir

echo ============================================
echo   Day Track - Versiyon Degistirici
echo ============================================
echo.

set /p VERSION="Yeni versiyon numarasini girin (ornek: 1.2.0): "

if "%VERSION%"=="" (
    echo Hata: Versiyon numarasi bos olamaz!
    pause
    exit /b 1
)

echo.
echo [1/2] app_config.dart guncelleniyor...
powershell -Command "(Get-Content 'lib\core\constants\app_config.dart') -replace \"static const String version = '.*'\", \"static const String version = '%VERSION%'\" | Set-Content 'lib\core\constants\app_config.dart'"

echo [2/2] pubspec.yaml guncelleniyor...
powershell -Command "(Get-Content 'pubspec.yaml') -replace 'version: .*\+', 'version: %VERSION%+' | Set-Content 'pubspec.yaml'"

echo.
echo ============================================
echo   Versiyon %VERSION% olarak guncellendi!
echo ============================================
echo.
echo Guncellenen dosyalar:
echo   - lib\core\constants\app_config.dart
echo   - pubspec.yaml
echo.
pause
