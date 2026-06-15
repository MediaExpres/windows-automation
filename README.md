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

1. Open your Windows Start menu, type **PowerShell**, right-click it, and select **Run as Administrator**.
2. Clone this repository or download the `Setup-WinGetAutomation.ps1` script to your local machine.
3. Execute the script:
   ```powershell
   .\Setup-WinGetAutomation.ps1