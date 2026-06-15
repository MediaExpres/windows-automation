# ==============================================================================
# SCRIPT: Setup-WinGetAutomation.ps1
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
# Clear log file and record startup time
Start-Transcript -Path "$Folder\updater_log.txt" -Append
Write-Host "Starting background WinGet update asset sequence..."
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
Write-Host "Sequence completed successfully."
Stop-Transcript
"@

# Save the code block into our script file
Set-Content -Path $ScriptPath -Value $UpdaterCode

# 3. Define the Task Scheduler Parameters via PowerShell Cmdlets
# Create a trigger that activates at system startup and waits 15 minutes
$Trigger = New-ScheduledTaskTrigger -AtStartup -Delay (New-TimeSpan -Minutes 15)

# Specify the system action: Launch PowerShell silently executing our script file
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Define the security settings: Run under the SYSTEM account with maximum administrative privileges
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# 4. Register the new task into the operating system
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Principal $Principal | Out-Null

Write-Host "Success! The code has generated '$ScriptPath' and registered the '$TaskName' task." -ForegroundColor Green
Write-Host "Your system will now safely check for and install updates 15 minutes after every boot." -ForegroundColor Cyan