set mode=%1
set arch=%2
set build_type=%3
set root_dir=%4

if "%arch%" equ "x64" (
    set arch_name="x64"
) else (
    set arch_name="x86"
)

set build_dir=%root_dir%build
set bin_dir=%root_dir%bin
set bin_arch_dir=%bin_dir%\%arch_name%\%build_type%
set install_dir=%root_dir%install
set script_dir=%root_dir%script_dir

echo Build dir: %build_dir%

if EXIST %build_dir% (
    rd /s/q %build_dir%
)

if EXIST %bin_arch_dir% (
    rd /s/q %bin_arch_dir%
)

cmake^
    -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE ^
    -DCMAKE_BUILD_TYPE:STRING=%build_type% ^
    -DCMAKE_INSTALL_PREFIX=%install_dir% ^
    -DBUILD_MODE:STRING=%mode% ^
    -G "Visual Studio 17 2022" ^
    -T host=x86 ^
    -A %arch% ^
    -S %root_dir% ^
    -B %build_dir%

cmake --build %build_dir% ^
    --config %build_type% ^
    --target install ^
    -j 14 ^
    --