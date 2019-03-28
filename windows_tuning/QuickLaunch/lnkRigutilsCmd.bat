@set @x=0 /*
@echo off

set "RIGUTILS_DIR=%~dp0"

cscript /NOLOGO /e:javascript %~s0
exit /b

*/

var 
    wsh = WScript.CreateObject( 'WScript.Shell' ),
    windir = wsh.ExpandEnvironmentStrings( '%windir%' ),
    system32 = windir + '\\system32',
    RIGUTILS_DIR = wsh.ExpandEnvironmentStrings( '%RIGUTILS_DIR%' ),
    
    hotkey = 'CTRL+SHIFT+ALT+A', // NOTE: Shortcut keys do not work for items on the Quick Launch bar.
    lnkName = 'Rigutils command prompt',
    arguments = '',
    targetPath =  RIGUTILS_DIR + 'admin_cmd.bat',    
    lnkLocation = wsh.ExpandEnvironmentStrings( '%APPDATA%' ) + '\\Microsoft\\Internet Explorer\\Quick Launch',
    
    // CreateShortcut - https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/windows-scripting/f5y78918(v%3dvs.84)
    oShellLink = wsh.CreateShortcut( lnkLocation + '\\' + lnkName + '.lnk' )
;

oShellLink.Hotkey = hotkey; 
oShellLink.Arguments = arguments;
oShellLink.TargetPath = targetPath;
oShellLink.WindowStyle = 1;
oShellLink.Description = lnkName;
oShellLink.IconLocation = system32 + '\\cmd.exe, 0';
oShellLink.WorkingDirectory = RIGUTILS_DIR;

oShellLink.Save();
