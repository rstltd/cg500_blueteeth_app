@echo off
REM CG500 BLE App Release Build Script
REM This script automates the APK build process for production

echo ========================================
echo CG500 BLE App Release Build
echo ========================================
echo.

REM Check if Flutter is available
flutter --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and try again
    pause
    exit /b 1
)

echo [1/6] Cleaning previous build...
flutter clean
if %errorlevel% neq 0 goto :error

echo.
echo [2/6] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 goto :error

echo.
echo [3/6] Running static analysis...
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Static analysis found issues
    echo Continue anyway? (y/n)
    set /p continue=
    if /i "%continue%" neq "y" exit /b 1
)

echo.
echo [4/6] Running tests...
flutter test
if %errorlevel% neq 0 (
    echo WARNING: Tests failed
    echo Continue anyway? (y/n)
    set /p continue=
    if /i "%continue%" neq "y" exit /b 1
)

echo.
echo [5/6] Building release APK...
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
if %errorlevel% neq 0 goto :error

echo.
echo [6/6] Build completed successfully!
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo File size:
for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do echo %%~zA bytes

echo.
echo ========================================
echo Build completed successfully!
echo ========================================

REM Ask if user wants to open the APK location
echo.
echo Open APK folder? (y/n)
set /p open_folder=
if /i "%open_folder%"=="y" (
    explorer "build\app\outputs\flutter-apk\"
)

pause
exit /b 0

:error
echo.
echo ========================================
echo Build failed!
echo ========================================
pause
exit /b 1