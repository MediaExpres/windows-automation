# ==============================================================================
# SCRIPT: Setup-WinGetAutomation.ps1 (FINAL BULLETPROOF VERSION)
# PURPOSE: Automatically creates a background WinGet updater script and 
#          registers it to run 15 minutes after you log in.
# ==============================================================================

$Folder = "C:\Automation"
$ScriptPath = "$Folder\BackgroundUpdater.ps1"
$TaskName = "Automated_WinGet_Updater"

# CRITICAL FIX: Ensure the target directory actually exists on new computers!
if (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder | Out-Null
}

# 1. Write the updating payload
$UpdaterCode = @"
Start-Transcript -Path "$Folder\updater_log.txt" -Append
Write-Host "Starting background WinGet update asset sequence..."
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
Write-Host "Sequence completed successfully."
Stop-Transcript
"@

Set-Content -Path $ScriptPath -Value $UpdaterCode

# 2. Define the new trigger: At User Logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Trigger.Delay = "PT15M"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest

# Optional: Force the Task Scheduler UI to display modern Windows compatibility
$Settings = New-ScheduledTaskSettingsSet -Compatibility Win8

# 3. Register the task
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

Write-Host "Success! The code generated '$ScriptPath' and the task trigger is now set to 15 minutes after you Log In." -ForegroundColor Green
