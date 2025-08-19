# VRPSolverInstall

This repository is designed as a series of scripts to assist new users in installing VRPSolver. 
The workflow is designed for installation via WSL (Windows Subsystem for Linux) on Windows, although it might also find use for dedicated linux users (dual-boot or similar). 

## Basic Usage (Windows)
 
1. Download this repository in a common folder:

On this page click on *Code* > *Download ZIP*. Save it to the *Downloads* folder.
  If you are familiar with git, you might clone this repo in a preferred manner.
   
3. Open PowerShell as Administrator
  To run PowerShell as an administrator, search for "PowerShell" in the Start menu, right-click on it, and select "Run as administrator."
  Alternatively, you can press Win + R, type "powershell," and then press Ctrl + Shift + Enter.

5. Go to the repository folder.
  If you have downloaded a zip file and unzipped it in the Downloads folder, then run the following: 
  ```powershell
  cd Downloads\VRPSolverInstall-main\
  ```

1. **Save the script** as `part1_wsl_setup.ps1`
2. Save 
3. **Run PowerShell as Administrator**
4. **Download CPLEX for Linux x86-64**
5. **Execute with parameters:**

```powershell
# Basic installation with Ubuntu 22.04 (default)
.\part1_wsl_setup.ps1

# Specify Ubuntu version and libraries
.\part1_wsl_setup.ps1 -UbuntuVersion "20.04" -Libraries @("git", "curl", "vim", "build-essential")

# Include a script to run inside WSL
.\part1_wsl_setup.ps1 -UbuntuVersion "22.04" -Libraries @("python3", "python3-pip") -ScriptToRun "C:\path\to\your\script.sh"
```

## What the script does:

1. **Checks administrator privileges** (required for Windows features)
2. **Enables WSL and Virtual Machine Platform** Windows features
3. **Downloads and installs WSL kernel update**
4. **Sets WSL 2 as the default version**
5. **Installs the specified Ubuntu version** from Microsoft Store
6. **Initializes Ubuntu** (prompts for username/password on first run)
7. **Updates the Ubuntu system**
8. **Installs specified libraries** using apt
9. **Copies and runs your custom script** inside WSL
10. **Displays final WSL configuration**

## Example for a development setup:

```powershell
.\part1_wsl_setup.ps1 -UbuntuVersion "22.04" -Libraries @("git", "curl", "wget", "build-essential", "python3", "python3-pip", "nodejs", "npm") -ScriptToRun "C:\dev\setup-dev-environment.sh"
```

## Notes:

- The script requires **administrator privileges**
- **Restart may be required** after enabling Windows features
- **Supported Ubuntu versions**: 18.04, 20.04, 22.04, 24.04
- Your custom script should be a bash script (`.sh`) that will run inside the Ubuntu environment
