# ponytail: minimal memory monitor & process analyzer for Infinix Hot 9 Play / Transsion XOS
[CmdletBinding()]
param(
    [int]$Watch = 0,
    [int]$Top = 15,
    [string]$Kill = "",
    [switch]$Snapshot
)

$ErrorActionPreference = 'Stop'

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
        Write-Host " [!] Tidak ada perangkat Infinix yang terdeteksi dalam status 'device'." -ForegroundColor Red
        return $null
    }

    $serial = ($lines[0] -split "\s+")[0]
    return $serial
}

function Get-MemoryMetrics {
    param([string]$AdbCmd)

    $procMem = & $AdbCmd shell cat /proc/meminfo
    $data = @{}
    foreach ($line in $procMem) {
        $parts = $line -split ":"
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $val = ($parts[1].Trim() -split "\s+")[0]
            if ($val -match "^\d+$") {
                $data[$key] = [int64]$val
            }
        }
    }

    $memTotal = [math]::Round($data["MemTotal"] / 1024, 1)
    $memAvail = [math]::Round($data["MemAvailable"] / 1024, 1)
    $memFree = [math]::Round($data["MemFree"] / 1024, 1)
    $memUsed = [math]::Round($memTotal - $memAvail, 1)
    $memPct = if ($memTotal -gt 0) { [math]::Round(($memUsed / $memTotal) * 100, 1) } else { 0 }

    $swapTotal = [math]::Round($data["SwapTotal"] / 1024, 1)
    $swapFree = [math]::Round($data["SwapFree"] / 1024, 1)
    $swapUsed = [math]::Round($swapTotal - $swapFree, 1)
    $swapPct = if ($swapTotal -gt 0) { [math]::Round(($swapUsed / $swapTotal) * 100, 1) } else { 0 }

    return [PSCustomObject]@{
        MemTotal  = $memTotal
        MemUsed   = $memUsed
        MemAvail  = $memAvail
        MemFree   = $memFree
        MemPct    = $memPct
        SwapTotal = $swapTotal
        SwapUsed  = $swapUsed
        SwapFree  = $swapFree
        SwapPct   = $swapPct
    }
}

function Get-TopRamProcesses {
    param(
        [string]$AdbCmd,
        [int]$Limit = 15
    )

    $dump = & $AdbCmd shell dumpsys meminfo
    $procs = @()
    $capture = $false

    foreach ($line in $dump) {
        if ($line -match "Total PSS by process:") {
            $capture = $true
            continue
        }
        if ($capture) {
            if ($line.Trim() -eq "" -or $line -match "Total PSS by OOM adjustment:" -or $line -match "Total PSS by category:") {
                break
            }
            if ($line -match "^\s*([0-9,]+)K:\s*([^\s(]+)") {
                $rawKb = [int64]($matches[1] -replace ",", "")
                $name = $matches[2].Trim()
                $mb = [math]::Round($rawKb / 1024, 1)
                $procs += [PSCustomObject]@{
                    Name  = $name
                    RamMB = $mb
                    RamKB = $rawKb
                }
            }
        }
    }

    $sorted = $procs | Sort-Object RamMB -Descending
    if ($sorted.Count -gt $Limit) {
        return $sorted[0..($Limit - 1)]
    }
    return $sorted
}

function Render-ProgressBar {
    param(
        [double]$Percentage,
        [int]$Width = 24
    )

    $filled = [int][math]::Round(($Percentage / 100) * $Width)
    if ($filled -gt $Width) { $filled = $Width }
    if ($filled -lt 0) { $filled = 0 }
    $empty = $Width - $filled

    $bar = ("#" * $filled) + ("-" * $empty)
    return "[{0}]" -f $bar
}

function Show-Dashboard {
    param(
        [string]$AdbCmd,
        [string]$Serial,
        [int]$Limit = 15
    )

    Clear-Host
    $metrics = Get-MemoryMetrics -AdbCmd $AdbCmd
    $procs = Get-TopRamProcesses -AdbCmd $AdbCmd -Limit $Limit

    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host "  INFINIX HOT 9 PLAY - RAM & BACKGROUND PROCESS ANALYZER" -ForegroundColor White
    $timeStr = Get-Date -Format 'HH:mm:ss'
    Write-Host ("  Perangkat: {0} | Target: Helio A22/A25 (XOS) | {1}" -f $Serial, $timeStr) -ForegroundColor Gray
    Write-Host "==========================================================================================" -ForegroundColor Cyan
    Write-Host ""

    # RAM Fisik
    $ramBar = Render-ProgressBar -Percentage $metrics.MemPct
    $ramColor = if ($metrics.MemPct -gt 85) { 'Red' } elseif ($metrics.MemPct -gt 70) { 'Yellow' } else { 'Green' }
    Write-Host "  RAM Fisik   : " -NoNewline
    Write-Host ("{0} {1}% " -f $ramBar, $metrics.MemPct) -ForegroundColor $ramColor -NoNewline
    Write-Host ("({0} MB terpakai / {1} MB total | Sisa Tersedia: {2} MB)" -f $metrics.MemUsed, $metrics.MemTotal, $metrics.MemAvail) -ForegroundColor Gray

    # ZRAM / Virtual RAM
    if ($metrics.SwapTotal -gt 0) {
        $swapBar = Render-ProgressBar -Percentage $metrics.SwapPct
        $swapColor = if ($metrics.SwapPct -gt 70) { 'Yellow' } else { 'Cyan' }
        Write-Host "  Virtual RAM : " -NoNewline
        Write-Host ("{0} {1}% " -f $swapBar, $metrics.SwapPct) -ForegroundColor $swapColor -NoNewline
        Write-Host ("({0} MB terpakai / {1} MB swap ZRAM)" -f $metrics.SwapUsed, $metrics.SwapTotal) -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host ("  {0,-4} | {1,-45} | {2,10} | {3}" -f "NO", "NAMA PROSES / PAKET", "RAM (MB)", "CATATAN") -ForegroundColor White
    Write-Host ("  " + ("-" * 82)) -ForegroundColor Gray

    $index = 1
    foreach ($p in $procs) {
        $tag = ""
        if ($p.Name -eq "com.transsion.phoenix") {
            $tag = "[Adware / Phoenix Browser]"
        } elseif ($p.Name -eq "com.transsion.palmstore") {
            $tag = "[Toko Transsion / Iklan]"
        } elseif ($p.Name -like "*ahagame*") {
            $tag = "[Aha Games Bloat]"
        } elseif ($p.Name -eq "com.transsion.phonemaster") {
            $tag = "[Phone Master Booster]"
        } elseif ($p.Name -eq "com.transsion.boomplayer") {
            $tag = "[Boomplay Music]"
        } elseif ($p.Name -eq "com.google.android.gms") {
            $tag = "[Google Play Services]"
        } elseif ($p.Name -like "*quicksearchbox*") {
            $tag = "[Google App]"
        } elseif ($p.Name -eq "com.android.systemui") {
            $tag = "[System UI]"
        }

        Write-Host ("  {0,4} | {1,-45} | {2,10:N1} | " -f $index, $p.Name, $p.RamMB) -NoNewline
        if ($tag -ne "") {
            Write-Host $tag -ForegroundColor Yellow
        } else {
            Write-Host ""
        }
        $index++
    }

    Write-Host ""
    Write-Host "  [!] TIPS OPTIMASI HELIO A22/A25:" -ForegroundColor Gray
    Write-Host "      1. Mencopot Phoenix Browser & Palm Store langsung menghentikan pop-up iklan background." -ForegroundColor Gray
    Write-Host "      2. Matikan 'Zero Screen' di setelan Launcher untuk membersihkan halaman feed kiri." -ForegroundColor Gray
    Write-Host ""
    return $procs
}

function Stop-TargetProcess {
    param(
        [string]$AdbCmd,
        [string]$PackageName
    )

    $protected = @("system", "com.android.systemui", "com.android.phone", "surfaceflinger", "zygote", "com.transsion.XOSLauncher")
    if ($protected -contains $PackageName) {
        Write-Host (" [!] DITOLAK: Proses '{0}' adalah komponen inti OS/Launcher dan tidak boleh dimatikan." -f $PackageName) -ForegroundColor Red
        return
    }

    Write-Host (" Menghentikan paksa (force-stop) '{0}'... " -f $PackageName) -NoNewline
    & $AdbCmd shell am force-stop $PackageName
    Write-Host "[SELESAI]" -ForegroundColor Green
}

# Main Execution Flow
$adb = Find-AdbBinary
if (-not $adb) {
    Write-Host "Error: ADB tidak ditemukan." -ForegroundColor Red
    exit 1
}

$serial = Test-AdbConnection -AdbCmd $adb
if (-not $serial) {
    exit 1
}

# Direct CLI Kill mode
if ($Kill -ne "") {
    Stop-TargetProcess -AdbCmd $adb -PackageName $Kill
    exit 0
}

# Snapshot Mode (Non-interactive)
if ($Snapshot) {
    $null = Show-Dashboard -AdbCmd $adb -Serial $serial -Limit $Top
    exit 0
}

# Watch Loop Mode
if ($Watch -gt 0) {
    Write-Host ("Menjalankan mode Live Watch (refresh tiap {0} detik). Tekan Ctrl+C untuk keluar." -f $Watch) -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    while ($true) {
        $null = Show-Dashboard -AdbCmd $adb -Serial $serial -Limit $Top
        Start-Sleep -Seconds $Watch
    }
    exit 0
}

# Snapshot & Interactive Mode
do {
    $currentProcs = Show-Dashboard -AdbCmd $adb -Serial $serial -Limit $Top

    Write-Host "Pilihan Aksi:" -ForegroundColor White
    Write-Host " [K] Hentikan paksa (Force-Stop) salah satu aplikasi di atas" -ForegroundColor White
    Write-Host " [R] Refresh / Perbarui metrik memori" -ForegroundColor White
    Write-Host " [Q] Keluar" -ForegroundColor Gray
    Write-Host ""

    $action = Read-Host "Pilih aksi (K/R/Q)"

    if ($action -match "^[kK]$") {
        $num = Read-Host ("Masukkan nomor urut proses (1-{0}) atau nama paket" -f $currentProcs.Count)
        if ($num -match "^\d+$") {
            $idx = [int]$num - 1
            if ($idx -ge 0 -and $idx -lt $currentProcs.Count) {
                $targetPkg = $currentProcs[$idx].Name
                Stop-TargetProcess -AdbCmd $adb -PackageName $targetPkg
            } else {
                Write-Host "Nomor urut di luar jangkauan." -ForegroundColor Red
            }
        } elseif ($num.Trim() -ne "") {
            Stop-TargetProcess -AdbCmd $adb -PackageName $num.Trim()
        }
        Start-Sleep -Seconds 1
    } elseif ($action -match "^[qQ]$") {
        Write-Host "Keluar dari RAM Monitor." -ForegroundColor Cyan
        break
    }
} while ($true)
