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

set "reg=%windir%\System32\reg.exe"
set "write=<nul set/p=:"
set "HCU_CurrentVersion=HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion"
set "HCU_Explorer=%HCU_CurrentVersion%\Explorer"

call "%~dp0\QuickLaunch\QuickLaunch.bat"

::
rem More user interface settings could be found here - https://ss64.com/nt/syntax-reghacks.html
rem Adjust settings to your taste.
::

echo == Tweking interface settings in registry ==
%write% Don't hide drive letters in file explorer...
"%reg%" ADD %HCU_CurrentVersion%\Policies\Explorer /v NoDrives /t REG_DWORD /d 0 /f >nul && echo OK

%write% Never combine Taskbar icons...
"%reg%" ADD %HCU_Explorer%\Advanced /v TaskbarGlomLevel /t REG_DWORD /d 2 /f >nul && echo OK

%write% No Glomming (keep every icon on the taskbar separate)...
"%reg%" ADD %HCU_Explorer% /v TaskbarGlomming /t REG_DWORD /d 0 /f >nul && echo OK

%write% Use small Icons on taskbar...
"%reg%" ADD %HCU_Explorer%\Advanced /v TaskbarSmallIcons /t REG_DWORD /d 1 /f >nul && echo OK

%write% Hide TaskView button...
"%reg%" ADD %HCU_Explorer%\Advanced /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul && echo OK

%write% Hide SearchIcon...
"%reg%" ADD %HCU_CurrentVersion%\Search /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul && echo OK

REM %write% Unpin FileExplorer from taskbar
REM del /q /s /f "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk" >nul 2>&1
rem >nul 2>&1

rem https://www.tenforums.com/tutorials/3151-reset-clear-taskbar-pinned-apps-windows-10-a.html
%write% Unpin all icons from Taskbar...
del /q /s /f "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned" >nul 2>&1
"%reg%" QUERY %HCU_Explorer%\Taskband >nul 2>&1 && "%reg%" DELETE %HCU_Explorer%\Taskband /F >nul
echo OK

%write% Remove store apps from taskbar...
"%reg%" ADD %HCU_Explorer%\Advanced /v StoreAppsOnTaskbar /t REG_DWORD /d 0 /f >nul && echo OK

rem https://serverfault.com/questions/268423/changing-desktop-solid-color-via-registry
%write% Desktop color, you have to logout/login or just restart (may be performed later)...
"%reg%" ADD "HKEY_CURRENT_USER\Control Panel\Colors" /v Background /t REG_SZ /d "0 99 177" /f >nul 
"%reg%" ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallPaper /t REG_SZ /d "" /f >nul && echo OK
REM "%reg%" ADD %HCU_Explorer%\Wallpapers /v BackgroundType /t REG_DWORD /d 1 /f

rem https://www.intowindows.com/how-to-open-file-explorer-to-this-pc-by-default-in-windows-10/
%write% Show "This PC" by default in file explorer...
"%reg%" ADD %HCU_Explorer%\Advanced /v LaunchTo /t REG_DWORD /d 1 /f >nul && echo OK

%write% Hide PeopleBand...
"%reg%" ADD %HCU_Explorer%\Advanced\People /v PeopleBand /t REG_DWORD /d 0 /f >nul && echo OK

%write% Remove the OneDrive icon...
"%reg%" ADD HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6} /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f >nul
"%reg%" ADD HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6} /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f >nul && echo OK

%write% Show hidden files and folders in file explorer...
"%reg%" ADD %HCU_Explorer%\Advanced /v Hidden /t REG_DWORD /d 1 /f >nul && echo OK

%write% Don't hide file extensions in file explorer...
"%reg%" ADD %HCU_Explorer%\Advanced /v HideFileExt /t REG_DWORD /d 0 /f >nul && echo OK

%write% System Tray - show all icons...
"%reg%" ADD HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer /v EnableAutoTray /t REG_DWORD /d 0 /f >nul && echo OK

rem Credits: https://www.windowscentral.com/how-disable-taskbar-thumbnail-preview-windows-10
%write% Disable taskbar thumbnail preview...
"%reg%" ADD %HCU_Explorer%\Advanced /v ExtendedUIHoverTime /t REG_DWORD /d 3000 /f >nul && echo OK

echo.
echo UI Tweking done