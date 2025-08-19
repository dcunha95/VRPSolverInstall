# WSL Setup and Configuration Script
# Run as Administrator

param(
    [string]$UbuntuVersion = "22.04",
    [string]$ScriptToRun = "",
    [string[]]$Libraries = @()
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

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Log "This script must be run as Administrator" "ERROR"
    Write-Log "Please right-click PowerShell and select 'Run as Administrator'" "ERROR"
    pause
    exit 1
}

Write-Log "Starting WSL setup process..."

# Step 1: Enable WSL and Virtual Machine Platform features
Write-Log "Enabling WSL and Virtual Machine Platform features..."
try {
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    
    if ($wslFeature.State -ne "Enabled") {
        Write-Log "Enabling WSL feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    }
    
    if ($vmFeature.State -ne "Enabled") {
        Write-Log "Enabling Virtual Machine Platform feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    }
    
    Write-Log "Windows features enabled successfully" "SUCCESS"
} catch {
    Write-Log "Failed to enable Windows features: $($_.Exception.Message)" "ERROR"
    exit 1
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
try {
    # Start Ubuntu to trigger initial setup
    $ubuntuExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps" -Filter "ubuntu*.exe" | Select-Object -First 1
    if ($ubuntuExe) {
        Write-Log "Please complete the Ubuntu initial setup (create username and password)..."
        & $ubuntuExe.FullName
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
        
        wsl -d Ubuntu -- bash -c "cp /mnt/c/'$($ScriptToRun.Replace('\', '/').Replace('C:', ''))' $wslScriptPath"
        wsl -d Ubuntu -- bash -c "chmod +x $wslScriptPath"
        wsl -d Ubuntu -- bash -c "$wslScriptPath"
        
        Write-Log "Script executed successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to execute script: $($_.Exception.Message)" "ERROR"
    }
} elseif ($ScriptToRun) {
    Write-Log "Script file not found: $ScriptToRun" "WARNING"
}

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

Write-Log "WSL setup process completed!" "SUCCESS"
Write-Host "`nYou can now use WSL by typing 'wsl' or 'ubuntu' in PowerShell or Command Prompt." -ForegroundColor Green

# Pause to allow user to read output
pause