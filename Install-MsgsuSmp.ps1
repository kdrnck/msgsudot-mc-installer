# MSGSU-DOT SMP Windows kurulum scripti

# config.json'u yükler.
function Load-Config {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

    if (-not (Test-Path -Path $configPath)) {
        Write-Error "config.json bulunamadı: $configPath"
        exit 1
    }

    try {
        $content = Get-Content -Path $configPath -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Error "config.json okunamadı: $_"
        exit 1
    }
}

# Banner gösterir; yoksa basit başlık yazar.
function Show-Banner {
    $bannerPath = Join-Path -Path $PSScriptRoot -ChildPath "banner.txt"

    if (Test-Path -Path $bannerPath) {
        Get-Content -Path $bannerPath | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Host "=== MSGSU-DOT SMP Kurulum ===" -ForegroundColor Cyan
    }

    Write-Host ""
}

# Sistemdeki RAM bilgisini gösterir.
function Show-RamInfo {
    try {
        $memBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
        if ($memBytes) {
            $memGb = [math]::Round($memBytes / 1GB, 2)
            Write-Host "RAM: $memGb GB" -ForegroundColor Cyan
            Write-Host "Size önerilen RAM için kurulum dökümanını kontrol ediniz." -ForegroundColor Yellow
            Write-Host ""
            return
        }
    }
    catch {
        # sessizce geç; zorunlu değil
    }

    Write-Host "RAM bilgisi alınamadı. Kurulum dökümanına bakarak RAM önerisini kontrol edin." -ForegroundColor Yellow
    Write-Host ""
}

# Winget var mı kontrol eder, yoksa uyarı ile çıkar.
function Ensure-Winget {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        return
    }

    Write-Host "Winget gerekli. Lütfen Microsoft Store'dan 'App Installer' kurun ve scripti tekrar çalıştırın." -ForegroundColor Red
    exit 1
}

# Java sürümünü kontrol eder, gerekirse winget ile kurar.
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
        Write-Host "Java $javaMajor tespit edildi (gereken >= $minMajor)."
        return
    }

    Write-Host "Java bulunamadı veya sürüm yetersiz. winget ile kuruluyor..." -ForegroundColor Yellow

    try {
        & winget install --id $Config.javaPackageId -e --accept-package-agreements --accept-source-agreements
        Write-Host "Java kurulumu tamamlandı." -ForegroundColor Green
    }
    catch {
        Write-Error "Java kurulumu başarısız: $_"
        exit 1
    }
}

# PolyMC'yi arar, gerekirse winget ile kurar ve tam yolunu döndürür.
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
        Write-Host "PolyMC bulunamadı. winget ile kuruluyor..." -ForegroundColor Yellow
        try {
            & winget install --id $Config.polyMcWingetId -e --accept-package-agreements --accept-source-agreements
        }
        catch {
            Write-Error "PolyMC kurulumu başarısız: $_"
            exit 1
        }

        $foundPath = Get-PolyMcPath
    }

    if (-not $foundPath) {
        Write-Host "PolyMC hala bulunamadı. Lütfen manuel kurup scripti tekrar çalıştırın." -ForegroundColor Red
        exit 1
    }

    Write-Host "PolyMC bulundu: $foundPath" -ForegroundColor Green
    return $foundPath
}

# PolyMC instance import çağrısını tetikler.
function Import-Instance {
    param (
        [Parameter(Mandatory = $true)]
        [string] $PolyMcExe,
        [Parameter(Mandatory = $true)]
        [string] $InstanceUrl,
        [Parameter(Mandatory = $true)]
        [string] $InstanceName
    )

    Write-Host "Instance import ediliyor: $InstanceName (kaynak: $InstanceUrl)" -ForegroundColor Cyan

    try {
        Start-Process -FilePath $PolyMcExe -ArgumentList "-I", $InstanceUrl | Out-Null
    }
    catch {
        Write-Error "Import çağrısı başarısız: $_"
        exit 1
    }
}

# Son kullanıcıya hesap ekleme adımlarını hatırlatır.
function Show-PostInstallInstructions {
    param (
        [Parameter(Mandatory = $true)]
        [string] $InstanceName
    )

    Write-Host ""
    Write-Host "Kurulum tamamlandı. Son adımlar:" -ForegroundColor Green
    Write-Host "1) PolyMC açılınca Accounts/Hesaplar bölümüne git." -ForegroundColor Yellow
    Write-Host "2) Gerekirse 'Add Microsoft' ile giriş yap, ya da izin veriyorsa 'Add offline account' ile nick ekle." -ForegroundColor Yellow
    Write-Host "3) Sol tarafta '$InstanceName' gözükecek." -ForegroundColor Yellow
    Write-Host "4) Instance'a tıklayıp PLAY diyerek MSGSU-DOT SMP'ye bağlan." -ForegroundColor Yellow
    Write-Host ""
}

# --- Ana akış ---
try {
    Set-Location -Path $PSScriptRoot
}
catch {
    Write-Error "Çalışma klasörü ayarlanamadı: $_"
    exit 1
}

Show-Banner
Show-RamInfo
Read-Host "MSGSU-DOT SMP kurulumuna başlamak için ENTER'a bas"

$config = Load-Config
Ensure-Winget
Ensure-Java -Config $config
$polyMcExe = Ensure-PolyMc -Config $config
Import-Instance -PolyMcExe $polyMcExe -InstanceUrl $config.instanceUrl -InstanceName $config.instanceName
Show-PostInstallInstructions -InstanceName $config.instanceName

Read-Host "Kapatmak için ENTER'a bas"

