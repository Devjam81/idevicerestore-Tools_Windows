@Echo off

Title IPSW Downloader
Color 5F             



:Download
title Choice Firmware...
CALL :log Opening IPSW downloader...

cls
Color 5F
Echo.
Echo d8b   8888888b.                              888                     888
Echo Y8P   888  "Y88b                             888                     888
Echo       888    888                             888                     888
Echo 888   888    888 .d88b. 888  888  88888888b. 888 .d88b.  8888b.  .d88888
Echo 888   888    888d88""88b888  888  888888 "88b888d88""88b    "88bd88" 888
Echo 888   888    888888  888888  888  888888  888888888  888.d888888888  888
Echo 888   888  .d88PY88..88PY88b 888 d88P888  888888Y88..88P888  888Y88b 888
Echo 888   8888888P"  "Y88P"  "Y8888888P" 888  888888 "Y88P" "Y888888 "Y88888
Echo.
ECHO --------------------------------------------------------------------------------
echo - You have chosen to download an IPSW file. 
echo - Which device are you downloading for? (e.g. iPhone5,4)
set /P dldevice=- Device: %=%

echo - Which firmware do you wish to download? (e.g. 9.0.0)
set /P dlfw=- Firmware: %=%


IF EXIST %tempdir%\dlipsw  RMDIR %tempdir%\dlipsw > NUL
IF not EXIST %tempdir%\dlipsw  MKDIR %tempdir%\dlipsw > NUL

CD %tempdir%\dlipsw

IF EXIST url.txt  DEL url.txt /S /Q > NUL
ECHO - Fetching Link...

curl -A "IpswTools - %uuid% - %version%" --silent http://api.ios.icj.me/v2.1/%dldevice%/%dlfw%/url -I  > response.txt

:: check for multiple buildids
FINDSTR "300 Multiple Choices" response.txt > nul

IF ERRORLEVEL 1  ( 
    SET downloadlink=http://api.ios.icj.me/v2/%dldevice%/%dlfw%
    GOTO downloadipsw
)

<nul set /p "= - Multiple BuildIDs Found: "
curl -A "IpswTools - %uuid% - %version%" --silent http://api.ios.icj.me/v2/%dldevice%/%dlfw%/buildid  > choices.txt

:: clean up the text file
ssr 0 """ "" choices.txt
ssr 0 "," "" choices.txt
ssr 0 "{" "" choices.txt
ssr 0 "}" "" choices.txt
ssr 0 "[" "" choices.txt
ssr 0 "]" "" choices.txt

FOR %%a in ( "choices.txt" ) do ( 
    FOR /f "tokens=2 delims=:" %%B in ('find "buildid" ^< %%a') do ( 
        CALL :addtovar %%B
    )
)
ECHO %buildids%

SET %=% /P dlid=- Choose one BuildID:


SET downloadlink=http://api.ios.icj.me/v2/%dldevice%/%dlid%

GOTO downloadipsw


:downloadipsw
title Donwnload ipsw please wait..
curl -A "IpswTools - %uuid% - %version%" --silent %downloadlink%/url -I  > response.txt

FINDSTR "200 OK" response.txt > nul

IF ERRORLEVEL 1  ( 
    ECHO - Error: Link not found.
    ECHO - Press any key to return to the IPSW downloader.
    CALL :log error Unable to find IPSW link
    PAUSE > NUL
    GOTO Download
)


curl -A "IpswTools - %uuid% - %version%" --silent %downloadlink%/filename  > ipsw_name.txt
curl -A "IpswTools - %uuid% - %version%" --silent %downloadlink%/url  > url.txt
curl -A "IpswTools - %uuid% - %version%" --silent %downloadlink%/filesize  > filesize.txt

SET /p ipswName= < ipsw_name.txt
SET /p downloadlink= < url.txt
SET /p filesize= < filesize.txt

ECHO - Downloading %ipswName%... [%filesize%MB]



ECHO --------------------------------------------------------------------------------
CALL curl -LO %downloadlink% --progress-bar

CALL :log IPSW Name: %ipswName%
:: check for my HDD for IPSWs :P
IF EXIST "C:\Apple Firmware"  ( 
    CALL :loC moving %ipswName% to "%UserProfile%\Desktop\%ipswName%"
    IF not EXIST "C:\Apple Firmware\%dldevice%"  MKDIR "C:\Apple Firmware\%dldevice%" > NUL
    IF not EXIST "C:\Apple Firmware\%dldevice%\Official"  MKDIR "C:\Apple Firmware\%dldevice%\Official" > NUL
    MOVE /y "%ipswName%" "C:\Apple Firmware\%dldevice%\Official\%ipswName%" >> %logme%

    IF not EXIST "C:\Apple Firmware\%dldevice%\Official\%ipswName%"  ( 
        CALL :log error IPSW move failed
    ) else (
        CALL :log IPSW move succeeded
    )

    SET IPSW="C:\Apple Firmware\%dldevice%\Official\%ipswName%"
    CLS
    ECHO - IPSW download finished^^! Saved to "C:\Apple Firmware\%dldevice%\Official\%ipswName%"

) else (
    CALL :log moving %ipswName% to "%UserProfile%\Desktop\%ipswName%"
    MOVE /y "%ipswName%" "%UserProfile%\Desktop\%ipswName%" >> %logme%

    IF not EXIST "%UserProfile%\Desktop\%ipswName%"  ( 
        CALL :log error IPSW move failed
    ) else (
        CALL :log IPSW move succeeded
    )

    SET IPSW="%UserProfile%\Desktop\%ipswName%"
    CLS
    ECHO - IPSW download finished^^! Saved to "%UserProfile%\Desktop\%ipswName%"
)
cd ..
RD "%temp%\IpswTools\dlipsw" /S /s /Q

ECHO - Press any key to continue...%tempdir%\dlipsw
PAUSE > NUL
goto Menu


Echo.
Echo -r  Pour Restorer Votre iPhone !
Echo -e  Pour Extraire l'IPSW
set /p COMAND=Command = 
if /i "%COMAND%"=="-r" goto Restore
if /i "%COMAND%"=="-e" goto Extract

:Restore
idevicename.exe

Echo Est ce votre iPhone ?
set /p Name=Oui ou Non ? 
if /i "%Name%"=="Oui" goto Name
if /i "%Name%"=="Non" goto Exit

:Name
Echo Etez Vous S?re De Restorer Et Mettre a Jour Votre iPhone ?
set /p Restore=Oui ou Non ? 
if /i "%Restore%"=="Oui" goto Restore
if /i "%Restore%"=="Non" goto Exit
:Restore
idevicerestore.exe -l -d "%dlmodel% %dlbuild% Restore.ipsw"
pause

:Extract
Echo ----Extraction de l'IPSW----

7za.exe x "%dlmodel% %dlbuild% Restore.ipsw"
pause

:Exit
exit
