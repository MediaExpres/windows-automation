# Media Expres WinGet Background Automation

A lightweight, zero-dependency, and securely hardened automation toolkit for Windows. It silently keeps all WinGet packages up to date in the background, complete with native desktop alerts.

## 🚀 Features
* **Silent Execution:** Runs completely hidden in the background 15 minutes after user logon.
* **Smart Output Parsing:** Uses structural Regex to extract exactly which applications were updated, regardless of the system language.
* **Native Toast Notifications:** Generates Windows 10/11 desktop alerts for both successful updates and failures, identifying specific packages without requiring external PowerShell modules.
* **Hardened Security:** Automatically locks down folder permissions (ACLs), resolves absolute paths to prevent hijacking, and pins script integrity hashes in the Windows Registry to prevent tampering.
* **Single-File Deployment:** A unified setup script handles environment creation, payload generation, and Windows Scheduled Task registration in one go.

## 💻 System Requirements
* Windows 10 or Windows 11
* PowerShell 5.1 or later
* WinGet (Windows Package Manager)

## 🛠️ Installation & Usage
Because this script enforces strict security protocols (locking down folder ACLs and pinning registry hashes), it must be installed by an Administrator.

1. Clone or download this repository to your machine.
2. Right-click your Start button and open **Terminal (Admin)** or **Windows PowerShell (Admin)**.
3. Navigate to the folder where you extracted the files:
   ```powershell
   cd C:\Path\To\windows-automation
   ```
4. Run the setup script:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\Setup-WinGetAutomation.ps1
   ```
5. The script will securely deploy the background updater to `C:\Automation` and register the Scheduled Task. It will run silently 15 minutes after you log in.

## ⚠️ Known Behaviors
* WinGet blocks the `--ignore-security-hash` flag in elevated administrator sessions. If an update fails due to a hash mismatch (often seen with software like CCleaner), it must be updated manually or deferred until the package repository is corrected.