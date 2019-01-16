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

rem Credits
rem https://github.com/vFense/vFenseAgent-win/wiki/Registry-keys-for-configuring-Automatic-Updates-&-WSUS
rem https://www.windowscentral.com/how-stop-updates-installing-automatically-windows-10

rem Creating registry entries
set "WU_KEY=HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
set "AU_KEY=%WU_KEY%\AU"

"%reg%" ADD %WU_KEY% /f
"%reg%" ADD %AU_KEY% /f

rem 5 = Automatic Updates is required and users can configure it.
"%reg%" ADD %AU_KEY% /v AUOptions /t REG_DWORD /d 5 /f

rem 1 = Disable Automatic Updates.
"%reg%" ADD %AU_KEY% /v NoAutoUpdate /t REG_DWORD /d 1 /f

rem 1 = The computer gets its updates from a WSUS server. We are providing fake address for it
"%reg%" ADD %AU_KEY% /v UseWUServer /t REG_DWORD /d 1 /f

rem Fake address for WindowsUpdate service
"%reg%" ADD %WU_KEY% /v WUServer /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD %WU_KEY% /v WUStatusServer /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD %WU_KEY% /v UpdateServiceUrlAlternate /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD %WU_KEY% /v FillEmptyContentUrls /t REG_DWORD /d 1 /f

rem Telling WindowsUpdate never call home
"%reg%" ADD %WU_KEY% /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f

rem Never try to update device drivers via WindowsUpdate
"%reg%" ADD %WU_KEY% /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f

rem Stopping and disabling WindowsUpdate related services

rem Update Orchestrator Service
sc stop UsoSvc >nul 2>&1
sc config UsoSvc start=disabled >nul 2>&1

rem WindowsUpdate
sc stop wuauserv >nul 2>&1
sc config wuauserv start=disabled >nul 2>&1

rem WindowsUpdate Medic Service
sc stop WaaSMedicSvc >nul 2>&1
sc config WaaSMedicSvc start=disabled >nul 2>&1

timeout /t 20