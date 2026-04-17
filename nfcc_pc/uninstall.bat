@echo off
REM NFCC — remove autostart entry and kill the running app.

echo Stopping NFCC (if running)...
taskkill /IM NFCC.exe /F >nul 2>&1

echo Removing autostart entry...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "NFCC" /f >nul 2>&1

echo Done. The exe at dist\NFCC.exe has NOT been deleted.
echo Delete it manually if you want to remove it completely.
