# ==============================================================================
# SCRIPT: Setup-WinGetAutomation.ps1 (USER CONTEXT FIX)
# PURPOSE: Automatically creates a background WinGet updater script and 
#          registers it to run 15 minutes after every system startup.
# ==============================================================================

# 1. Define the directory and paths for our automated payload
$Folder = "C:\Automation"
$ScriptPath = "$Folder\BackgroundUpdater.ps1"
$TaskName = "Automated_WinGet_Updater"

# Create the directory if it doesn't exist yet
if (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder | Out-Null
}

# 2. Write the updating code block that will run in the background
$UpdaterCode = @"
Start-Transcript -Path "$Folder\updater_log.txt" -Append
Write-Host "Starting background WinGet update asset sequence..."
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
Write-Host "Sequence completed successfully."
Stop-Transcript
"@

# Save the code block into our script file
Set-Content -Path $ScriptPath -Value $UpdaterCode

# 3. Define the Task Scheduler Parameters via PowerShell Cmdlets
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Trigger.Delay = "PT15M"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# --- THE FIX IS HERE ---
# Dynamically grab your current Windows username (e.g., DELLCODE\mihai)
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Run as YOU, only when logged in, but with the Highest (Admin) privileges
$Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest

# 4. Register the new task into the operating system
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Principal $Principal -Force | Out-Null

Write-Host "Success! The task has been updated to run under your profile: $CurrentUser" -ForegroundColor Green