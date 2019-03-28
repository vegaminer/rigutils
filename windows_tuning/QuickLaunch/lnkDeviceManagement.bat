@set @x=0 /*
@echo off

cscript /NOLOGO /e:javascript %~s0
exit /b

*/

var 
    wsh = WScript.CreateObject( 'WScript.Shell' ),
    windir = wsh.ExpandEnvironmentStrings( '%windir%' ),
    system32 = windir + '\\system32',

    hotkey = 'CTRL+SHIFT+ALT+D', // NOTE: Shortcut keys do not work for items on the Quick Launch bar.
    lnkName = 'Device Management',    
    arguments = '',    
    targetPath =  system32 + '\\devmgmt.msc',
    lnkLocation = wsh.ExpandEnvironmentStrings( '%APPDATA%' ) + '\\Microsoft\\Internet Explorer\\Quick Launch',

    // CreateShortcut - https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/windows-scripting/f5y78918(v%3dvs.84)
    oShellLink = wsh.CreateShortcut( lnkLocation + '\\' + lnkName + '.lnk' )
;

oShellLink.Hotkey = hotkey;    
oShellLink.Arguments = arguments;
oShellLink.TargetPath = targetPath;
oShellLink.WindowStyle = 3;
oShellLink.Description = lnkName;
oShellLink.IconLocation = system32 + '\\devmgr.dll, 5';

oShellLink.Save();
