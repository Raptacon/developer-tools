# developer-tools
A Repo for Installing Developer Tools

## Installation
### Windows

You MUST run 

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

before you run the install script. 

Open an Admin powershell and copy and paste that code. 

Then download the script in the repo and run it.
