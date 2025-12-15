# ============================================================================
# Raptacon 3200 FRC Development Environment Setup Script
# ============================================================================
# 
# Purpose: Automated installation of FRC development tools for student laptops
# 
# Features:
# - Idempotent: Safe to run multiple times
# - Retry logic for network operations
# - Modular functions for easy maintenance
# 
# Maintenance Notes:
# - Update version numbers in CONFIGURATION section below
# - Add new Chocolatey packages to $chocolateyPackages array
# - Add new VS Code extensions to Install-VSCodeExtensions function
# 
# Requirements:
# - Windows 10/11
# - Administrator privileges
# - Internet connection
# 
# ============================================================================

# ============================================================================
# CONFIGURATION - Update these values for new versions
# ============================================================================

$script:Config = @{
    # Repository URLs
    DevToolsRepo = "https://github.com/Raptacon/developer-tools.git"
    Win11DebloatRepo = "https://github.com/Raphire/Win11Debloat.git"
    
    # Local paths
    DownloadsPath = "$HOME\Downloads"
    LocalBinPath = "$env:USERPROFILE\.local\bin"
    
    # Retry configuration
    MaxRetries = 3
    RetryDelaySeconds = 5
    
    # FRC Tools URLs (Update for each season)
    REVHardwareClientURL = "https://software.revrobotics.com/rev-hardware-client/"
    PhoenixTunerXURL = "https://apps.microsoft.com/detail/9nvv4pwdw27z"
    WPILibURL = "https://github.com/wpilibsuite/allwpilib/releases/latest"
}

# Chocolatey packages to install
$script:ChocolateyPackages = @(
    "vscode",
    "git",
    "git.install",
    "github-desktop",
    "python3",
    "firefox",
    "discord",
    "fzf",
    "ripgrep",
    "microsoft-windows-terminal",
    "vim"
)

# VS Code extensions to install
$script:VSCodeExtensions = @(
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.debugpy",
    "wpilibsuite.vscode-wpilib",
    "ms-python.black-formatter",
    "ms-python.flake8",
    "eamodio.gitlens",
    "pkief.material-icon-theme",
    "oderwat.indent-rainbow",
    "streetsidesoftware.code-spell-checker"
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    $params = @{
        Object = $Message
        ForegroundColor = $Color
    }
    if ($NoNewline) { $params.NoNewline = $true }
    
    Write-Host @params
}

function Write-Section {
    param([string]$Title)
    
    Write-ColorOutput "`n=========================================" "Cyan"
    Write-ColorOutput $Title "Cyan"
    Write-ColorOutput "=========================================`n" "Cyan"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = $script:Config.MaxRetries,
        [int]$DelaySeconds = $script:Config.RetryDelaySeconds,
        [string]$OperationName = "Operation"
    )
    
    $attempt = 1
    while ($attempt -le $MaxRetries) {
        try {
            Write-ColorOutput "[$OperationName] Attempt $attempt of $MaxRetries..." "Gray"
            $result = & $ScriptBlock
            Write-ColorOutput "[$OperationName] Success!" "Green"
            return $result
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                Write-ColorOutput "[$OperationName] Failed after $MaxRetries attempts: $_" "Red"
                throw
            }
            Write-ColorOutput "[$OperationName] Attempt $attempt failed. Retrying in $DelaySeconds seconds..." "Yellow"
            Start-Sleep -Seconds $DelaySeconds
            $attempt++
        }
    }
}

function Test-CommandExists {
    param([string]$Command)
    
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Add-ToUserPath {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$Path*") {
        Write-ColorOutput "Adding $Path to user PATH..." "Gray"
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$Path", "User")
        $env:Path += ";$Path"
        return $true
    }
    return $false
}

# ============================================================================
# GIT REPOSITORY FUNCTIONS
# ============================================================================

function Test-GitInstalled {
    if (-not (Test-CommandExists "git")) {
        Write-ColorOutput "Git is not installed. Skipping repository operations." "Yellow"
        return $false
    }
    return $true
}

function Invoke-GitClone {
    param(
        [string]$RepoUrl,
        [string]$LocalPath,
        [string]$RepoName
    )
    
    if (Test-Path $LocalPath) {
        Write-ColorOutput "$RepoName already exists at $LocalPath" "Gray"
        return $false
    }
    
    Invoke-WithRetry -OperationName "Clone $RepoName" -ScriptBlock {
        git clone $RepoUrl $LocalPath
    }
    
    Write-ColorOutput "$RepoName cloned to $LocalPath" "Green"
    return $true
}

function Test-GitRepoUpdates {
    param([string]$LocalPath)
    
    Push-Location $LocalPath
    try {
        git fetch origin | Out-Null
        $localHash = git rev-parse HEAD
        $remoteHash = git rev-parse origin/main
        Pop-Location
        
        if ($localHash -ne $remoteHash) {
            Write-ColorOutput "Updates are available. Please update the repository and re-run the script." "Yellow"
            return $true
        }
        return $false
    }
    catch {
        Pop-Location
        Write-ColorOutput "Could not check for updates: $_" "Yellow"
        return $false
    }
}

# ============================================================================
# CHOCOLATEY FUNCTIONS
# ============================================================================

function Install-Chocolatey {
    if (Test-CommandExists "choco") {
        Write-ColorOutput "Chocolatey is already installed" "Gray"
        return
    }
    
    Write-ColorOutput "Installing Chocolatey..." "Yellow"
    Invoke-WithRetry -OperationName "Install Chocolatey" -ScriptBlock {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    refreshenv
    Write-ColorOutput "Chocolatey installed successfully" "Green"
}

function Install-ChocolateyPackage {
    param([string]$PackageName)
    
    $installed = choco list --local-only --exact $PackageName --limit-output
    if ($installed) {
        Write-ColorOutput "$PackageName is already installed" "Gray"
        return $false
    }
    
    Write-ColorOutput "Installing $PackageName..." "Yellow"
    Invoke-WithRetry -OperationName "Install $PackageName" -ScriptBlock {
        choco install $PackageName --yes --no-progress --limit-output
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey install failed with exit code $LASTEXITCODE"
        }
    }
    
    Write-ColorOutput "$PackageName installed successfully" "Green"
    return $true
}

# ============================================================================
# PYTHON SETUP FUNCTIONS
# ============================================================================

function New-PythonAliases {
    if (-not (Test-CommandExists "python3")) {
        Write-ColorOutput "Python3 not found. Cannot create aliases." "Yellow"
        return
    }
    
    $aliasDir = $script:Config.LocalBinPath
    $python3Path = (Get-Command python3).Source
    
    Add-ToUserPath -Path $aliasDir | Out-Null
    
    $pythonBat = "$aliasDir\python.bat"
    $pyBat = "$aliasDir\py.bat"
    
    $batchContent = "@echo off`n`"$python3Path`" %*"
    
    if (-not (Test-Path $pythonBat) -or (Get-Content $pythonBat -Raw) -ne $batchContent) {
        $batchContent | Out-File -FilePath $pythonBat -Encoding ASCII
        Write-ColorOutput "Created 'python' alias" "Green"
    }
    
    if (-not (Test-Path $pyBat) -or (Get-Content $pyBat -Raw) -ne $batchContent) {
        $batchContent | Out-File -FilePath $pyBat -Encoding ASCII
        Write-ColorOutput "Created 'py' alias" "Green"
    }
}

function Install-Pipenv {
    if (Test-CommandExists "pipenv") {
        Write-ColorOutput "Pipenv is already installed" "Gray"
        return
    }
    
    if (-not (Test-CommandExists "python3")) {
        Write-ColorOutput "Python3 not found. Cannot install pipenv." "Red"
        return
    }
    
    Write-ColorOutput "Installing pipenv via pip..." "Yellow"
    Invoke-WithRetry -OperationName "Install pipenv" -ScriptBlock {
        python3 -m pip install --user pipenv
        if ($LASTEXITCODE -ne 0) {
            throw "pip install failed"
        }
    }
    
    Write-ColorOutput "Pipenv installed successfully" "Green"
}

# ============================================================================
# VS CODE EXTENSION FUNCTIONS
# ============================================================================

function Install-VSCodeExtensions {
    if (-not (Test-CommandExists "code")) {
        Write-ColorOutput "VS Code (code) not found in PATH. Skipping extension installation." "Yellow"
        return
    }
    
    Write-Section "Installing VS Code Extensions"
    
    $installedExtensions = code --list-extensions 2>$null
    
    foreach ($extension in $script:VSCodeExtensions) {
        if ($installedExtensions -contains $extension) {
            Write-ColorOutput "$extension is already installed" "Gray"
        }
        else {
            Write-ColorOutput "Installing $extension..." "Yellow"
            code --install-extension $extension --force
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "$extension installed successfully" "Green"
            }
            else {
                Write-ColorOutput "Failed to install $extension" "Red"
            }
        }
    }
    
    Write-ColorOutput "`nVS Code extensions installation complete" "Green"
    
    # TODO: Raptacon3200 - Configure team code style/linting rules
    # Suggested implementation:
    # Create .vscode/settings.json in team repos with:
    # {
    #   "python.linting.enabled": true,
    #   "python.linting.flake8Enabled": true,
    #   "python.formatting.provider": "black",
    #   "python.formatting.blackArgs": ["--line-length", "100"],
    #   "editor.formatOnSave": true,
    #   "[python]": {
    #     "editor.defaultFormatter": "ms-python.black-formatter"
    #   }
    # }
}

# ============================================================================
# WINGET FUNCTIONS
# ============================================================================

function Install-WinGet {
    if (Test-CommandExists "winget") {
        Write-ColorOutput "WinGet is already installed" "Gray"
        return
    }
    
    Write-ColorOutput "Installing WinGet (App Installer)..." "Yellow"
    
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Write-ColorOutput "WinGet installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Could not install WinGet automatically. Please install from Microsoft Store." "Yellow"
    }
}

# ============================================================================
# FRC TOOLS FUNCTIONS
# ============================================================================

function Install-PhoenixTunerX {
    Write-ColorOutput "Installing Phoenix Tuner X..." "Yellow"
    
    if (-not (Test-CommandExists "winget")) {
        Write-ColorOutput "WinGet not available. Please install Phoenix Tuner X manually from:" "Yellow"
        Write-ColorOutput $script:Config.PhoenixTunerXURL "Cyan"
        return
    }
    
    try {
        winget install --id=CTR-Electronics.PhoenixTunerX -e --accept-source-agreements --accept-package-agreements
        Write-ColorOutput "Phoenix Tuner X installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Could not install Phoenix Tuner X via WinGet. Install manually from:" "Yellow"
        Write-ColorOutput $script:Config.PhoenixTunerXURL "Cyan"
    }
}

function Show-FRCToolsInstructions {
    Write-Section "FRC Tools - Manual Installation Required"
    
    Write-ColorOutput "The following FRC tools require manual installation:`n" "Yellow"
    
    Write-ColorOutput "1. FRC Game Tools (Driver Station, Imaging Tool)" "White"
    Write-ColorOutput "   Download from: https://www.ni.com/en/support/downloads/drivers/download.frc-game-tools.html" "Cyan"
    Write-ColorOutput "   - Create NI account (free)" "Gray"
    Write-ColorOutput "   - Download the ISO file" "Gray"
    Write-ColorOutput "   - Right-click ISO -> 'Mount'" "Gray"
    Write-ColorOutput "   - Run install.exe from mounted drive" "Gray"
    Write-ColorOutput "   - Includes: Driver Station, roboRIO Imaging Tool`n" "Gray"
    
    Write-ColorOutput "2. WPILib Suite (Robot Programming Tools)" "White"
    Write-ColorOutput "   Download from: $($script:Config.WPILibURL)" "Cyan"
    Write-ColorOutput "   - Download WPILib_Windows-*.iso" "Gray"
    Write-ColorOutput "   - Right-click ISO -> 'Mount'" "Gray"
    Write-ColorOutput "   - Run WPILibInstaller.exe" "Gray"
    Write-ColorOutput "   - Includes: VS Code WPILib, Shuffleboard, SmartDashboard, Elastic Dashboard, etc.`n" "Gray"
    
    Write-ColorOutput "   Note: Dashboard Evolution (for reference)" "DarkGray"
    Write-ColorOutput "   - SmartDashboard -> Shuffleboard -> Elastic Dashboard" "DarkGray"
    Write-ColorOutput "   - SmartDashboard & Shuffleboard are deprecated, will be removed in 2027" "DarkGray"
    Write-ColorOutput "   - Citation: https://docs.wpilib.org/en/stable/docs/software/dashboards/dashboard-intro.html" "DarkGray"
    Write-ColorOutput "   - All three are included in WPILib for compatibility`n" "DarkGray"
    
    Write-ColorOutput "3. REV Hardware Client (for REV motors/sensors)" "White"
    Write-ColorOutput "   Download from: $($script:Config.REVHardwareClientURL)" "Cyan"
    Write-ColorOutput "   - Required for SparkMax, SparkFlex, NEO motors" "Gray"
    Write-ColorOutput "   - Download and run installer`n" "Gray"
}

# ============================================================================
# WIN11DEBLOAT FUNCTION
# ============================================================================

function Install-Win11Debloat {
    param([bool]$GitAvailable)
    
    if (-not $GitAvailable) {
        Write-ColorOutput "Git not available. Skipping Win11Debloat." "Yellow"
        return
    }
    
    Write-Section "Installing Win11Debloat"
    
    $debloatPath = Join-Path $script:Config.DownloadsPath "Win11Debloat"
    $debloatScript = Join-Path $debloatPath "Win11Debloat.ps1"
    
    Invoke-GitClone -RepoUrl $script:Config.Win11DebloatRepo -LocalPath $debloatPath -RepoName "Win11Debloat"
    
    if (-not (Test-Path $debloatScript)) {
        Write-ColorOutput "Win11Debloat script not found at $debloatScript" "Red"
        return
    }
    
    Write-ColorOutput "Running Win11Debloat (interactive GUI)..." "Yellow"
    
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $debloatScript
        Write-ColorOutput "Win11Debloat completed" "Green"
    }
    catch {
        Write-ColorOutput "Win11Debloat failed: $_" "Red"
    }
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

function Test-Installation {
    param(
        [string]$Name,
        [scriptblock]$TestScript
    )
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-ColorOutput "✓ $Name" "Green" -NoNewline
            Write-ColorOutput " - $result" "Gray"
        }
        else {
            Write-ColorOutput "✗ $Name - Not installed" "Red"
        }
    }
    catch {
        Write-ColorOutput "✗ $Name - Not installed" "Red"
    }
}

function Show-InstallationSummary {
    Write-Section "Installation Verification"
    
    Test-Installation "VS Code" { 
        if (Test-CommandExists "code") { 
            (code --version)[0]
        }
    }
    
    Test-Installation "Git" { 
        if (Test-CommandExists "git") { 
            git --version
        }
    }
    
    Test-Installation "GitHub Desktop" {
        $path = "C:\Program Files\GitHub Desktop\GitHubDesktop.exe"
        if (Test-Path $path) { "Installed" }
    }
    
    Test-Installation "Python3" { 
        if (Test-CommandExists "python3") { 
            python3 --version
        }
    }
    
    Test-Installation "Python alias" { 
        if (Test-CommandExists "python") { 
            "Working -> python3"
        }
    }
    
    Test-Installation "Py alias" { 
        if (Test-CommandExists "py") { 
            "Working -> python3"
        }
    }
    
    Test-Installation "Pipenv" { 
        if (Test-CommandExists "pipenv") { 
            pipenv --version
        }
    }
    
    Test-Installation "Firefox" {
        $path = "C:\Program Files\Mozilla Firefox\firefox.exe"
        if (Test-Path $path) { "Installed" }
    }
    
    Test-Installation "Discord" {
        if (Test-Path "$env:LOCALAPPDATA\Discord\app-*\Discord.exe") { "Installed" }
    }
    
    Test-Installation "Windows Terminal" { 
        if (Test-CommandExists "wt") { 
            "Installed"
        }
    }
    
    Test-Installation "fzf" { 
        if (Test-CommandExists "fzf") { 
            fzf --version
        }
    }
    
    Test-Installation "ripgrep" { 
        if (Test-CommandExists "rg") { 
            (rg --version)[0]
        }
    }
    
    Test-Installation "Vim" { 
        if (Test-CommandExists "vim") { 
            "Installed (for Chris)"
        }
    }
}

# ============================================================================
# MAIN INSTALLATION WORKFLOW
# ============================================================================

function Start-Installation {
    Write-Section "Raptacon 3200 FRC Development Environment Setup"
    
    if (-not (Test-Administrator)) {
        Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
        Write-ColorOutput "Please restart PowerShell as Administrator and try again." "Yellow"
        exit 1
    }
    
    $gitAvailable = Test-GitInstalled
    
    if ($gitAvailable) {
        $devToolsPath = Join-Path $script:Config.DownloadsPath "developer-tools"
        Invoke-GitClone -RepoUrl $script:Config.DevToolsRepo -LocalPath $devToolsPath -RepoName "Developer Tools"
        
        if (Test-Path $devToolsPath) {
            if (Test-GitRepoUpdates -LocalPath $devToolsPath) {
                Write-ColorOutput "Please update the repository and re-run this script." "Yellow"
                exit 1
            }
        }
    }
    
    Write-Section "Installing Chocolatey Package Manager"
    Install-Chocolatey
    
    Write-Section "Installing Development Tools via Chocolatey"
    $installedPackages = @()
    foreach ($package in $script:ChocolateyPackages) {
        if (Install-ChocolateyPackage -PackageName $package) {
            $installedPackages += $package
        }
    }
    
    if ($installedPackages.Count -gt 0) {
        Write-ColorOutput "`nRefreshing environment variables..." "Yellow"
        refreshenv
    }
    
    Write-Section "Configuring Python Environment"
    New-PythonAliases
    Install-Pipenv
    refreshenv
    
    Write-Section "Installing WinGet Package Manager"
    Install-WinGet
    
    Write-Section "Installing FRC Tools"
    Install-PhoenixTunerX
    
    Install-VSCodeExtensions
    
    Show-FRCToolsInstructions
    
    Install-Win11Debloat -GitAvailable $gitAvailable
    
    Show-InstallationSummary
    
    Write-Section "Installation Complete!"
    
    Write-ColorOutput "Next Steps:" "Yellow"
    Write-ColorOutput "1. Install FRC Game Tools (see instructions above)" "White"
    Write-ColorOutput "2. Install WPILib Suite (see instructions above)" "White"
    Write-ColorOutput "3. Install REV Hardware Client (see instructions above)" "White"
    Write-ColorOutput "4. Restart your computer to ensure all PATH changes take effect" "White"
    Write-ColorOutput "5. Configure Git with your name and email:" "White"
    Write-ColorOutput "   git config --global user.name 'Your Name'" "Cyan"
    Write-ColorOutput "   git config --global user.email 'your.email@example.com'" "Cyan"
    
    Write-ColorOutput "`nFor Raptacon3200 team members:" "Yellow"
    Write-ColorOutput "- Clone team repositories from GitHub" "White"
    Write-ColorOutput "- Join team Discord server" "White"
    Write-ColorOutput "- Review .vscode/settings.json in team repos for code style rules" "White"
    
    Write-ColorOutput "`nThis script is idempotent - safe to run multiple times!" "Green"
    Write-ColorOutput "Happy coding! 🤖" "Cyan"
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

Start-Installation
