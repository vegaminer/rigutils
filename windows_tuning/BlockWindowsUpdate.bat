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
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /f

rem 5 = Automatic Updates is required and users can configure it.
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v AUOptions /t REG_DWORD /d 5 /f

rem 1 = Disable Automatic Updates.
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f

rem 1 = The computer gets its updates from a WSUS server. We are providing fake address for it
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v UseWUServer /t REG_DWORD /d 1 /f

rem Fake address for WindowsUpdate service
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUServer /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUStatusServer /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v UpdateServiceUrlAlternate /t REG_SZ /d "http://127.0.0.2" /f
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v FillEmptyContentUrls /t REG_DWORD /d 1 /f

rem Telling WU never call home
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f

rem Never try to update device drivers via WU
"%reg%" ADD HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f

rem Stopping and disabling Windows Update related services

rem Update Orchestrator Service
sc stop UsoSvc >nul 2>&1
sc config UsoSvc start=disabled >nul 2>&1

rem Windows Update
sc stop wuauserv >nul 2>&1
sc config wuauserv start=disabled >nul 2>&1

rem Windows Update Medic Service
sc stop WaaSMedicSvc >nul 2>&1
sc config WaaSMedicSvc start=disabled >nul 2>&1

timeout /t 20