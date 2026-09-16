setlocal enabledelayedexpansion
set RUNLOG=C:\EXOSalesforceExport\EdwardGroupSandbox\Result\ScheduledRunOutput.log
set SRC_DIR=C:\EXOSalesforceExport
set ARCHIVE_DIR=C:\EXOSalesforceExport\EdwardGroupSandbox\FilesUploaded
set FIXED_NAME=DebtorsExport.csv

echo ==== %DATE% %TIME% - starting EXODebtorInsert ==== >> "%RUNLOG%"

set LATEST_FILE=
for /f "delims=" %%F in ('dir /b /o:-d "%SRC_DIR%\DebtorsExport*.csv" 2^>nul') do (
    if not defined LATEST_FILE set LATEST_FILE=%%F
)

if not defined LATEST_FILE (
    echo ERROR: No file matching DebtorsExport*.csv found in %SRC_DIR% >> "%RUNLOG%"
    echo ==== %DATE% %TIME% - finished with exit code 9009 ==== >> "%RUNLOG%"
    exit /b 9009
)

echo Using source file: !LATEST_FILE! >> "%RUNLOG%"
copy /Y "%SRC_DIR%\!LATEST_FILE!" "%SRC_DIR%\%FIXED_NAME%" >nul

cd /d "C:\EXOSalesforceExport\EdwardGroupSandbox\Dataloader\bin"
CALL process.bat "C:\EXOSalesforceExport\EdwardGroupSandbox\setting" EXODebtorInsert >> "%RUNLOG%" 2>&1
set LOAD_EXIT_CODE=%ERRORLEVEL%
echo ==== %DATE% %TIME% - finished with exit code %LOAD_EXIT_CODE% ==== >> "%RUNLOG%"

if not exist "%ARCHIVE_DIR%" mkdir "%ARCHIVE_DIR%"

if %LOAD_EXIT_CODE% NEQ 0 (
    echo ERROR: Data Loader failed with exit code %LOAD_EXIT_CODE%. File not moved. >> "%RUNLOG%"
) else (
    move /Y "%SRC_DIR%\!LATEST_FILE!" "%ARCHIVE_DIR%\!LATEST_FILE!" >> "%RUNLOG%" 2>&1
    if errorlevel 1 (
        echo ERROR: Failed to move !LATEST_FILE! to %ARCHIVE_DIR% >> "%RUNLOG%"
    ) else (
        echo Archived !LATEST_FILE! to %ARCHIVE_DIR% >> "%RUNLOG%"
    )
    
    del /F /Q "%SRC_DIR%\%FIXED_NAME%" 2>nul
    echo Removed working copy %FIXED_NAME% from %SRC_DIR% >> "%RUNLOG%"
)

exit /b %LOAD_EXIT_CODE%