# ponytail: minimal interactive debloat & restore CLI runner for Infinix Hot 9 Play / Transsion XOS
[CmdletBinding()]
param(
    [switch]$Tier1,
    [switch]$Tier2,
    [switch]$Tier3,
    [switch]$All,
    [switch]$Restore,
    [switch]$CheckStatus
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "packages.json"
$LogFile = Join-Path $ScriptDir "debloat_history_xos.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] $Message" -ErrorAction SilentlyContinue
}

function Find-AdbBinary {
    if (Get-Command "adb" -ErrorAction SilentlyContinue) {
        return "adb"
    }

    $commonPaths = @(
        "C:\ProgramData\chocolatey\lib\scrcpy\tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\platform-tools\adb.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Test-AdbConnection {
    param([string]$AdbCmd)

    $output = & $AdbCmd devices
    $lines = @($output | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" })

    if ($lines.Count -eq 0) {
        Write-Host " [!] Tidak ada perangkat Infinix/Android yang terdeteksi dalam status 'device'." -ForegroundColor Red
        Write-Host "     Pastikan:" -ForegroundColor Yellow
        Write-Host "     1. USB Debugging aktif di Developer Options HP Infinix Anda."
        Write-Host "     2. Pop-up otorisasi di layar HP sudah disetujui (Always allow)."
        Write-Host "     3. Kabel USB terhubung dengan baik."
        return $null
    }

    $serial = ($lines[0] -split "\s+")[0]
    return $serial
}

function Get-ActivePackagesMap {
    param([string]$AdbCmd)

    $output = & $AdbCmd shell pm list packages
    $activeMap = @{}
    foreach ($line in $output) {
        if ($line -match "^package:(.+)$") {
            $activeMap[$matches[1].Trim()] = $true
        }
    }
    return $activeMap
}

function Show-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  INFINIX XOS DEBLOATER & RESTORE TOOL" -ForegroundColor White
    Write-Host "  Target: Infinix Hot 9 Play (X680 / Helio A22/A25 / XOS)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-DebloatBatch {
    param(
        [string]$AdbCmd,
        [array]$Packages,
        [string]$TierName = "Batch"
    )

    Write-Host ("Memulai proses debloat {0} (pm uninstall -k --user 0)..." -f $TierName) -ForegroundColor Cyan
    Write-Host ""

    $activeMap = Get-ActivePackagesMap -AdbCmd $AdbCmd
    $countSuccess = 0
    $countSkipped = 0

    # Whitelist proteksi absolut XOS
    $protected = @("com.transsion.batterylab", "com.transsion.zahooc", "com.transsion.plat.appupdate")

    foreach ($pkg in $Packages) {
        $id = $pkg.id
        $name = $pkg.name

        if ($protected -contains $id) {
            Write-Host (" -> {0} ({1})... [DILINDUNGI SISTEM / DILEWATI]" -f $name, $id) -ForegroundColor Yellow
            continue
        }

        Write-Host (" -> {0} ({1})... " -f $name, $id) -NoNewline

        if (-not $activeMap.ContainsKey($id)) {
            Write-Host "[SUDAH TIDAK AKTIF]" -ForegroundColor Yellow
            $countSkipped++
            Write-Log "SKIP: $id sudah tidak aktif di user 0"
            continue
        }

        $result = (& $AdbCmd shell pm uninstall -k --user 0 $id 2>&1) -join " "

        if ($result -match "Success") {
            Write-Host "[BERHASIL DICOPOT]" -ForegroundColor Green
            $countSuccess++
            Write-Log "DEBLOAT SUCCESS: $id ($TierName)"
        } else {
            Write-Host ("[GAGAL: {0}]" -f $result) -ForegroundColor Red
            Write-Log "DEBLOAT FAILED: $id ($result)"
        }
    }

    Write-Host ""
    Write-Host ("Selesai. {0} berhasil dicopot, {1} dilewati." -f $countSuccess, $countSkipped) -ForegroundColor Cyan
}

function Invoke-RestoreBatch {
    param(
        [string]$AdbCmd,
        [array]$Packages,
        [string]$TierName = "Batch"
    )

    Write-Host ("Memulai proses restore {0} (cmd package install-existing)..." -f $TierName) -ForegroundColor Cyan
    Write-Host ""

    $countSuccess = 0

    foreach ($pkg in $Packages) {
        $id = $pkg.id
        $name = $pkg.name

        Write-Host (" -> {0} ({1})... " -f $name, $id) -NoNewline

        $result = (& $AdbCmd shell cmd package install-existing $id 2>&1) -join " "

        if ($result -match "installed package $id") {
            Write-Host "[BERHASIL DIKEMBALIKAN]" -ForegroundColor Green
            $countSuccess++
            Write-Log "RESTORE SUCCESS: $id ($TierName)"
        } elseif ($result -match "doesn't exist") {
            Write-Host "[ROM TIDAK MENYEDIAKAN APK ASLI]" -ForegroundColor Red
            Write-Log "RESTORE NOT FOUND: $id"
        } else {
            Write-Host ("[{0}]" -f $result) -ForegroundColor Yellow
            Write-Log "RESTORE NOTICE: $id ($result)"
        }
    }

    Write-Host ""
    Write-Host ("Selesai. {0} paket berhasil di-restore." -f $countSuccess) -ForegroundColor Cyan
}

function Show-StatusSummary {
    param(
        [string]$AdbCmd,
        $Manifest
    )

    Write-Host "Memeriksa status paket di perangkat Infinix..." -ForegroundColor Cyan
    Write-Host ""

    $activeMap = Get-ActivePackagesMap -AdbCmd $AdbCmd

    $sections = @(
        @{ Title = $Manifest.tier1.name; Packages = $Manifest.tier1.packages },
        @{ Title = $Manifest.tier2.name; Packages = $Manifest.tier2.packages },
        @{ Title = $Manifest.tier3.name; Packages = $Manifest.tier3.packages }
    )

    foreach ($sec in $sections) {
        Write-Host ("# {0}" -f $sec.Title) -ForegroundColor White
        Write-Host ("{0,-38} | {1,-38} | {2}" -f "NAMA KOMPONEN", "PACKAGE ID", "STATUS") -ForegroundColor Gray
        Write-Host ("-" * 91) -ForegroundColor Gray

        foreach ($pkg in $sec.Packages) {
            $id = $pkg.id
            $name = $pkg.name
            $isActive = $activeMap.ContainsKey($id)

            if ($isActive) {
                Write-Host ("{0,-38} | {1,-38} | " -f $name, $id) -NoNewline
                Write-Host "AKTIF / TERPASANG" -ForegroundColor Yellow
            } else {
                Write-Host ("{0,-38} | {1,-38} | " -f $name, $id) -NoNewline
                Write-Host "TERDEBLOAT / NONAKTIF" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
}

# Main Execution Flow
if (-not (Test-Path $ConfigFile)) {
    Write-Host ("Error: File {0} tidak ditemukan." -f $ConfigFile) -ForegroundColor Red
    exit 1
}

$adb = Find-AdbBinary
if (-not $adb) {
    Write-Host "Error: Eksekutabel ADB tidak ditemukan di PATH atau lokasi standar." -ForegroundColor Red
    exit 1
}

$deviceSerial = Test-AdbConnection -AdbCmd $adb
if (-not $deviceSerial) {
    exit 1
}

$manifestData = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
$tier1Pkgs = $manifestData.tier1.packages
$tier2Pkgs = $manifestData.tier2.packages
$tier3Pkgs = $manifestData.tier3.packages
$allPkgs = @($tier1Pkgs) + @($tier2Pkgs) + @($tier3Pkgs)

if ($CheckStatus) {
    Show-Header
    Show-StatusSummary -AdbCmd $adb -Manifest $manifestData
    exit 0
}

if ($Tier1) {
    Show-Header
    Invoke-DebloatBatch -AdbCmd $adb -Packages $tier1Pkgs -TierName "Tier 1"
    exit 0
}

if ($Tier2) {
    Show-Header
    Invoke-DebloatBatch -AdbCmd $adb -Packages $tier2Pkgs -TierName "Tier 2"
    exit 0
}

if ($Tier3) {
    Show-Header
    Invoke-DebloatBatch -AdbCmd $adb -Packages $tier3Pkgs -TierName "Tier 3"
    exit 0
}

if ($All) {
    Show-Header
    Invoke-DebloatBatch -AdbCmd $adb -Packages $allPkgs -TierName "Semua Tier (1, 2, & 3)"
    exit 0
}

if ($Restore) {
    Show-Header
    Invoke-RestoreBatch -AdbCmd $adb -Packages $allPkgs -TierName "Semua Tier (1, 2, & 3)"
    exit 0
}

do {
    Show-Header
    Write-Host ("Perangkat Terhubung : {0}" -f $deviceSerial) -ForegroundColor Green
    Write-Host ("Koleksi Paket       : {0} Tier 1 | {1} Tier 2 | {2} Tier 3" -f @($tier1Pkgs).Count, @($tier2Pkgs).Count, @($tier3Pkgs).Count) -ForegroundColor Gray
    Write-Host ""
    Write-Host "Pilihan Aksi:" -ForegroundColor White
    Write-Host " [1] Debloat Tier 1 Saja (Adware, Phoenix, Palm Store, Aha Games, Telemetri)" -ForegroundColor White
    Write-Host " [2] Debloat Tier 2 Saja (Utilitas XOS: Phone Master, File Manager, Smart Panel)" -ForegroundColor White
    Write-Host " [3] Debloat Tier 3 Saja (Layanan Google Non-Esensial: Google App, TTS, Wellbeing)" -ForegroundColor White
    Write-Host " [4] Debloat Semua Paket (Tier 1 + 2 + 3)" -ForegroundColor White
    Write-Host " [5] Restore / Kembalikan Paket" -ForegroundColor White
    Write-Host " [6] Cek Status Paket (Audit Real-time XOS)" -ForegroundColor White
    Write-Host " [7] Keluar" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Masukkan pilihan Anda (1-7)"

    switch ($choice) {
        "1" {
            Show-Header
            $confirm = Read-Host ("Mencopot {0} paket Tier 1? (y/n)" -f @($tier1Pkgs).Count)
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                Invoke-DebloatBatch -AdbCmd $adb -Packages $tier1Pkgs -TierName "Tier 1"
            }
            Write-Host ""
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "2" {
            Show-Header
            $confirm = Read-Host ("Mencopot {0} paket Tier 2 (Utilitas XOS)? (y/n)" -f @($tier2Pkgs).Count)
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                Invoke-DebloatBatch -AdbCmd $adb -Packages $tier2Pkgs -TierName "Tier 2"
            }
            Write-Host ""
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "3" {
            Show-Header
            $confirm = Read-Host ("Mencopot {0} paket Tier 3 (Google Non-Essential)? (y/n)" -f @($tier3Pkgs).Count)
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                Invoke-DebloatBatch -AdbCmd $adb -Packages $tier3Pkgs -TierName "Tier 3"
            }
            Write-Host ""
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "4" {
            Show-Header
            $confirm = Read-Host ("Mencopot SEMUA {0} paket (Tier 1 + 2 + 3)? (y/n)" -f @($allPkgs).Count)
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                Invoke-DebloatBatch -AdbCmd $adb -Packages $allPkgs -TierName "Semua Tier"
            }
            Write-Host ""
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "5" {
            Show-Header
            Write-Host "Opsi Restore:" -ForegroundColor White
            Write-Host " [1] Restore Tier 1 Saja"
            Write-Host " [2] Restore Tier 2 Saja"
            Write-Host " [3] Restore Tier 3 Saja"
            Write-Host " [4] Restore Semua Paket"
            $rChoice = Read-Host "Pilih (1-4)"
            switch ($rChoice) {
                "1" { Invoke-RestoreBatch -AdbCmd $adb -Packages $tier1Pkgs -TierName "Tier 1" }
                "2" { Invoke-RestoreBatch -AdbCmd $adb -Packages $tier2Pkgs -TierName "Tier 2" }
                "3" { Invoke-RestoreBatch -AdbCmd $adb -Packages $tier3Pkgs -TierName "Tier 3" }
                "4" { Invoke-RestoreBatch -AdbCmd $adb -Packages $allPkgs -TierName "Semua Tier" }
                default { Write-Host "Dibatalkan." -ForegroundColor Gray }
            }
            Write-Host ""
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "6" {
            Show-Header
            Show-StatusSummary -AdbCmd $adb -Manifest $manifestData
            Read-Host "Tekan Enter untuk kembali ke menu..."
        }
        "7" {
            Write-Host "Selesai. Sampai jumpa!" -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Pilihan tidak valid." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "7")
