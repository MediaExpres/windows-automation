# ==============================================================================
# SCRIPT: Setup-WinGetAutomation.ps1 (LOG MANAGEMENT UPGRADE)
# PURPOSE: Automatically creates a background WinGet updater script and 
#          registers it to run 15 minutes after you log in.
# ==============================================================================

$Folder = "C:\Automation"
$ScriptPath = "$Folder\BackgroundUpdater.ps1"
$TaskName = "Automated_WinGet_Updater"

# Ensure the target directory actually exists
if (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder | Out-Null
}

# 1. Write the updating payload with Auto-Trimming Logic
$UpdaterCode = @"
# --- LOG MANAGEMENT ---
# Check if the log file exists and is larger than 2MB (2097152 bytes)
if ((Test-Path "$Folder\updater_log.txt") -and ((Get-Item "$Folder\updater_log.txt").Length -gt 2097152)) {
    # Keep only the last 500 lines to save space and overwrite the old bloated file
    (Get-Content "$Folder\updater_log.txt" -Tail 500) | Set-Content "$Folder\updater_log.txt"
}

# --- UPDATE SEQUENCE ---
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

Write-Host "Success! The code generated '$ScriptPath' with auto-trimming logs, triggered 15 mins after Login." -ForegroundColor Green
