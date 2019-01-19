::
:: This file is part of RigUtils project. Visit https://cryptofarm.wiki/doku.php/windows/rigutils
::
@echo off

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

set "reg=%windir%\System32\reg.exe"
set "write=<nul set/p="

rem Credits
rem https://github.com/vFense/vFenseAgent-win/wiki/Registry-keys-for-configuring-Automatic-Updates-&-WSUS
rem https://www.windowscentral.com/how-stop-updates-installing-automatically-windows-10

echo == Creating registry entries ==

set "WU_KEY=HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
set "AU_KEY=%WU_KEY%\AU"

echo %WU_KEY%
"%reg%" ADD %WU_KEY% /f || exit /b 1

echo %AU_KEY%
"%reg%" ADD %AU_KEY% /f || exit /b 1

echo. && echo == Configuring WindowsUpdate Options ==
echo Let admin to configure WindowsUpdate,
echo automatic Updates is required and users can configure it
%write% :AUOptions = 5: 
"%reg%" ADD %AU_KEY% /v AUOptions /t REG_DWORD /d 5 /f || exit /b 1

echo. && echo disabling Automatic Updates -
%write% :NoAutoUpdate = 1: 
"%reg%" ADD %AU_KEY% /v NoAutoUpdate /t REG_DWORD /d 1 /f || exit /b 1

echo. && echo the computer gets updates from a WSUS server -
%write% :UseWUServer = 1: 
"%reg%" ADD %AU_KEY% /v UseWUServer /t REG_DWORD /d 1 /f || exit /b 1

echo. && echo set fake address for WindowsUpdate service -
%write% :WUServer = http://127.0.0.2: 
"%reg%" ADD %WU_KEY% /v WUServer /t REG_SZ /d "http://127.0.0.2" /f || exit /b 1

%write% :WUStatusServer = http://127.0.0.2: 
"%reg%" ADD %WU_KEY% /v WUStatusServer /t REG_SZ /d "http://127.0.0.2" /f || exit /b 1

%write% :UpdateServiceUrlAlternate = http://127.0.0.2: 
"%reg%" ADD %WU_KEY% /v UpdateServiceUrlAlternate /t REG_SZ /d "http://127.0.0.2" /f || exit /b 1

%write% :FillEmptyContentUrls = 1: 
"%reg%" ADD %WU_KEY% /v FillEmptyContentUrls /t REG_DWORD /d 1 /f || exit /b 1

echo. && echo telling WindowsUpdate never call home
%write% :DoNotConnectToWindowsUpdateInternetLocations = 1: 
"%reg%" ADD %WU_KEY% /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f || exit /b 1

echo. && echo never try to update device drivers via WindowsUpdate
%write% :ExcludeWUDriversInQualityUpdate = 1: 
"%reg%" ADD %WU_KEY% /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f  || exit /b 1

echo. && echo == Stopping and disabling WindowsUpdate related services ==

echo Update Orchestrator Service
sc stop UsoSvc >nul 2>&1
sc config UsoSvc start=disabled >nul 2>&1

echo Windows Update Service
sc stop wuauserv >nul 2>&1
sc config wuauserv start=disabled >nul 2>&1

echo Windows Update Medic Service
sc stop WaaSMedicSvc >nul 2>&1
sc config WaaSMedicSvc start=disabled >nul 2>&1

REM timeout /t 20