::
:: This file is part of RigUtils project. Visit https://cryptofarm.wiki/doku.php/windows/rigutils/windows_tuning
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

setlocal EnableDelayedExpansion

set "reg=%windir%\System32\reg.exe"
set "fw=netsh advfirewall"
set "write=<nul set/p="

goto :aaa
::
rem Creating backup of current firewall profile
set "BackupDir=%~dp0firewall.bak"
if not exist "%BackupDir%" (
    echo == Creating backup directory ==
    echo %BackupDir%
    mkdir "%BackupDir%" || goto :exitWithError
    echo.
)

::
if not exist "%BackupDir%\firewall.wfw" (
    echo == Saving current firewall configuration ==
    echo file: %BackupDir%\firewall.wfw
    %fw% export "%BackupDir%\firewall.wfw" || goto :exitWithError    
    
    call :printRestoreHelp
)

echo == Disabling ALL PERMISSIVE inbound rules ==
rem Docs https://docs.microsoft.com/ru-ru/windows/desktop/api/netfw/nn-netfw-inetfwrule
rem https://docs.microsoft.com/ru-ru/windows/desktop/api/icftypes/ne-icftypes-net_fw_action_
powershell -Command "& { $fw=New-object -comObject HNetCfg.FwPolicy2; $fw.rules | where-object { $_.Direction -eq 1 -and $_.Enabled -eq $true -and $_.Action -ne 0 } | tee -Variable rules | ForEach { echo $_.Name; $_.Enabled=0 }; $rc=@($rules).Count; echo ' ' \"$rc firewall rules were disabled\" }" || goto :exitWithError

call :printRestoreHelp

echo == Disabling IPv6 ==
rem https://support.microsoft.com/en-us/help/929852/guidance-for-configuring-ipv6-in-windows-for-advanced-users
set "RegPath=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
set "RegValue=255"

echo RegPath: %RegPath%
echo RegValue: %RegValue%
"%reg%" ADD %RegPath% /v DisabledComponents /t REG_DWORD /d %RegValue% /f || goto :exitWithError
echo.

rem
rem https://soykablog.wordpress.com/2013/04/04/disable-firewall-from-the-command-line/
echo == Configuring firewall policy ==
echo deny ALL INCOMING connections with NO MATCHING rules and allow ALL OUTGOING connections
%fw% set allprofiles firewallpolicy blockinbound,allowoutbound || goto :exitWithError

echo To re-enable ALL INCOMING connections by default run the following command: 
echo   netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound

::
echo == Creating explicit BLOCK rules for known Windows services ==
rem Use the command to delete created rules
rem netsh advfirewall firewall delete rule protocol=<tcp|udp> localport=<port_number> name="<Rule name>"

rem General info https://serverfault.com/questions/859817/windows-firewall-rpc-135
rem https://www.speedguide.net/port.php?port=135
call :inboundRule block TCP 135 "Windows RPC" || goto :exitWithError
call :inboundRule block UDP 135 "Windows RPC" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=593
call :inboundRule block TCP 593 "Windows RPC" || goto :exitWithError
call :inboundRule block UDP 593 "Windows RPC" || goto :exitWithError

rem http://techgenix.com/windowsdeploymentservicesandfirewalls/
call :inboundRule block TCP 5040 "Windows RPC" || goto :exitWithError

rem https://answers.microsoft.com/es-es/windows/forum/windows_other-winapps/widnows-server-mitigar-vulnerabilidad-dcerpc-and/5ab3f7b2-eaf5-4168-a103-3442e323b7a2
rem https://alamot.github.io/tally_writeup/
call :inboundRule block TCP 49664-49675 "Windows RPC" || goto :exitWithError
call :inboundRule block UDP 49664-49675 "Windows RPC" || goto :exitWithError

rem Please note that by disabling NETBIOS ports you will be not able to share folders or disks from your computer any more. 
rem https://www.speedguide.net/port.php?port=137
call :inboundRule block TCP 137 "NetBIOS Name Service" || goto :exitWithError
call :inboundRule block UDP 137 "NetBIOS Name Service" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=138
call :inboundRule block TCP 138 "NetBIOS Datagram Service" || goto :exitWithError
call :inboundRule block UDP 138 "NetBIOS Datagram Service" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=139
call :inboundRule block TCP 139 "NetBIOS Session Service" || goto :exitWithError
call :inboundRule block UDP 139 "NetBIOS Session Service" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=445
call :inboundRule block TCP 445 "TCP NetBIOS helper" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=5000
call :inboundRule block TCP 5000 "UPnP Service" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=5353
call :inboundRule block UDP 5353 "DNSCache Service" || goto :exitWithError
call :inboundRule block UDP 5355 "DNSCache Service" || goto :exitWithError

rem https://www.speedguide.net/port.php?port=7680
call :inboundRule block TCP 7680 "Windows Update Delivery Optimization" || goto :exitWithError
call :inboundRule block UDP 7680 "Windows Update Delivery Optimization" || goto :exitWithError

echo.
echo Use the command to delete a created rule if you want to unblock a port:
echo   netsh advfirewall firewall delete rule protocol=^<tcp^|udp^> localport=^<port^> name="<rule>"

::
echo == Allow individual services ==
rem Allow Web GUI for accessing miners monitoring page
::

set /p allowWebGUI=Would you like to use your miner's Web GUI^? If 'yes' press 1: || set "allowWebGUI=0"

if /i "y" == "%allowWebGUI%" set "allowWebGUI=1"
if "1" == "%allowWebGUI%" (
    set /p webGUIPort=Enter a Web GUI port number or 0 to cancel: || set "webGUIPort=0"
    
    rem Validating input
    set /a "portNumber=!webGUIPort!"
    if "!portNumber!" neq "!webGUIPort!" set /a portNumber=0
    
    if "0" == "!portNumber!" (
        echo operation canceled
    ) else (
        call :inboundRule allow TCP !webGUIPort! "Miner Web GUI" || goto :exitWithError
    )
    
    echo.
)

::
rem Open Hardware Monitor TCP port 8085
rem https://openhardwaremonitor.org
::
set /p allowOHMWebGUI=Would you like to use "Open Hardware Monitor" Web GUI? If 'yes' press 1: || set "allowOHMWebGUI=0"

if /i "y" == "%allowOHMWebGUI%" set "allowOHMWebGUI=1"
if "1" == "%allowOHMWebGUI%" (
    call :inboundRule allow TCP 8085 "Open Hardware Monitor Web GUI" || goto :exitWithError
)

::
rem Remote Desktop Protocol
::
set /p allowRDP=Would you like to use Remote Desktop on your PC? If 'yes' press 1: || set "allowRDP=0"

if /i "y" == "%allowRDP%" set "allowRDP=1"
if "1" == "%allowRDP%" (
    call :allowRDP
) else (
    call :inboundRule block TCP 3389 "Windows Remote Desktop - RDP" || goto :exitWithError
)

call :printRestoreHelp
echo Don't forget to restart your computer to changes take effect

exit /b 0

::
rem printRestoreHelp
:: 
:printRestoreHelp
    echo.
    echo For restoring of your original firewall configuration use the command:
    echo   %fw% import %BackupDir%\firewall.wfw
    echo or the following command if you want to restore default Windows settings:
    echo   %fw% reset 
    echo.
exit /b
    
::
rem exitWithError
::
:exitWithError
    echo.
    echo Some error occurred^!
    echo Unable to configure firewall.
exit /b 1

::
rem allowRDP
::
:allowRDP
    set "rdpPort=3389"
    
    set /p changeRDPort=Would you like to change default RDP port-%rdpPort% ^(recomended^)? If 'yes' press 1: || exit /b 0
    
    if /i "y" == "%changeRDPort%" set "changeRDPort=1"
    if "1" == "%changeRDPort%" (
        set /p rdpPort=Enter RDP port number or 0 to cancel: || exit /b 0
    
        rem Validating input
        set /a "portNumber=!rdpPort!"
        if "!portNumber!" neq "!rdpPort!" set /a rdpPort=0
    ) 

    if "0" == "!rdpPort!" (
        echo action canceled
        exit /b 0
    )    
    
    call :inboundRule allow TCP !rdpPort! "Windows RDP" || goto :exitWithError
    call :inboundRule allow UDP !rdpPort! "Windows RDP" || goto :exitWithError
        
    echo updating RDP port number in registry
    "%reg%" ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d !rdpPort! /f || goto :exitWithError       
    
    echo restarting RDP service to changes take effect
    powershell -Command "Restart-Service -Force -Verbose TermService"

exit /b 0

::
rem inboundRule
::
:inboundRule 
    set "action=%~1"
    set "proto=%~2"
    set "port=%~3"
    set "serviceName=%~4"
    set "ruleName=[%action%] %serviceName% %proto%-%port%"
    
    rem Select enabled inbound rule with the given name
    powershell -Command "& { try { $fw=New-object -comObject HNetCfg.FwPolicy2; $fw.rules | where-object { $_.Direction -eq 1 -and $_.Name -eq '%ruleName%' } | ForEach { exit 1 }; exit 0 } catch { write-host "\"Exception Message: $($_.Exception.Message)\"" -ForegroundColor Red; exit 2 } }"
    
    if ERRORLEVEL 2 exit /b 1 rem ERROR
    if ERRORLEVEL 1 exit /b 0 rem echo Already exists

    rem echo NOT FOUND
    %write% %proto%: %port%, rule: %ruleName%...
    %fw% firewall add rule dir=in action=%action% protocol=%proto% localport=%port% name="%ruleName%" >nul || exit /b 1
    echo OK
exit /b 0

