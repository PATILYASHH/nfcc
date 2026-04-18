@echo off
REM  NFCC-PC CLI wrapper.
REM
REM  Add this folder to your PATH and you can just type "NFCC-PC" from
REM  any terminal, any directory.
REM
REM  Examples:
REM     NFCC-PC                             (= NFCC-PC serve — tray service)
REM     NFCC-PC status
REM     NFCC-PC pair
REM     NFCC-PC dashboard
REM     NFCC-PC reconnect
REM     NFCC-PC forward                     (UPnP — open router port)
REM     NFCC-PC unforward
REM     NFCC-PC action lockPc
REM     NFCC-PC action launchApp --params "{\"name\":\"notepad\"}"

cd /d "%~dp0"
python main.py %*
