# Define the GitHub repository and local path
$repoUrl = "https://github.com/Raptacon/developer-tools.git"
$localRepoPath = "$HOME\Downloads\developer-tools"
$scriptPath = "$localRepoPath\install_dev_tools.ps1"

# Function to check if Git is installed
function Check-GitInstalled {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "Git is not installed. Skipping repository cloning and update checks."
        return $false
    } else {
        return $true
    }
}

# Function to clone the repository if it doesn't exist
function Clone-RepoIfNotExists {
    param (
        [string]$repoUrl,
        [string]$localRepoPath
    )

    if (-not (Test-Path $localRepoPath)) {
        git clone $repoUrl $localRepoPath
        Write-Output "Repository cloned to $localRepoPath."
    } else {
        Write-Output "Repository already exists at $localRepoPath."
    }
}

# Function to check for updates in the repository
function Check-ForUpdates {
    param (
        [string]$localRepoPath
    )

    Push-Location $localRepoPath
    git fetch origin
    $localHash = git rev-parse HEAD
    $remoteHash = git rev-parse origin/main
    Pop-Location

    if ($localHash -ne $remoteHash) {
        Write-Error "Updates are available. Please update the repository and re-run the script."
        return $true
    } else {
        Write-Output "No updates found. Proceeding with the script."
        return $false
    }
}


# Check if Git is installed
$gitInstalled = Check-GitInstalled

if ($gitInstalled) {
    # Clone the repository if it doesn't exist
    Clone-RepoIfNotExists -repoUrl $repoUrl -localRepoPath $localRepoPath

    # Ensure the script is running from the cloned repository
    $currentDir = Get-Location
    if ($currentDir -ne (Get-Item $localRepoPath).FullName) {
        Write-Warning "The script is not running from the cloned repository at $localRepoPath."
        $response = Read-Host "Do you want to proceed anyway? (yes/no)"
        if ($response -ne "yes") {
            Write-Output "Please navigate to $localRepoPath and re-run the script."
            exit 1
        }
    }

    # Check for updates
    if (Check-ForUpdates -localRepoPath $localRepoPath) {
        exit 1
    }
}

# Ensure Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
}

# Function to install Chocolatey packages only if not installed
function Install-ChocolateyPackage {
    param (
        [string]$packageName
    )

    if (-not (choco list --local-only | Select-String $packageName)) {
        choco install $packageName -y;
    }
}

# Install Visual Studio Code, Git, and Git Bash
Install-ChocolateyPackage -packageName "vscode"
Install-ChocolateyPackage -packageName "git"
Install-ChocolateyPackage -packageName "git.install"
Install-ChocolateyPackage -packageName "Git-Credential-Manager-for-Windows"
Install-ChocolateyPackage -packageName "github-desktop"
Install-ChocolateyPackage -packageName "python"
Install-ChocolateyPackage -packageName "pipenv"
Install-ChocolateyPackage -packageName "firefox"
Install-ChocolateyPackage -packageName "discord"
# So Chris isn't crippled
Install-ChocolateyPackage -packageName "vim"

# Verify the installations
Write-Output "Visual Studio Code version:"
if (Get-Command code -ErrorAction SilentlyContinue) {
    code --version
} else {
    Write-Output "Visual Studio Code is not installed."
}

Write-Output "Git version:"
if (Get-Command git -ErrorAction SilentlyContinue) {
    git --version
} else {
    Write-Output "Git is not installed."
}

Write-Output "Git Bash version:"
if (Get-Command bash -ErrorAction SilentlyContinue) {
    bash --version
} else {
    Write-Output "Git Bash is not installed."
}

Write-Output "GitHub Desktop version:"
$githubDesktopPath = "C:\Program Files\GitHub Desktop\GitHubDesktop.exe"
if (Test-Path $githubDesktopPath) {
    & $githubDesktopPath --version
} else {
    Write-Output "GitHub Desktop is not installed."
}

Write-Output "Python version:"
if (Get-Command python -ErrorAction SilentlyContinue) {
    python --version
} else {
    Write-Output "Python is not installed."
}

Write-Output "Pip version:"
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip --version
} else {
    Write-Output "Pip is not installed."
}

Write-Output "Pipenv version:"
if (Get-Command pipenv -ErrorAction SilentlyContinue) {
    pipenv --version
} else {
    Write-Output "Pipenv is not installed."
}

Write-Output "Firefox version:"
$firefoxPath = "C:\Program Files\Mozilla Firefox\firefox.exe"
if (Test-Path $firefoxPath) {
    & $firefoxPath -v | Select-String -Pattern "Mozilla Firefox"
} else {
    Write-Output "Firefox is not installed."
}

Write-Output "Discord version:"
$discordPath = "C:\Users\$env:USERNAME\AppData\Local\Discord\app-*\Discord.exe"
if (Test-Path $discordPath) {
    & $discordPath --version
} else {
    Write-Output "Discord is not installed."
}
