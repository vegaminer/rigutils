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

pushd "%~dp0"

echo Credits https://github.com/crazy-max/WindowsSpyBlocker

set "hostsFile=%windir%\System32\drivers\etc\hosts"
set "dataUrl=https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts"

echo.
echo updating %hostsFile%
echo from %dataUrl%

type "%hostsFile%" | findstr /V /C:"WindowsShutup" > hosts.txt
echo # [%date% %time%] WindowsShutup >> hosts.txt

echo.
call :downloadFile update.txt || goto :exitWithError
call :downloadFile spy.txt || goto :exitWithError
call :downloadFile extra.txt || goto :exitWithError

type hosts.txt > "%hostsFile%"

echo flushing DNS cache
ipconfig /flushdns

echo. 
echo Success^!
echo File %hostsFile% was updated

REM timeout /t 20

exit /b

rem
rem downloadFile
rem
:downloadFile
	set "file=%~1"
    del /q /s /f "%file%" >nul 2>&1
    
    echo Downloading file %file%
	powershell -Command "& { Invoke-WebRequest -Uri %dataUrl%/%file% -OutFile %file% }"
	if not exist "%file%" (
        echo Error downloading %file%
        exit /b 1
    )
    
    rem Adding # WindowsShutup to each entry
	for /f "usebackq delims=" %%s in ( `type ^"%file%^"` ) do ( echo %%s # WindowsShutup >> hosts.txt )
	
	del /q /s /f "%file%" >nul 2>&1
exit /b 0

rem
rem exitWithError
rem
:exitWithError
    echo.
    echo Some error occurred^!
    echo Unable to block Windows Telemetry Service.
exit /b 1
                              