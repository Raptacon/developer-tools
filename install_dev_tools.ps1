# Install Chocolatey if not installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
}

# Function to check if a program is installed via Chocolatey
function Install-ChocolateyPackage {
    param (
        [string]$packageName
    )

    if (-not (choco list --local-only | Select-String $packageName)) {
        choco install $packageName -y;
    }
}

# Install Visual Studio Code, Git, Git Bash using Chocolatey
Install-ChocolateyPackage -packageName "vscode"
Install-ChocolateyPackage -packageName "git"
Install-ChocolateyPackage -packageName "git.install"
Install-ChocolateyPackage -packageName "Git-Credential-Manager-for-Windows"
Install-ChocolateyPackage -packageName "github-desktop"
Install-ChocolateyPackage -packageName "python"
Install-ChocolateyPackage -packageName "pipenv"
Install-ChocolateyPackage -packageName "firefox"
Install-ChocolateyPackage -packageName "discord"

# Verify the installations
Write-Output "Visual Studio Code version:";
if (Get-Command code -ErrorAction SilentlyContinue) {
    code --version;
} else {
    Write-Output "Visual Studio Code is not installed.";
}

Write-Output "Git version:";
if (Get-Command git -ErrorAction SilentlyContinue) {
    git --version;
} else {
    Write-Output "Git is not installed.";
}

Write-Output "Git Bash version:";
if (Get-Command bash -ErrorAction SilentlyContinue) {
    bash --version;
} else {
    Write-Output "Git Bash is not installed.";
}

Write-Output "GitHub Desktop version:";
$githubDesktopPath = "C:\Program Files\GitHub Desktop\GitHubDesktop.exe"
if (Test-Path $githubDesktopPath) {
    & $githubDesktopPath --version;
} else {
    Write-Output "GitHub Desktop is not installed.";
}

Write-Output "Python version:";
if (Get-Command python -ErrorAction SilentlyContinue) {
    python --version;
} else {
    Write-Output "Python is not installed.";
}

Write-Output "Pip version:";
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip --version;
} else {
    Write-Output "Pip is not installed.";
}

Write-Output "Pipenv version:";
if (Get-Command pipenv -ErrorAction SilentlyContinue) {
    pipenv --version;
} else {
    Write-Output "Pipenv is not installed.";
}

Write-Output "Firefox version:";
$firefoxPath = "C:\Program Files\Mozilla Firefox\firefox.exe"
if (Test-Path $firefoxPath) {
    & $firefoxPath -v | Select-String -Pattern "Mozilla Firefox";
} else {
    Write-Output "Firefox is not installed.";
}

Write-Output "Discord version:";
$discordPath = "C:\Users\$env:USERNAME\AppData\Local\Discord\app-*\Discord.exe"
if (Test-Path $discordPath) {
    & $discordPath --version;
} else {
    Write-Output "Discord is not installed.";
}
