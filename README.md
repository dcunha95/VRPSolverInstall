# VRPSolverInstall

This repository is designed as a series of scripts to assist new users in installing VRPSolver. 
The workflow is designed for assisting installation via WSL (Windows Subsystem for Linux) on Windows, although it might also find use for dedicated linux users (dual-boot or similar). 

If you are using Windows, please make sure you are running the latest version of 10 or 11 to avoid headaches and follow the main usage guide.

If you are already using Linux, you will only need to follow steps 1, 4, 5 and 7. 
Note that the script is designed for Ubuntu 22.04 LTS, so if you are using another distro you will need to modify the script `part2_linux_setup.sh` to use the appropriate package manager, and possibly solve other issues. 

**DISCLAIMER**: Please note that the provided scripts come with no warranty, of any kind. 

If you run into any issues, please open an issue.

## Main usage guide 

1. **Open PowerShell as Administrator and install git**

To run PowerShell as an administrator, search for "PowerShell" in the Start menu, right-click on it, and select "Run as administrator."
Alternatively, you can press Win + R, type "powershell," and then press Ctrl + Shift + Enter. 

After that install git, if you don't have it (copy-paste the snippet below in your PowerShell terminal and press Enter):

```powershell
cd ~
winget install --id Git.Git -e --source winget
```

After the installation is complete, refresh your PowerShell terminal (close and reopen it as administrator)
   
2. **Clone this repository to the Downloads folder**
 
Go to the *Downloads* folder directory, clone this repository and enter it (copy-paste the snippet below in your PowerShell terminal and press Enter):

```powershell
cd ~/Downloads
git clone https://github.com/dcunha95/VRPSolverInstall.git
cd VRPSolverInstall
```

3. **Download BaPCod**

Go to the website (https://bapcod-process.math.u-bordeaux.fr/index.html#download), fill the form, accept the agreement and download the zip file.

Make sure to download to the repository folder (e.g. `Downloads\VRPSolverInstall-main`), as the script will use it.

4. **Download CPLEX**

For academics, go the website (https://academic.ibm.com/a2mt/), register and download CPLEX **FOR LINUX x86-64**.
It should be under the *Data Science* field. 
When selecting the correct version, you might set the download method to HTTP if you don't want to install IBM's dedicated installer.

Make sure to download to the repository folder (e.g. `Downloads\VRPSolverInstall-main`), as the script will use it.


5. **Run the part 1 script: Install WSL**

<!-- ```powershell
# Basic installation with Ubuntu 22.04 (default)
.\part1_wsl_setup.ps1

# Specify Ubuntu version and libraries
.\part1_wsl_setup.ps1 -UbuntuVersion "20.04" -Libraries @("git", "curl", "vim", "build-essential")

# Include a script to run inside WSL
.\part1_wsl_setup.ps1 -UbuntuVersion "22.04" -Libraries @("python3", "python3-pip") -ScriptToRun "C:\path\to\your\script.sh"
``` -->

Run the first part of the script to install WSL with Ubuntu 22.04, saving the log with the `Start-Transcript` utility:

```powershell
Start-Transcript -Append part1_wsl_setup.log
.\part1_wsl_setup.ps1
Stop-Transcript
```

If the script asks to reboot the machine, please do so, repeat steps 2 (open PowerShell as administrator) and continue the setup by running:

```powershell
cd ~\Downloads\VRPSolverInstall-main
Start-Transcript -Append part1_wsl_setup.log
.\part1_wsl_setup.ps1 -Phase2
Stop-Transcript
```

6. **Run the part 2: Setup the linux environment**

You should now have a copy of the repository in your home directory in linux with copies of CPLEX and BaPCod inside.
Open the terminal with your preferred method (Ctrl+Alt+T), go to the repo folder and provide permissions to run the script `part2_linux_setup.sh`:

```bash
cd VRPSolverInstall
chmod +x part2_linux_setup.sh
```

It should look something like the picture below:

<img width="1471" height="211" alt="image" src="https://github.com/user-attachments/assets/d9f0bee8-1e26-48b5-a5eb-ef8015b5b812" />

Originally the script would be run with the command `./part2_linux_setup.sh`. However, we also desire to store a log. We also desire to reload to refresh the terminal with the new environment variables. Thus we run the following:
 
```bash
script -c "./part2_linux_setup.sh" ./part2_linux_setup.log
source ~/.bashrc
```

Note that you will likely be asked to provide your password, as `sudo` is required for CPLEX and several packages installation. Aditionally, Julia installation will require some interactivity (accept agreements, default install location etc). 

