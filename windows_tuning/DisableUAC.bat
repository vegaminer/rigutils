::
:: This file is part of RigUtils project. Visit https://cryptofarm.wiki/doku.php/windows/rigutils
::
@echo off

:: This script has to be run with Admin rights, elevating if necessary.
:: https://stackoverflow.com/questions/7044985/how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-administrator
set "self=%~s0"
whoami /groups | findstr "S-1-16-12288" >nul 2>&1 || (

    set "mshta=%~dp0\ms_hta.exe"
    for /f "usebackq delims=" %%a in ( `where mshta.exe` ) do copy /y "%%a" "%mshta%" >nul
    if not exist "%mshta%" (
        echo Unable to copy mshta.exe
        exit /b 1
    )
    
    "%mshta%" "javascript: var shell = new ActiveXObject( 'shell.application' ); shell.ShellExecute( '%self:\=\\%', '', '', 'runas', 1 ); close();"
    exit /b    
)

rem Credits https://www.howtogeek.com/howto/windows-vista/enable-or-disable-uac-from-the-windows-vista-command-line/
rem Disabling UAC
%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

rem Rebooting PC
echo Reboot required!
set /P reboot=Press 1 for automatic reboot now, 0 for manual reboot:
if "1" == "%reboot%" (
    shutdown.exe /r /f /t 5
)
