# WSL Setup Script - Phase 1 (Pre-Restart)
# Run as Administrator

param(
    [string]$UbuntuVersion = "22.04",
    [string]$ScriptToRun = "",
    [string[]]$Libraries = @(),
    [switch]$Phase2 = $false
)

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

# Save parameters for Phase 2
function Save-Phase2Config {
    $configPath = "$env:TEMP\wsl-setup-config.json"
    $config = @{
        UbuntuVersion = $UbuntuVersion
        ScriptToRun = $ScriptToRun
        Libraries = $Libraries
    }
    $config | ConvertTo-Json | Set-Content -Path $configPath
    Write-Log "Configuration saved for Phase 2: $configPath"
}

# Load parameters for Phase 2
function Load-Phase2Config {
    $configPath = "$env:TEMP\wsl-setup-config.json"
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath | ConvertFrom-Json
        return $config
    }
    return $null
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Log "This script must be run as Administrator" "ERROR"
    Write-Log "Please right-click PowerShell and select 'Run as Administrator'" "ERROR"
    pause
    exit 1
}

if (-not $Phase2) {
    # PHASE 1: Pre-Restart Setup
    Write-Log "=== PHASE 1: Pre-Restart Setup ===" "SUCCESS"
    Write-Log "Starting WSL setup process..."

    # Save configuration for Phase 2
    Save-Phase2Config

    # Step 1: Enable WSL and Virtual Machine Platform features
    Write-Log "Enabling WSL and Virtual Machine Platform features..."
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        
        $restartRequired = $false
        
        if ($wslFeature.State -ne "Enabled") {
            Write-Log "Enabling WSL feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            $restartRequired = $true
        } else {
            Write-Log "WSL feature already enabled"
        }
        
        if ($vmFeature.State -ne "Enabled") {
            Write-Log "Enabling Virtual Machine Platform feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
            $restartRequired = $true
        } else {
            Write-Log "Virtual Machine Platform already enabled"
        }
        
        if ($restartRequired) {
            Write-Log "Windows features enabled successfully" "SUCCESS"
            Write-Host ""
            Write-Host "===============================================" -ForegroundColor Yellow
            Write-Host "RESTART REQUIRED!" -ForegroundColor Red
            Write-Host "===============================================" -ForegroundColor Yellow
            Write-Host "After restarting, run this command to continue:" -ForegroundColor Cyan
            Write-Host ".\setup-wsl.ps1 -Phase2" -ForegroundColor Green
            Write-Host ""
            
            $restart = Read-Host "Would you like to restart now? (y/N)"
            if ($restart -match "^[Yy]") {
                Write-Log "Restarting system..."
                Restart-Computer -Force
            } else {
                Write-Log "Please restart manually and run: .\setup-wsl.ps1 -Phase2"
            }
        } else {
            Write-Log "Features already enabled, proceeding to Phase 2..."
            & $PSCommandPath -Phase2
        }
    } catch {
        Write-Log "Failed to enable Windows features: $($_.Exception.Message)" "ERROR"
        exit 1
    }

} else {
    # PHASE 2: Post-Restart Setup
    Write-Log "=== PHASE 2: Post-Restart Setup ===" "SUCCESS"
    
    # Load saved configuration
    $config = Load-Phase2Config
    if ($config) {
        $UbuntuVersion = $config.UbuntuVersion
        $ScriptToRun = $config.ScriptToRun
        $Libraries = $config.Libraries
        Write-Log "Loaded configuration from Phase 1"
    }

    # Step 2: Download and install WSL kernel update
    Write-Log "Checking for WSL kernel update..."
    try {
        $kernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $kernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"
        
        if (-not (Test-Path $kernelUpdatePath)) {
            Write-Log "Downloading WSL kernel update..."
            Invoke-WebRequest -Uri $kernelUpdateUrl -OutFile $kernelUpdatePath -UseBasicParsing
        }
        
        Write-Log "Installing WSL kernel update..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelUpdatePath, "/quiet", "/norestart" -Wait
        Write-Log "WSL kernel update installed successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to install WSL kernel update: $($_.Exception.Message)" "WARNING"
    }

    # Step 3: Set WSL 2 as default version
    Write-Log "Setting WSL 2 as default version..."
    try {
        wsl --set-default-version 2
        Write-Log "WSL 2 set as default version" "SUCCESS"
    } catch {
        Write-Log "Failed to set WSL 2 as default: $($_.Exception.Message)" "WARNING"
    }

    # Step 4: Install specified Ubuntu version
    Write-Log "Installing Ubuntu $UbuntuVersion..."
    try {
        # Map version to store package name
        $ubuntuPackages = @{
            "18.04" = "Ubuntu.1804"
            "20.04" = "Ubuntu.2004"
            "22.04" = "Ubuntu.2204" 
            "24.04" = "Ubuntu.2404"
        }
        
        $packageName = $ubuntuPackages[$UbuntuVersion]
        if (-not $packageName) {
            Write-Log "Unsupported Ubuntu version: $UbuntuVersion" "ERROR"
            Write-Log "Supported versions: $($ubuntuPackages.Keys -join ', ')" "ERROR"
            exit 1
        }
        
        # Check if Ubuntu is already installed
        $installedDistros = wsl --list --quiet 2>$null
        $ubuntuInstalled = $installedDistros | Where-Object { $_ -match "Ubuntu" }
        
        if (-not $ubuntuInstalled) {
            Write-Log "Installing Ubuntu $UbuntuVersion from Microsoft Store..."
            winget install --id $packageName --source msstore --accept-package-agreements --accept-source-agreements
            Write-Log "Ubuntu $UbuntuVersion installed successfully" "SUCCESS"
        } else {
            Write-Log "Ubuntu is already installed" "WARNING"
        }
    } catch {
        Write-Log "Failed to install Ubuntu: $($_.Exception.Message)" "ERROR"
        exit 1
    }

    # Step 5: Initialize Ubuntu (first run)
    Write-Log "Initializing Ubuntu (this may take a few minutes)..."
    Write-Log "Please complete the Ubuntu initial setup when prompted (create username and password)..."
    try {
        # Try different ways to launch Ubuntu
        $launched = $false
        
        # Try ubuntu.exe first
        if (Get-Command "ubuntu.exe" -ErrorAction SilentlyContinue) {
            ubuntu.exe
            $launched = $true
        } else {
            # Try to find Ubuntu executable in WindowsApps
            $ubuntuExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps" -Filter "ubuntu*.exe" | Select-Object -First 1
            if ($ubuntuExe) {
                & $ubuntuExe.FullName
                $launched = $true
            }
        }
        
        if (-not $launched) {
            Write-Log "Could not automatically launch Ubuntu. Please run 'ubuntu' from Start Menu to complete setup." "WARNING"
            pause
        }
    } catch {
        Write-Log "Failed to initialize Ubuntu: $($_.Exception.Message)" "ERROR"
    }

    # Step 6: Update Ubuntu system
    Write-Log "Updating Ubuntu system..."
    try {
        wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y"
        Write-Log "Ubuntu system updated successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to update Ubuntu system: $($_.Exception.Message)" "WARNING"
    }

    # Step 7: Install specified libraries
    if ($Libraries.Count -gt 0) {
        Write-Log "Installing specified libraries: $($Libraries -join ', ')..."
        try {
            $libraryString = $Libraries -join ' '
            wsl -d Ubuntu -- bash -c "sudo apt install -y $libraryString"
            Write-Log "Libraries installed successfully" "SUCCESS"
        } catch {
            Write-Log "Failed to install some libraries: $($_.Exception.Message)" "WARNING"
        }
    }

    # Step 8: Copy and run additional script if specified
    if ($ScriptToRun -and (Test-Path $ScriptToRun)) {
        Write-Log "Copying and executing script: $ScriptToRun..."
        try {
            # Copy script to WSL
            $scriptName = Split-Path $ScriptToRun -Leaf
            $wslScriptPath = "/tmp/$scriptName"
            
            # Convert Windows path to WSL path
            $windowsPath = $ScriptToRun.Replace('\', '/').Replace('C:', '/mnt/c')
            wsl -d Ubuntu -- bash -c "cp '$windowsPath' $wslScriptPath"
            wsl -d Ubuntu -- bash -c "chmod +x $wslScriptPath"
            wsl -d Ubuntu -- bash -c "$wslScriptPath"
            
            Write-Log "Script executed successfully" "SUCCESS"
        } catch {
            Write-Log "Failed to execute script: $($_.Exception.Message)" "ERROR"
        }
    } elseif ($ScriptToRun) {
        Write-Log "Script file not found: $ScriptToRun" "WARNING"
    }

    # Step 9: Setup shortcut
    $ShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\WSL.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.HotKey = "CTRL+ALT+T"
    $Shortcut.Save()

    # Step 9: Display WSL information
    Write-Log "WSL setup completed! Here's your current configuration:"
    try {
        Write-Host "`nInstalled WSL distributions:" -ForegroundColor Cyan
        wsl --list --verbose
        
        Write-Host "`nWSL version:" -ForegroundColor Cyan
        wsl --version
    } catch {
        Write-Log "Could not retrieve WSL information" "WARNING"
    }

    # Clean up configuration file
    $configPath = "$env:TEMP\wsl-setup-config.json"
    if (Test-Path $configPath) {
        Remove-Item $configPath -Force
    }

    Write-Log "WSL setup process completed!" "SUCCESS"
    Write-Host "`nYou can now use WSL by typing 'wsl' or 'ubuntu' in PowerShell or Command Prompt, or use the shortcut CTRL+ALT+T." -ForegroundColor Green
}

# Pause to allow user to read output
pause
