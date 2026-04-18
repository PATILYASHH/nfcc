@echo off
REM Launch NFCC PC companion detached from any terminal.
REM pythonw.exe has no console window, so closing the cmd prompt that
REM kicked this off will NOT stop the service — the tray icon is what
REM keeps it alive, and only Quit from the tray kills the process.

REM Run from this script's own directory so relative imports resolve.
cd /d "%~dp0"

start "" /B pythonw.exe main.py serve
exit /b 0
