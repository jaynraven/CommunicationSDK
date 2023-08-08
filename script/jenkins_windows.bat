set CODE_ROOT_DIR=%WORKSPACE%
set branch=%branch:origin/=%
set OUT_DIR_ROOT=D:\output\diceng\lib_CMakeTemplateSDK\%branch%
set PROJECT_OUT_DIR=%CODE_ROOT_DIR%\install

git branch -D %branch%
git switch -c %branch%

d:
cd %CODE_ROOT_DIR%
call build.bat

if not %errorlevel% == 0 exit /b -l

set git_version=0
for /f %%i in ('type %PROJECT_OUT_DIR%\git_version') do (set git_version=%%i)
for /f "tokens=1-3 delims=/ " %%1 in ("%date%") do set ttt=%%1%%2%%3
for /f "tokens=1-3 delims=.: " %%1 in ("%time%") do set ttt=%%1%%2%%3
set BUILD_DATETIME=%ttt%
set OUT_DIR="%OUT_DIR_ROOT%\%BUILD_DATETIME%_%git_version%_%BUILD_NUMBER%"

call signcode.bat "%PROJECT_OUT_DIR%" "lib_CMakeTemplateSDK_V%git_version%" ""

xcopy %PROJECT_OUT_DIR%\*.* %OUT_DIR%\ /E /F /Y

echo 'send pdb file to bugsplat ...'
set PDB_FOLDER=%OUT_DIR%\bin\x64
set version="%git_version%"
@rem 清空当前版本的所有符号
@rem SendPdbs.exe /u develop@temorshare.com /p develop@2019 /b 4ddig_win /a lib_DeviceViewerSDK /v %git_version% /r
@rem 只上传x64的符号，可以通用
