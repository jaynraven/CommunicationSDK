@echo off 

set mode=%1
set bin_dir=bin
set build_dir=build
set install_dir=install

if "%mode%" equ "help" (
    echo "Usage:%0[mode]"
    echo "mode:dev|build|clean|help, default:build"
) else if "%mode%" equ "clean" (
    call:func
) else if "%mode%" equ "dev" (
    call:func
    call %~dp0script\build_windows.bat dev x64 Debug %~dp0
) else (
    call:func
    call %~dp0script\build_windows.bat build x64 RelWithDebInfo %~dp0
    call %~dp0script\build_windows.bat build Win32 RelWithDebInfo %~dp0
)

goto:eof

@REM 函数定义
:func
    if EXIST %bin_dir% (
        rd /s/q %bin_dir%
    )
    if EXIST %build_dir% (
        rd /s/q %build_dir%
    )
    if EXIST %install_dir% (
        rd /s/q %install_dir%
    )
goto:eof