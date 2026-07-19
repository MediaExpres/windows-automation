# Install-Task.ps1
$taskName = "Media Expres WinGet Updater"

# Dynamically find the updater script in the same directory as this installer
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "BackgroundUpdater.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Warning "Could not find BackgroundUpdater.ps1 in $PSScriptRoot."
    Write-Warning "Please ensure both scripts are in the same folder before running the installer."
    exit
}

Write-Output "Configuring Scheduled Task for $env:USERNAME..."

# 1. Action: Run PowerShell hidden, bypassing local execution policies for this single run
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# 2. Trigger: Run at Logon, delayed by 15 minutes (to avoid slowing down Windows boot)
$trigger = New-ScheduledTaskTrigger -AtLogOn
$trigger.Delay = "PT15M" # ISO 8601 format for 15 minutes

# 3. Settings: Require internet (for WinGet) and allow running on laptop battery
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 4. Principal: Run strictly in the current user's active session so Toast Notifications are visible
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

# 5. Register the Task (Force overwrites any existing task with the same name)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force

Write-Output "✅ Successfully installed scheduled task: $taskName"
Write-Output "The updater will now run silently 15 minutes after you log in."