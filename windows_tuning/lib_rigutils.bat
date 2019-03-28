@echo off

setlocal EnableDelayedExpansion

rem
rem getOEMCodePage <action> 
rem action : set|print (default)
rem 
:getOEMCodePage 
setlocal
    set "action=%~2" 
    if "" == "%action%" set "action=print"
    
	chcp 437 >nul 2>&1 

	for /f "usebackq tokens=1 delims=-" %%a in ( `powershell -Command "& { Get-WinSystemLocale } | select Name" ^| findstr /v /c:"Name" /c:"----"` ) do (
        set "locale=%%a"
        rem echo SystemLocale=!locale!
    )
    
    rem See full list of codepages here https://docs.microsoft.com/en-us/windows/desktop/intl/code-page-identifiers (you need version for OEM DOS )
    rem and here https://www.science.co.il/language/Locale-codes.php
    
    set "__oem_437=en"
    rem 1250-WINDOWS, 852-DOS OEM Latin 2; Central European 
    set "__oem_852=sq,hr,cs,hu,pl,ro,sk,sl"
    rem 1251-WINDOWS, 866-DOS OEM Russian; Cyrillic 
    set "__oem_866=be,bg,mk,kk,mn,ru,sr,tt,uk" 
    rem 1252-WINDOWS, 850-DOS OEM Multilingual Latin 1; Western European 
    set "__oem_850=af,eu,ca,da,nl,fo,fi,fr,gl,de,is,id,it,ms,nb,nn,no,pt,es,sv,se"
    rem 1253-WINDOWS, 869-DOS OEM Modern Greek; Greek, Modern 
    set "__oem_869=el"
    rem 1254-WINDOWS, 857-DOS OEM Turkish; Turkish
    set "__oem_857=tr,uz"
    rem 1255-WINDOW, 862-DOS OEM Hebrew; Hebrew
    set "__oem_862=he"
    rem 1256-WINDOWS, 864-DOS OEM Arabic; Arabic (864)
    set "__oem_864=ar,fa"
    rem 1257-WINDOWS, 775-DOS OEM Baltic; Baltic
    set "__oem_775=et,lv,lt"
    rem 1258 ANSI/OEM Vietnamese; Vietnamese (Windows)
    set "__oem_1258=vi"
    
	for /f "usebackq tokens=1,2 delims=_=" %%a in ( `set ^| findstr __oem_` ) do (
		set "codePage=%%b"
		
		call set languages=%%__oem_!codePage!%%
		set "test=languages:!locale!=_" && call set "test=%%!test!%%"
		if "!test!" neq "!languages!" ( 
			rem echo OEMCodePage=!codePage!
            REM chcp !codePage!
            if "set" == "%action%" (
                chcp !codePage! >nul
            ) else (
                echo !codePage!
            )
            
            exit /b
		)
	)

exit /b