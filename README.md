# Automated WinGet Background Updater

A lightweight, fully automated PowerShell script that keeps your Windows applications up to date using the native Windows Package Manager (WinGet). 

Instead of manually checking for updates or relying on heavy third-party software, this script integrates directly with Windows Task Scheduler to run silently in the background 15 minutes after your system starts.

## ✨ Features

* **Set It and Forget It:** Automatically upgrades all supported applications with a single setup.
* **Non-Intrusive:** Uses a 15-minute startup delay so it doesn't slow down your computer while booting.
* **Silent Execution:** Runs completely hidden in the background without popping up annoying terminal windows.
* **Secure Context:** Runs locally under your own Windows user profile with the necessary administrative privileges.
* **Transparent Logging:** Generates a clean text log of every update sequence so you can verify what changed.

## 🚀 Installation & Setup

1. Open your Windows Start menu, type **PowerShell**, right-click it, and select **Run as Administrator**.
2. Clone this repository or download the `Setup-WinGetAutomation.ps1` script to your local machine.
3. Execute the script:
   ```powershell
   .\Setup-WinGetAutomation.ps1

```

4. The setup script will automatically:
* Create an automation directory at `C:\Automation`.
* Generate the background updater payload (`BackgroundUpdater.ps1`).
* Register a new Scheduled Task named `Automated_WinGet_Updater`.



## 🛠️ How It Works

Once installed, the setup script creates a Windows Scheduled Task with the following parameters:

* **Trigger:** On System Startup with a `PT15M` (15-minute) delay.
* **Action:** Launches `PowerShell.exe` with a `-WindowStyle Hidden` argument.
* **Security:** Runs as the interactive user with `Highest` (Administrator) privileges to ensure software can be installed cleanly.

The payload script uses the following WinGet command to safely update all packages, accepting standard agreements automatically:

```powershell
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

```

## 📝 Logs and Verification

You can check the history of your updates at any time by opening the generated log file:
`C:\Automation\updater_log.txt`

If you want to manually trigger an update outside of the normal startup schedule:

1. Open **Task Scheduler**.
2. Locate `Automated_WinGet_Updater` in the Task Scheduler Library.
3. Right-click and select **Run**.

## ⚠️ Prerequisites

* Windows 10 or Windows 11.
* [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) installed (Included by default on modern Windows builds via the App Installer package).


