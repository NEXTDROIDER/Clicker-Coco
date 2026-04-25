@echo off
setlocal

:: --- CONFIGURATION ---
set "INPUT=app\build\outputs\apk\release\app-release-unsigned.apk"
set "ALIGNED=app\build\outputs\apk\release\app-aligned.apk"
set "FINAL=app\build\outputs\apk\release\app-signed.apk"

:: Setting up paths for Android Tools
set "APPDATALOCAL=%LOCALAPPDATA%"
set "PATH=%PATH%;%APPDATALOCAL%\Android\Sdk\emulator;%APPDATALOCAL%\Android\Sdk\platform-tools;%APPDATALOCAL%\Android\Sdk\cmdline-tools\latest\bin"

echo ============================
echo 1. CLEAN + BUILD
echo ============================
call gradlew clean build

if %errorlevel% neq 0 (
    echo [!] BUILD FAILED
    pause
    exit /b %errorlevel%
)

echo ============================
echo 2. ZIPALIGN
echo ============================
if not exist "Tools\zipalign.exe" (
    echo [!] zipalign.exe not found in Tools folder!
    pause
    exit /b 1
)

Tools\zipalign.exe -f -v 4 "%INPUT%" "%ALIGNED%"

if %errorlevel% neq 0 (
    echo [!] ZIPALIGN FAILED
    pause
    exit /b %errorlevel%
)

echo ============================
echo 3. SIGN APK
echo ============================
call java -Xmx1024M -Xss1m -jar "lib\apksigner.jar" sign --ks release.jks --ks-key-alias my-key-alias --ks-pass file:.env --out "%FINAL%" "%ALIGNED%"

if %errorlevel% neq 0 (
    echo [!] SIGNING FAILED
    pause
    exit /b %errorlevel%
)
echo DONE: Signed Apk %FINAL%

echo ============================
echo 4. VERIFY APK
echo ============================
call java -Xmx1024M -Xss1m -jar "lib\apksigner.jar" verify -v --print-certs "%FINAL%"

if %errorlevel% equ 0 (
    echo [OK] VERIFICATION SUCCESSFUL
) else (
    echo [!] VERIFICATION FAILED
    pause
    exit /b %errorlevel%
)

echo ========================================
echo 5. EMULATOR CHECK ^& RUN (API 37)
echo ========================================
set "TARGET_AVD="
for /f "tokens=*" %%a in ('emulator -list-avds') do (
    set "TARGET_AVD=%%a"
    goto :FoundAVD
)

:NoAVD
echo [!] No emulators found. Creating "Medium_Phone_API_37"...
call sdkmanager "system-images;android-37;google_apis;x86_64"
echo no | avdmanager create avd -n "Medium_Phone_API_37" -k "system-images;android-37;google_apis;x86_64" --force
set "TARGET_AVD=Medium_Phone_API_37"

:FoundAVD
echo [*] Target Emulator: %TARGET_AVD%
set /p "START_EMU=Do you want to start emulator and install APK? (y/n): "
if /i "%START_EMU%" neq "y" goto :End

echo [*] Starting %TARGET_AVD%...
start "Emulator" emulator -avd %TARGET_AVD% -no-snapshot-load

echo [*] Waiting for device to connect (Timeout: 120s)...
:: 1. Wait for the adb server to see the device
adb wait-for-device

echo [*] Device detected! Waiting for Android to finish booting...
:: 2. Loop to check if boot is completed (max 120 seconds)
set /a "counter=0"
:BootLoop
set /a "counter+=1"
if %counter% gtr 120 (
    echo [!] ERROR: Boot timeout reached.
    goto :End
)
:: Check sys.boot_completed property
for /f "tokens=*" %%i in ('adb shell getprop sys.boot_completed 2^>nul') do set "booted=%%i"
if "%booted%"=="1" (
    echo [OK] Android is ready!
    goto :Install
)
:: Small delay (1 second) before next check
timeout /t 1 /nobreak >nul
goto :BootLoop

:Install
echo [*] Installing %FINAL%...
adb install -r "%FINAL%"
pause