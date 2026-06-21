# ==============================================================================
# SCRIPT: Setup-WinGetAutomation.ps1 
# PURPOSE: Automatically creates a background WinGet updater script and 
#          registers it to run 15 minutes after you log in.
# ==============================================================================

<#
.SYNOPSIS
    Hardened setup for a scheduled WinGet auto-updater task.
#>

$ErrorActionPreference = 'Stop'

$Folder      = "C:\Automation"
$ScriptPath  = "$Folder\BackgroundUpdater.ps1"
$LogPath     = "$Folder\updater_log.txt"
$TaskName    = "Automated_WinGet_Updater"
$RegKeyPath  = "HKLM:\SOFTWARE\WinGetAutomation"
$RegHashName = "ExpectedScriptHash"

function Write-Section {
    param([string]$Message, [string]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
}

try {
    # -------------------------------------------------------------------
    # 0. Confirm elevation and capture the real interactive user identity
    # -------------------------------------------------------------------
    $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run from an elevated (Administrator) PowerShell session."
    }
    $CurrentUser = $identity.Name
    Write-Section "Running elevated as $CurrentUser." 'Gray'

    # -------------------------------------------------------------------
    # 1. Force clear any existing automation folder to ensure a fresh slate
    # -------------------------------------------------------------------
    if (Test-Path $Folder) {
        $existing = Get-Item $Folder -Force
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "$Folder is a reparse point / junction / symlink. Refusing to reuse it."
        }
        Write-Section "Existing deployment detected. Resetting ACLs and force-deleting $Folder..." 'Yellow'
        # Reset permissions to default inherited rules to bypass prior lockdowns
        & icacls $Folder /reset /T /C /Q | Out-Null
        # Force remove the entire folder and its contents cleanly
        Remove-Item -Path $Folder -Recurse -Force
    }
    
    # Create the folder fresh
    New-Item -ItemType Directory -Path $Folder | Out-Null

    # Lock it down immediately before writing any files
    $icaclsArgs = @(
        $Folder, '/inheritance:r',
        '/grant', "*S-1-5-32-544:(OI)(CI)F",
        '/grant', "*S-1-5-18:(OI)(CI)F",
        '/grant', "${CurrentUser}:(OI)(CI)RX",
        '/T', '/C', '/Q'
    )
    $icaclsOutput = & icacls @icaclsArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "icacls failed to lock down $Folder (exit code $LASTEXITCODE): $icaclsOutput"
    }

    # Verify ACL using proper SID Translation
    $acl = Get-Acl $Folder
    if (-not $acl.AreAccessRulesProtected) {
        throw "$Folder still inherits parent permissions after icacls /inheritance:r - aborting."
    }
    
    $hasAdminFull = $acl.Access | Where-Object {
        $sid = $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
        $sid -eq 'S-1-5-32-544' -and $_.FileSystemRights -match 'FullControl'
    }
    
    if (-not $hasAdminFull) {
        throw "Expected Administrators FullControl ACE not found on $Folder after lockdown - aborting."
    }
    Write-Section "Folder $Folder created and locked down (verified) before any payload was written." 'Green'

    # -------------------------------------------------------------------
    # 2. Write the updater payload (PATCHED for PS 5.1 NativeCommandError)
    # -------------------------------------------------------------------
    $UpdaterCode = @"
`$ErrorActionPreference = 'Stop'
`$LogPath = "$LogPath"

if ((Test-Path `$LogPath) -and ((Get-Item `$LogPath).Length -gt 2097152)) {
    (Get-Content `$LogPath -Tail 500) | Set-Content `$LogPath -Encoding UTF8
}

try {
    Start-Transcript -Path `$LogPath -Append | Out-Null
    Write-Host "Starting background WinGet update sequence: `$(Get-Date -Format o)"

    # Securely resolve WinGet path to prevent PATH hijacking
    `$WinGetPath = "`$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

    if (-not (Test-Path `$WinGetPath)) { throw "winget.exe could not be found at secure path." }

    # Isolate WinGet in its own process to prevent PS 5.1 from crashing on progress bar outputs
    `$proc = Start-Process -FilePath `$WinGetPath -ArgumentList "upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow -PassThru
    `$wingetExit = `$proc.ExitCode
    
    if (`$wingetExit -eq 0) {
        Write-Host "Sequence completed successfully (exit code 0)."
    } else {
        Write-Host "WARNING: winget exited with code `$wingetExit."
    }
}
catch {
    Write-Host "ERROR: `$_"
}
finally {
    Stop-Transcript | Out-Null
}
"@

    Set-Content -Path $ScriptPath -Value $UpdaterCode -Encoding UTF8 -Force
    Write-Section "Payload written to $ScriptPath." 'Gray'

    # -------------------------------------------------------------------
    # 3. Pin an integrity hash in HKLM
    # -------------------------------------------------------------------
    $expectedHash = (Get-FileHash -Path $ScriptPath -Algorithm SHA256).Hash
    if (-not (Test-Path $RegKeyPath)) {
        New-Item -Path $RegKeyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegKeyPath -Name $RegHashName -Value $expectedHash -Type String
    Write-Section "Integrity hash pinned at $RegKeyPath\$RegHashName." 'Gray'

    # -------------------------------------------------------------------
    # 4. Build a scheduled task Action that verifies the payload's hash
    # -------------------------------------------------------------------
    $VerifyAndRun = @'
$ErrorActionPreference = 'Stop'
$scriptPath  = 'REPLACE_SCRIPT_PATH'
$regKeyPath  = 'REPLACE_REG_KEY'
$regHashName = 'REPLACE_REG_NAME'
try {
    $expected = (Get-ItemProperty -Path $regKeyPath -Name $regHashName -ErrorAction Stop).$regHashName
    $actual   = (Get-FileHash -Path $scriptPath -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($expected -ne $actual) {
        throw "Hash Mismatch! Aborting execution."
    }
    & $scriptPath
}
catch {
    throw "Verification Failed."
}
'@
    $VerifyAndRun = $VerifyAndRun.Replace('REPLACE_SCRIPT_PATH', $ScriptPath).
                                   Replace('REPLACE_REG_KEY', $RegKeyPath).
                                   Replace('REPLACE_REG_NAME', $RegHashName)

    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($VerifyAndRun))
    $PowerShellExe  = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"

    # -------------------------------------------------------------------
    # 5. Register the scheduled task
    # -------------------------------------------------------------------
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Trigger.Delay = "PT15M"

    $Action = New-ScheduledTaskAction -Execute $PowerShellExe `
        -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy RemoteSigned -EncodedCommand $EncodedCommand"

    $Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest
    $Settings  = New-ScheduledTaskSettingsSet -Compatibility Win8

    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Section "An existing task named '$TaskName' was found and will be replaced." 'Yellow'
    }

    Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

    # -------------------------------------------------------------------
    # 6. Final verification pass
    # -------------------------------------------------------------------
    $verifyTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $verifyAcl  = Get-Acl $Folder
    $verifyHash = (Get-FileHash -Path $ScriptPath -Algorithm SHA256).Hash
    $regHash    = (Get-ItemProperty -Path $RegKeyPath -Name $RegHashName).$RegHashName

    $allGood = $true
    if (-not $verifyTask) {
        Write-Section "FAILED: scheduled task not found after registration." 'Red'
        $allGood = $false
    }
    if ($verifyHash -ne $regHash) {
        Write-Section "FAILED: pinned hash does not match the file currently on disk." 'Red'
        $allGood = $false
    }

    if ($allGood) {
        Write-Host ""
        Write-Host "Success: '$ScriptPath' created with auto-trimming logs and a hash-verifying launcher," -ForegroundColor Green
        Write-Host "         triggered 15 minutes after logon as task '$TaskName'." -ForegroundColor Green
        Write-Host "Hardening applied: ACL locked before write, integrity hash pinned in HKLM," -ForegroundColor Cyan
        Write-Host "                   winget resolved by absolute path." -ForegroundColor Cyan
    }
    else {
        throw "One or more post-install verification checks failed. See above."
    }
}
catch {
    Write-Host ""
    Write-Host "Setup failed: $_" -ForegroundColor Red
}
