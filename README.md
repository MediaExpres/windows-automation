# Media Expres WinGet Background Automation

A lightweight, zero-dependency automation toolkit for Windows that silently keeps all WinGet packages up to date in the background, complete with native desktop alerts.

## 🚀 Features
* **Silent Execution:** Runs completely hidden in the background 15 minutes after user logon.
* **Smart Output Parsing:** Uses structural Regex to extract exactly which applications were updated, regardless of the system language.
* **Native Toast Notifications:** Generates Windows 10/11 desktop alerts for both successful updates and failures, identifying specific packages without requiring external PowerShell modules.
* **One-Click Installation:** Automatically registers and configures the Windows Scheduled Task with the correct execution policies and network/battery conditions.

## 💻 System Requirements
* Windows 10 or Windows 11
* PowerShell 5.1 or later
* WinGet (Windows Package Manager)

## 🛠️ Installation & Usage
1. Clone or download this repository to a permanent location on your drive.
2. Right-click **`Install-Task.ps1`** and select **Run with PowerShell**.
3. The script will automatically create a Scheduled Task named `Media Expres WinGet Updater` that runs under your user profile.

## ⚠️ Known Behaviors
* WinGet blocks the `--ignore-security-hash` flag in elevated administrator sessions. If an update fails due to a hash mismatch of any software, this must be updated manually or deferred until the package repository is corrected.