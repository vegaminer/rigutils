@echo off

pushd "%~dp0"

echo == Creating QuickLaunch task bar
regedit /s QuickLaunch.reg && echo OK

echo == Creating shortcuts at quicklaunch bar

echo   ComputerManagement
call lnkComputerManagement.bat

echo   DeviceManagement
call lnkDeviceManagement.bat

echo   Rigutils command prompt
call lnkRigutilsCmd.bat

popd
