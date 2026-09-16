@echo off
:: Self-elevating fixer for EXOInvoiceStagingDailyLoad:
:: - Enables "Start the task as soon as possible after a scheduled start is missed"
:: - Enables "Wake the computer to run this task" (helps if the machine is asleep, not fully off)
:: - Dumps the task's current settings and run history to a log file for review

net session >nul 2>&1
if %errorLevel% == 0 goto :run

echo Requesting administrator privileges...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
set LOGFILE=D:\DataloaderCLI\EdwardGroupSandbox\Result\TaskScheduleCheck.log

powershell -NoProfile -Command ^
  "$ErrorActionPreference='Continue';" ^
  "'--- Task Info (before fix) ---' | Out-File -FilePath '%LOGFILE%';" ^
  "Get-ScheduledTask -TaskName 'EXOInvoiceStagingDailyLoad' | Format-List * | Out-File -Append -FilePath '%LOGFILE%';" ^
  "Get-ScheduledTaskInfo -TaskName 'EXOInvoiceStagingDailyLoad' | Format-List * | Out-File -Append -FilePath '%LOGFILE%';" ^
  "$s = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries;" ^
  "Set-ScheduledTask -TaskName 'EXOInvoiceStagingDailyLoad' -Settings $s | Out-Null;" ^
  "'--- Task Info (after fix) ---' | Out-File -Append -FilePath '%LOGFILE%';" ^
  "Get-ScheduledTask -TaskName 'EXOInvoiceStagingDailyLoad' | Format-List * | Out-File -Append -FilePath '%LOGFILE%';" ^
  "'--- Recent run history (Task Scheduler event log) ---' | Out-File -Append -FilePath '%LOGFILE%';" ^
  "try { Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'} -MaxEvents 200 -ErrorAction Stop | Where-Object { $_.Message -match 'EXOInvoiceStagingDailyLoad' } | Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append -FilePath '%LOGFILE%' } catch { \"No task history events found or log unavailable: $($_.Exception.Message)\" | Out-File -Append -FilePath '%LOGFILE%' }"

echo.
echo Done. Results written to %LOGFILE%
echo Press any key to close this window.
pause >nul
