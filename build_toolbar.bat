@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set PATH=C:\Qt\6.10.1\msvc2022_64\bin;%PATH%
cd /d D:\git\qgroundcontrol\build\Desktop_Qt_6_10_1_MSVC2022_64bit-Debug
ninja -j 2
echo BUILD_EXIT_CODE=%ERRORLEVEL%
