@echo off
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set PATH=D:\flutter\bin;%PATH%
set CL=/wd4819
cd /d E:\develop-space\nex.alaikis.com\clients
flutter build windows --debug --verbose
endlocal
