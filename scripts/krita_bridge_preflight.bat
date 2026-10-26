@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0\.."

echo ==========================================
echo   NAI Launcher - Krita Bridge Preflight
echo ==========================================
echo.
echo This command is read-only for the real Krita profile.
echo It packages the plugin, checks the current profile with --check,
echo and regenerates the acceptance report.
echo.

set "PYTHON_CMD="
set "WSL_CWD="
where py >nul 2>nul
if errorlevel 1 goto :find_python
set "PYTHON_CMD=py -3"
goto :run_python

:find_python
where python >nul 2>nul
if errorlevel 1 goto :find_wsl
set "PYTHON_CMD=python"
goto :run_python

:find_wsl
where wsl.exe >nul 2>nul
if errorlevel 1 goto :no_python
for /f "usebackq delims=" %%p in (`wsl.exe wslpath -a "%CD%"`) do set "WSL_CWD=%%p"
if not defined WSL_CWD goto :no_python
wsl.exe --cd "%WSL_CWD%" python3 krita_plugin/preflight.py %*
set "EXIT_CODE=%errorlevel%"
goto :after_preflight

:run_python
%PYTHON_CMD% krita_plugin\preflight.py %*
set "EXIT_CODE=%errorlevel%"
goto :after_preflight

:no_python
echo [ERROR] Python was not found on PATH.
echo Install Python 3 or run from WSL: python3 krita_plugin/preflight.py %*
exit /b 1

:after_preflight
if not "%EXIT_CODE%"=="0" (
    echo.
    echo [ERROR] Krita Bridge preflight failed with exit code %EXIT_CODE%.
    exit /b %EXIT_CODE%
)

echo.
echo [OK] Krita Bridge preflight finished.
exit /b 0
