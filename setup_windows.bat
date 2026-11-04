@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
    echo Flutter was not found on PATH. Install Flutter or add its bin folder to PATH.
    exit /b 1
)

echo Creating the Windows desktop runner...
flutter create --platforms=windows .
if errorlevel 1 exit /b %errorlevel%

echo Resolving Dart and Flutter packages...
flutter pub get
if errorlevel 1 exit /b %errorlevel%

echo Running Pocket Ledger on Windows...
flutter run -d windows
