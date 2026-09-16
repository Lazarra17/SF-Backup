@echo off
:: Self-elevating: forces EXOInvoiceStagingDailyLoad to run right now (same
:: SYSTEM context Task Scheduler uses), waits for it to finish, then dumps
:: the task result and console output log for review.

net session >nul 2>&1
if %errorLevel% == 0 goto :run

echo Requesting administrator privileges...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
set LOGFILE=D:\DataloaderCLI\EdwardGroupSandbox\Result\TaskScheduleCheck.log

echo ==== Forcing immediate run via schtasks /Run ==== >> "%LOGFILE%"
schtasks /Run /TN "EXOInvoiceStagingDailyLoad"

echo Waiting 45 seconds for the run to complete...
powershell -NoProfile -Command "Start-Sleep -Seconds 45"

powershell -NoProfile -Command ^
  "'--- Task Info after forced run ---' | Out-File -Append -FilePath '%LOGFILE%';" ^
  "Get-ScheduledTaskInfo -TaskName 'EXOInvoiceStagingDailyLoad' | Format-List * | Out-File -Append -FilePath '%LOGFILE%'"

echo.
echo Done. Check %LOGFILE% and D:\DataloaderCLI\EdwardGroupSandbox\Result\ScheduledRunOutput.log
echo Press any key to close this window.
pause >nul
