# MSGSU-DOT SMP Windows Setup Script

This project automates Java 21 (Temurin), PolyMC, and MSGSU-DOT SMP PolyMC instance import with a single PowerShell script. Only account setup inside PolyMC remains for the user.

## Usage
- Double-click: `Install-MsgsuSmp.cmd` (calls PowerShell with `Bypass`).
- Alternative: right-click `Install-MsgsuSmp.ps1` → **Run with PowerShell**.
- The script checks Java and PolyMC, installs via winget if needed, and imports the instance into PolyMC.
- When PolyMC opens:
  1) Go to Accounts.
  2) Use "Add Microsoft" or, if allowed, "Add offline account".
  3) In the left menu select the imported `MSGSU-DOT SMP` instance and press PLAY.

## Dev note (LLM collaboration)
- You can request patch-style changes, e.g.:  
  - `Install-MsgsuSmp.ps1 dosyasindaki Ensure-PolyMc fonksiyonuna X davranisini ekle`
- Structure:
  - `config.json`: settings
  - `banner.txt`: ASCII banner
  - `Install-MsgsuSmp.ps1`: main script

