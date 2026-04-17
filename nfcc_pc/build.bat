@echo off
REM NFCC PC companion — one-shot build script.
REM Produces dist\NFCC.exe (single file, no console, system tray).

setlocal
cd /d "%~dp0"

echo.
echo [1/3] Installing / updating dependencies...
python -m pip install --upgrade pip >nul
python -m pip install -r requirements.txt || goto :err

echo.
echo [2/3] Cleaning previous build...
if exist build rmdir /s /q build
if exist dist  rmdir /s /q dist

echo.
echo [3/3] Building NFCC.exe with PyInstaller...
python -m PyInstaller nfcc.spec --noconfirm || goto :err

echo.
echo ======================================================
echo Build complete.
echo   EXE:  %cd%\dist\NFCC.exe
echo ======================================================
echo.
echo Next steps:
echo   - Double-click dist\NFCC.exe to run the tray app.
echo   - Run install.bat to enable autostart on login.
echo.
exit /b 0

:err
echo.
echo Build FAILED. See error above.
exit /b 1
