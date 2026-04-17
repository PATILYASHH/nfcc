@echo off
REM NFCC — register the exe for autostart on login.
REM Run AFTER build.bat so dist\NFCC.exe exists.

setlocal
cd /d "%~dp0"

set "EXE=%cd%\dist\NFCC.exe"
if not exist "%EXE%" (
    echo NFCC.exe not found at %EXE%
    echo Run build.bat first.
    exit /b 1
)

echo Registering NFCC for autostart at login...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "NFCC" /t REG_SZ /d "\"%EXE%\"" /f >nul
if errorlevel 1 (
    echo Failed to write registry key.
    exit /b 1
)

echo.
echo Installed. NFCC will launch next time you sign in.
echo Starting it now...
start "" "%EXE%"
echo Done. Look for the NFCC icon in your system tray.
