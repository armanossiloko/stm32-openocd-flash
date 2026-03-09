@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%"
if exist "%SCRIPT_DIR%..\.project" set "PROJECT_DIR=%SCRIPT_DIR%.."
cd /d "%PROJECT_DIR%"

set "PROJECT_NAME=%~1"
if "%PROJECT_NAME%"=="" if exist ".project" (
    for /f "delims=" %%P in ('powershell -NoProfile -Command "$m=[regex]::Match((Get-Content ''.project'' -Raw), ''<name>([^<]+)</name>''); if ($m.Success) { $m.Groups[1].Value }"') do set "PROJECT_NAME=%%P"
)
if "%PROJECT_NAME%"=="" (
    for %%F in (*.ioc) do if not defined PROJECT_NAME set "PROJECT_NAME=%%~nF"
)
if "%PROJECT_NAME%"=="" set "PROJECT_NAME=Stm32Project"

set "OPENOCD_CMD=openocd"
if not "%OPENOCD_SCRIPTS%"=="" set "OPENOCD_CMD=openocd -s ""%OPENOCD_SCRIPTS%"""

set "ELF_PATH=Debug/%PROJECT_NAME%.elf"
if not exist "Debug\%PROJECT_NAME%.elf" if exist "Release\%PROJECT_NAME%.elf" set "ELF_PATH=Release/%PROJECT_NAME%.elf"
set "ELF=%ELF_PATH:/=\%"

if not exist "%ELF%" (
    echo Error: %ELF% not found. Build the project in STM32CubeIDE first.
    pause
    exit /b 1
)

echo Flashing %ELF% to CH32...
call %OPENOCD_CMD% -c "set CPUTAPID 0x2ba01477" -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program %ELF_PATH% verify reset exit"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Retry with NRST held during connect...
    call %OPENOCD_CMD% -c "set CPUTAPID 0x2ba01477" -f interface/stlink.cfg -c "reset_config srst_only srst_nogate connect_assert_srst" -f target/stm32f1x.cfg -c "program %ELF_PATH% verify reset exit"
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo Flash failed.
    echo If old code is still running, wire ST-Link NRST to board NRST and run this again.
    echo Keep SWDIO, SWCLK, GND, and NRST connected.
    pause
    exit /b 1
)

echo Done. Device should be running.
endlocal
exit /b 0
