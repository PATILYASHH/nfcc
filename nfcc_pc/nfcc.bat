@echo off
REM Friendly `nfcc` CLI wrapper.
REM Add this folder to your PATH and you can run:
REM    nfcc              (= nfcc serve)
REM    nfcc status
REM    nfcc pair
REM    nfcc dashboard
REM    nfcc action lockPc
REM    nfcc action launchApp --params "{\"name\":\"notepad\"}"

cd /d "%~dp0"
python main.py %*
