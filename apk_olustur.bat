@echo off
echo ==============================================
echo APK Derleniyor... Lutfen bekleyin, bu islem biraz surebilir.
echo ==============================================

flutter build apk --release

echo.
echo ==============================================
echo Derleme Tamamlandi! APK dosyasinin bulundugu klasor aciliyor...
echo ==============================================
explorer "build\app\outputs\flutter-apk"

echo.
pause
