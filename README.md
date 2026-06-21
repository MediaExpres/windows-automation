# Automated WinGet Background Updater

A lightweight, highly secure, and fully automated PowerShell script that keeps your Windows applications up to date using the native Windows Package Manager (WinGet). 

Instead of manually checking for updates or relying on heavy third-party software that drains system resources, this script integrates directly with Windows Task Scheduler to run silently in the background 15 minutes after you log in to your computer.

*🤖 **Acknowledgments:** This automation script and documentation were developed iteratively with Google Gemini as an AI pair-programming partner.*

## ✨ Features

* **Set It and Forget It:** Automatically upgrades all supported applications with a single setup.
* **Non-Intrusive:** Uses a 15-minute delay after logon so it doesn't slow down your computer while it's booting up.
* **Silent Execution:** Runs completely hidden in the background without popping up annoying terminal windows.
* **Auto-Trimming Logs:** Automatically monitors its own log file. If the log exceeds 2 MB, it automatically trims old entries, keeping only the 500 most recent lines to permanently prevent file bloat.
* **Enterprise Security Hardening:** Actively defends against script hijacking via strict ACL folder lockdowns, automated permission teardown and resets on upgrades, SHA-256 cryptographic hash pinning, and absolute executable pathing.

## 🚀 Installation & Setup

Because Windows strictly limits running downloaded script files by default, the easiest way to install this automation is to run the code directly in your terminal.

1. Open your Windows Start menu, type **PowerShell**, right-click it, and select **Run as Administrator**.
2. Open the `Setup-WinGetAutomation.ps1` file from this repository and **copy all of the code**.
3. Go back to your Administrator PowerShell window, **paste the code**, and press **Enter**.
4. The setup sequence will automatically:
   * Verify an elevated context.
   * Reset prior ACL dependencies and force-delete existing versions of `C:\Automation` to clear modification conflicts.
   * Create and immediately lock down the `C:\Automation` directory to prevent TOCTOU race conditions.
   * Generate the background updater payload (`BackgroundUpdater.ps1`).
   * Calculate and pin the SHA-256 integrity hash of the script to `HKLM`.
   * Register a new Scheduled Task named `Automated_WinGet_Updater`.

*That's it! You can now close the PowerShell window.*

## 🛠️ How It Works

Once installed, the setup code creates a Windows Scheduled Task with the following parameters:
* **Trigger:** At User Logon with a `PT15M` (15-minute) delay.
* **Action:** Launches `PowerShell.exe` with a `-WindowStyle Hidden` argument.
* **Security Context:** Runs dynamically as the current interactive user with `Highest` (Administrator) privileges.

### Security Architecture
To prevent Script Hijacking, the script implements cryptographic verification. Before the Scheduled Task ever runs the WinGet payload, it computes the live SHA-256 hash of `BackgroundUpdater.ps1` and compares it to the trusted hash pinned in the Windows Registry during installation. If malicious software alters the file, the hash mismatch causes the task to immediately abort.

When the verified background payload runs, it mathematically checks `updater_log.txt` to trim old entries, then runs the following WinGet command (using absolute paths and `--silent` flags) to safely update all packages:

    $proc = Start-Process -FilePath $WinGetPath -ArgumentList "upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow -PassThru

## 📝 Logs and Verification

You can check the history of your updates at any time by opening the generated log file: `C:\Automation\updater_log.txt`

If you want to manually trigger an update outside of the normal logon schedule:

1. Open **Task Scheduler**.
2. Locate `Automated_WinGet_Updater` in the Task Scheduler Library.
3. Right-click and select **Run**.

## ⚠️ Prerequisites

* Windows 10 or Windows 11.
* [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) installed (Included by default on modern Windows builds via the App Installer package).
