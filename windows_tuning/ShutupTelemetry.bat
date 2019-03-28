::
:: This file is part of RigUtils project. Visit https://cryptofarm.wiki/doku.php/windows/rigutils/windows_tuning
::
@echo off

setlocal EnableDelayedExpansion

:: This script has to be run with Admin rights, elevating if necessary.
set "self=%~s0"
whoami /groups | findstr "S-1-16-12288" >nul 2>&1 || (
    rem More info can be found here https://cryptofarm.wiki/doku.php/windows/rigutils/windows_tuning/antivirustest.bat
    echo If Windows Defender blocks the script telling that this is a virus then visit the page
    echo https://cryptofarm.wiki/doku.php/windows/rigutils/windows_tuning/antivirustest.bat
    
    set "mshta=%~dp0\ms_hta.exe"
    for /f "usebackq delims=" %%a in ( `where mshta.exe` ) do copy /y "%%a" "%mshta%" >nul
    if not exist "%mshta%" (
        echo Unable to copy mshta.exe
        exit /b 1
    )
    
    "%mshta%" "javascript: var shell = new ActiveXObject( 'shell.application' ); shell.ShellExecute( '%self:\=\\%', '', '', 'runas', 1 ); close();"
    exit /b
)

echo Credits https://github.com/crazy-max/WindowsSpyBlocker
echo.

set "hostsFile=%windir%\System32\drivers\etc\hosts"
set "dataUrl=https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts"

set "BackupDir=%~dp0ShutupTelemetry"
if not exist "%BackupDir%" (
    echo == Creating backup directory ==
    echo   %BackupDir%
    mkdir "%BackupDir%" || goto :exitWithError
    echo.
)

pushd "%BackupDir%"

echo == Creating bakup of current hosts file ==
echo   src: %hostsFile%
echo   bak: %BackupDir%\hosts.bak
copy /y hosts.bak.1 hosts.bak.2 2>&1 >nul
copy /y hosts.bak.0 hosts.bak.1 2>&1 >nul
copy /y hosts.bak hosts.bak.0 2>&1 >nul
copy /y "%hostsFile%" hosts.bak >nul || goto :exitWithError

echo == Updating hosts file ==
echo   src: %dataUrl%
echo   dst: %hostsFile%

echo   removing old WindowsShutup entries if any
type "%hostsFile%" | findstr /V /C:"WindowsShutup" > hosts.txt
echo. >> hosts.txt
echo # [%date% %time%] WindowsShutup >> hosts.txt

echo   adding new entries from github:
call :downloadFile update.txt || goto :exitWithError
call :downloadFile spy.txt || goto :exitWithError
call :downloadFile extra.txt || goto :exitWithError

rem answers.microsoft.com could be helpful ;)
type hosts.txt | findstr /V /C:"answers" > "%hostsFile%"

echo == Flushing DNS cache ==
ipconfig /flushdns >nul || goto :exitWithError

echo. 
echo Success^!
echo File %hostsFile% was updated

REM timeout /t 20
popd

exit /b

rem
rem downloadFile
rem
:downloadFile
	set "file=%~1"
    del /q /s /f "%file%" >nul 2>&1
    
    echo     %file%
	powershell -Command "& { Invoke-WebRequest -Uri %dataUrl%/%file% -OutFile %file% }"
	if not exist "%file%" (
        echo Error downloading %file%
        exit /b 1
    )
    
    rem Adding # WindowsShutup to each entry
    echo. >> hosts.txt
    echo # %file% WindowsShutup >> hosts.txt
	for /f "usebackq delims=" %%s in ( `type ^"%file%^"` ) do ( echo %%s # WindowsShutup >> hosts.txt )
	
	REM del /q /s /f "%file%" >nul 2>&1
exit /b 0

rem
rem exitWithError
rem
:exitWithError
    echo.
    echo Some error occurred^!
    echo Unable to block Windows Telemetry Service.
    popd
exit /b 1
                              