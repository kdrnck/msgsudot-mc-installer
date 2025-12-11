Set-StrictMode -Version Latest

# MSGSU-DOT SMP Windows setup script

# Loads config.json.
function Load-Config {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

    if (-not (Test-Path -Path $configPath)) {
        Write-Error "config.json not found: $configPath"
        exit 1
    }

    try {
        $content = Get-Content -Path $configPath -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Error "config.json could not be read: $_"
        exit 1
    }
}

# Shows banner progressively (4 lines per second); falls back to simple title.
function Show-Banner {
    $bannerPath = Join-Path -Path $PSScriptRoot -ChildPath "banner.txt"

    if (Test-Path -Path $bannerPath) {
        $lines = Get-Content -Path $bannerPath
        foreach ($line in $lines) {
            Write-Host $line
            Start-Sleep -Milliseconds 250
        }
    }
    else {
        Write-Host "=== MSGSU-DOT SMP Setup ===" -ForegroundColor Cyan
    }

    Write-Host ""
}

# Shows system RAM info.
function Show-RamInfo {
    try {
        $memBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
        if ($memBytes) {
            $memGb = [math]::Round($memBytes / 1GB, 2)
            Write-Host "RAM Miktariniz: $memGb GB" -ForegroundColor Cyan
            Write-Host "Lütfen doğru RAM ayırmak için kurulum dökümanını kontrol ediniz." -ForegroundColor Yellow
            Write-Host ""
            return
        }
    }
    catch {
        # optional info; ignore errors
    }

    Write-Host "RAM bilgisi alınamadı. Doğrudan devam edilecek." -ForegroundColor Yellow
    Write-Host ""
}

# Ensures winget exists; otherwise exits with guidance.
function Ensure-Winget {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        return
    }

    Write-Host "Winget gerekli. Lütfen Microsoft Store'dan 'App Installer' kurun ve scripti tekrar çalıştırın." -ForegroundColor Red
    exit 1
}

# Checks Java; installs via winget if missing or too old.
function Ensure-Java {
    param (
        [Parameter(Mandatory = $true)]
        [psobject] $Config
    )

    $minMajor = [int]$Config.minJavaMajorVersion
    $javaOutput = $null
    $javaMajor = $null

    try {
        $javaOutput = & java -version 2>&1
        $match = [regex]::Match($javaOutput, 'version\s+"?(\d+)')
        if ($match.Success) {
            $javaMajor = [int]$match.Groups[1].Value
        }
    }
    catch {
        $javaOutput = $null
    }

    if ($javaMajor -ge $minMajor) {
        Write-Host "Java $javaMajor detected (required >= $minMajor)."
        return
    }

    Write-Host "Java bulunamadı veya sürümü yetersiz. Winget ile yükleniyor..." -ForegroundColor Yellow

    try {
        & winget install --id $Config.javaPackageId -e --accept-package-agreements --accept-source-agreements
        Write-Host "Java yüklemesi tamamlandı." -ForegroundColor Green
    }
    catch {
        Write-Error "Java indirmesi tamamlanamadı: $_"
        exit 1
    }
}

# Finds PolyMC; installs via winget if needed and returns full path.
function Ensure-PolyMc {
    param (
        [Parameter(Mandatory = $true)]
        [psobject] $Config
    )

    function Get-PolyMcPath {
        $cmd = Get-Command polymc.exe -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }

        foreach ($path in $Config.polyMcSearchPaths) {
            $expanded = [System.Environment]::ExpandEnvironmentVariables($path)
            if (Test-Path -Path $expanded) {
                return $expanded
            }
        }

        return $null
    }

    $foundPath = Get-PolyMcPath

    if (-not $foundPath) {
        Write-Host "PolyMC bulunamadı. Winget ile yükleniyor..." -ForegroundColor Yellow
        try {
            & winget install --id $Config.polyMcWingetId -e --accept-package-agreements --accept-source-agreements
        }
        catch {
            Write-Error "PolyMC yüklemesi tamamlanamadı: $_"
            exit 1
        }

        $foundPath = Get-PolyMcPath
    }

    if (-not $foundPath) {
        Write-Host "PolyMC hala bulunamadı. Lütfen manuel olarak kurun ve scripti tekrar çalıştırın." -ForegroundColor Red
        exit 1
    }

    Write-Host "PolyMC found: $foundPath" -ForegroundColor Green
    return $foundPath
}

# Triggers PolyMC instance import.
function Import-Instance {
    param (
        [Parameter(Mandatory = $true)]
        [string] $PolyMcExe,
        [Parameter(Mandatory = $true)]
        [string] $InstanceUrl,
        [Parameter(Mandatory = $true)]
        [string] $InstanceName
    )

    Write-Host "Importing instance: $InstanceName (source: $InstanceUrl)" -ForegroundColor Cyan

    try {
        Start-Process -FilePath $PolyMcExe -ArgumentList "-I", $InstanceUrl | Out-Null
    }
    catch {
        Write-Error "Import call failed: $_"
        exit 1
    }
}

# Shows post-install account steps.
function Show-PostInstallInstructions {
    param (
        [Parameter(Mandatory = $true)]
        [string] $InstanceName
    )

    Write-Host ""
    Write-Host "Kurulum tamamlandı. Son adımlar:" -ForegroundColor Green
    Write-Host "1) PolyMC'de Hesaplar'ı açın." -ForegroundColor Yellow
    Write-Host "2) Çevrimdışı hesap eklemek için dökümanı kontrol ediniz." -ForegroundColor Yellow
    Write-Host "3) MSGSU-DOT SMP örneği sol menüde görünecektir." -ForegroundColor Yellow
    Write-Host "4) Seçin ve OYUNA BASARAK MSGSU-DOT SMP'ye katılın." -ForegroundColor Yellow
    Write-Host ""
}

# Main flow with error guard.
function Invoke-Main {
    try {
        Set-Location -Path $PSScriptRoot
    }
    catch {
        Write-Error "Working directory could not be set: $_"
        Read-Host "Press ENTER to close"
        exit 1
    }

    Show-Banner
    Show-RamInfo
    Read-Host "Lütfen MSGSU-DOT SMP kurulumunu başlatmak için klavyenizden herhangi bir tuşa basın!"

    try {
        $config = Load-Config
        Ensure-Winget
        Ensure-Java -Config $config
        $polyMcExe = Ensure-PolyMc -Config $config
        Import-Instance -PolyMcExe $polyMcExe -InstanceUrl $config.instanceUrl -InstanceName $config.instanceName
        Show-PostInstallInstructions -InstanceName $config.instanceName
    }
    catch {
        Write-Error "Kurulum tamamlanamadı: $_"
        Read-Host "Lütfen kapatmak için klavyenizden herhangi bir tuşa basın!"
        exit 1
    }
}

Invoke-Main
exit 0
