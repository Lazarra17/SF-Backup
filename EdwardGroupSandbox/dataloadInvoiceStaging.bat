setlocal enabledelayedexpansion
set RUNLOG=C:\EXOSalesforceExport\EdwardGroupSandbox\Result\ScheduledRunOutput.log
set SRC_DIR=C:\EXOSalesforceExport\EdwardGroupSandbox\FileToUpload
set ARCHIVE_DIR=C:\EXOSalesforceExport\EdwardGroupSandbox\FilesUploaded
set FIXED_NAME=InvoiceExport.csv

echo ==== %DATE% %TIME% - starting EXOInvoiceInsert ==== >> "%RUNLOG%"

set LATEST_FILE=
for /f "delims=" %%F in ('dir /b /o:-d "%SRC_DIR%\InvoiceExport*.csv" 2^>nul') do (
    if not defined LATEST_FILE set LATEST_FILE=%%F
)

if not defined LATEST_FILE (
    echo ERROR: No file matching InvoiceExport*.csv found in %SRC_DIR% >> "%RUNLOG%"
    echo ==== %DATE% %TIME% - finished with exit code 9009 ==== >> "%RUNLOG%"
    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\EXOSalesforceExport\EdwardGroupSandbox\setting\SendLoadFailureAlert.ps1" -ProcessName "EXOInvoiceInsert" -ExitCode 9009 -DebugLogPath "C:\EXOSalesforceExport\EdwardGroupSandbox\Result\invoiceMasterSoapTrace.log"
    exit /b 9009
)

echo Using source file: !LATEST_FILE! >> "%RUNLOG%"
copy /Y "%SRC_DIR%\!LATEST_FILE!" "%SRC_DIR%\%FIXED_NAME%" >nul

cd /d "C:\EXOSalesforceExport\EdwardGroupSandbox\Dataloader\bin"
CALL process.bat "C:\EXOSalesforceExport\EdwardGroupSandbox\setting" EXOInvoiceInsert >> "%RUNLOG%" 2>&1
set LOAD_EXIT_CODE=%ERRORLEVEL%
echo ==== %DATE% %TIME% - finished with exit code %LOAD_EXIT_CODE% ==== >> "%RUNLOG%"

if not %LOAD_EXIT_CODE% == 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\EXOSalesforceExport\EdwardGroupSandbox\setting\SendLoadFailureAlert.ps1" -ProcessName "EXOInvoiceInsert" -ExitCode %LOAD_EXIT_CODE% -DebugLogPath "C:\EXOSalesforceExport\EdwardGroupSandbox\Result\invoiceMasterSoapTrace.log"
) else (
    move /Y "%SRC_DIR%\!LATEST_FILE!" "%ARCHIVE_DIR%\!LATEST_FILE!" >nul
    echo Archived !LATEST_FILE! to %ARCHIVE_DIR% >> "%RUNLOG%"
    del /F /Q "%SRC_DIR%\%FIXED_NAME%" 2>nul
    echo Removed working copy %FIXED_NAME% from %SRC_DIR% >> "%RUNLOG%"
)

exit /b %LOAD_EXIT_CODE%
