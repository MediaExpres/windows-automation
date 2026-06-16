# Automated WinGet Background Updater

A lightweight, fully automated PowerShell script that keeps your Windows applications up to date using the native Windows Package Manager (WinGet). 

Instead of manually checking for updates or relying on heavy third-party software, this script integrates directly with Windows Task Scheduler to run silently in the background 15 minutes after you log in to your computer.

## ✨ Features

* **Set It and Forget It:** Automatically upgrades all supported applications with a single setup.
* **Non-Intrusive:** Uses a 15-minute delay after logon so it doesn't slow down your computer while it's booting up.
* **Silent Execution:** Runs completely hidden in the background without popping up annoying terminal windows.
* **Secure Context:** Runs locally under your own specific Windows user profile with the necessary administrative privileges.
* **Transparent Logging:** Generates a clean text log of every update sequence so you can verify what changed.

## 🚀 Installation & Setup

Because Windows strictly limits running downloaded script files by default, the easiest way to install this automation is to run the code directly in your terminal.

1. Open your Windows Start menu, type **PowerShell**, right-click it, and select **Run as Administrator**.
2. Open the `Setup-WinGetAutomation.ps1` file from this repository and **copy all of the code**.
3. Go back to your Administrator PowerShell window, **paste the code**, and press **Enter**.
4. The setup sequence will automatically:
   * Create an automation directory at `C:\Automation`.
   * Generate the background updater payload (`BackgroundUpdater.ps1`).
   * Register a new Scheduled Task named `Automated_WinGet_Updater`.

*That's it! You can now close the PowerShell window.*

## 🛠️ How It Works

Once installed, the setup code creates a Windows Scheduled Task with the following parameters:
* **Trigger:** At User Logon with a `PT15M` (15-minute) delay.
* **Action:** Launches `PowerShell.exe` with a `-WindowStyle Hidden` argument.
* **Security:** Runs dynamically as the current interactive user with `Highest` (Administrator) privileges to ensure software can be installed cleanly under your profile.

The payload script uses the following WinGet command to safely update all packages, accepting standard agreements automatically:
```powershell
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
