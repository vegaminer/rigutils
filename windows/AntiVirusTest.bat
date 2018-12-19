::
:: This file is part of RigUtils project. Visit https://cryptofarm.wiki/doku.php/windows/rigutils
::
@echo off

set "self=%~s0"
set "avtest=%~dp0\avtest.txt"
set "mshta=%~dp0\ms_hta.exe"

whoami /groups | findstr "S-1-16-12288" >nul 2>&1 || (
    echo %date% > "%avtest%"
    echo Attempt to create elevated environment...
    
    rem Find full file name of mshta.exe and create a copy with name ms_hta.exe in working directory
    for /f "usebackq delims=" %%a in ( `where mshta.exe` ) do copy /y "%%a" "%mshta%" >nul
    if not exist "%mshta%" (
        echo Unable to copy mshta.exe
        exit /b 1
    )
    
    "%mshta%" "javascript: var shell = new ActiveXObject( 'shell.application' ); shell.ShellExecute( '%self:\=\\%', '', '', 'runas', 1 ); close();"
    timeout /t 3 
    
    if not exist "%avtest%" (
        echo Success!
    ) else (
        echo Failed...
        echo Looks like Windows Defender blocks the script. Please visit https://cryptofarm.wiki/windows/tuning/antivirustest
    )
    
    del /q /f "%avtest%" >nul 2>&1 
    exit /b    
)

del /q /f "%avtest%" >nul 2>&1 

title AVTEST
"%mshta%" "javascript: alert( 'Hello, this is admin speaking!' ); close();"
