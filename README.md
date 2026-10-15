# developer-tools
A Repo for Installing Developer Tools

## Installation
### Windows

You MUST run 

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
```

before you run the install script. 

Open an Admin powershell and copy and paste that code. 

Then download the script in the repo and run it.

### Linux

### OSX

## Tools

- [`qr-generator/`](qr-generator/README.md) — generates branded Raptacon 3200 QR
  codes (logo-in-center) for check-in / sign-up forms and other links.
  - [Ready-made codes](qr-generator/README.md#ready-made-codes): print-ready
    PNGs for every team form and link, in [`qr-generator/codes/`](qr-generator/codes/).
