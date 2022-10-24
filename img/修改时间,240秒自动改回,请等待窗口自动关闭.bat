@echo off
set today=%date:~0,10%
set ott=%time%
date 2018-11-28
time 01:34
for /f "tokens=1-3 delims=:, " %%i in ("%ott%") do set /a oht=%%i&set /a omt=%%j&set /a ost=%%k
set /a ttst=%oht%*3600+%omt%*60+%ost%+240
set /a nh=%ttst%/3600
set /a nm=(%ttst%-%nh%*3600)/60
set /a ns=%ttst%-%nh%*3600-%nm%*60
ping 127.1 -n 240
time %nh%:%nm%:%ns%
date %today%
