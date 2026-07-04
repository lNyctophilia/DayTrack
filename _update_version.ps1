param([string]$Version)

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host ""
    Write-Host "  [HATA] Format X.Y.Z olmali! (ornek: 1.2.0)"
    Write-Host "  Girilen: $Version"
    exit 1
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1) app_config.dart
$cfgPath = Join-Path $root "lib\core\constants\app_config.dart"
$cfg = [System.IO.File]::ReadAllText($cfgPath)
$cfg = $cfg -replace "static const String version = '.*?'", "static const String version = '$Version'"
[System.IO.File]::WriteAllText($cfgPath, $cfg)
Write-Host "  [1/2] app_config.dart -> $Version"

# 2) pubspec.yaml
$pubPath = Join-Path $root "pubspec.yaml"
$pub = [System.IO.File]::ReadAllText($pubPath)
$pub = $pub -replace 'version: \d+\.\d+\.\d+\+\d+', "version: $Version+1"
[System.IO.File]::WriteAllText($pubPath, $pub)
Write-Host "  [2/2] pubspec.yaml    -> $Version+1"

Write-Host ""
Write-Host "  Versiyon $Version olarak guncellendi!"
exit 0
