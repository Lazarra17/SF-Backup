@echo off
:: Self-elevating installer for the EXOInvoiceStagingDailyLoad scheduled task.
:: Double-click this file; a UAC prompt will appear (this is required to create
:: a task that runs as SYSTEM) - click Yes to continue.

net session >nul 2>&1
if %errorLevel% == 0 goto :run

echo Requesting administrator privileges...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
schtasks /Create /TN "EXODebtorStagingDailyLoad" /TR "C:\EXOSalesforceExport\EdwardGroupSandbox\dataloadDebtorStaging.bat" /SC DAILY /ST 02:30 /RU "SYSTEM" /RL HIGHEST /F
schtasks /Create /TN "EXOInvoiceStagingDailyLoad" /TR "C:\EXOSalesforceExport\EdwardGroupSandbox\dataloadInvoiceStaging.bat" /SC DAILY /ST 02:32 /RU "SYSTEM" /RL HIGHEST /F

echo.
echo Done. Press any key to close this window.
pause >nul
