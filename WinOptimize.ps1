# ============================================================
#  WinOptimize Ultimate (Interactive Edition)
#  Author: Harry (https://github.com/minimalharry/)
# ============================================================


# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Administrator ke saath chalao! Right-click > Run as Administrator" -ForegroundColor Red
    pause
    exit
}

# Colors ke saath output function
function Write-Section($title) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  ✦ $title" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Write-OK($msg)   { Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "  ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }

Clear-Host
Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

   Windows Optimizer (Minecraft / Gaming Boost)
   GitHub: https://github.com/minimalharry/
"@ -ForegroundColor Magenta

Write-Host "  System: $env:COMPUTERNAME | User: $env:USERNAME" -ForegroundColor DarkGray
Write-Host "  Date: $(Get-Date -Format 'dd-MM-yyyy HH:mm')`n" -ForegroundColor DarkGray

# ─── 1. GAMING FPS BOOST ───────────────────────────────────
Write-Section "GAMING FPS BOOST"

# Ultimate Performance Power Plan
Write-Info "Ultimate Performance power plan enable kar raha hoon..."
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
$ultimatePlan = powercfg -list | Select-String "Ultimate Performance"
if ($ultimatePlan) {
    $guid = ($ultimatePlan -split "\s+")[3]
    powercfg -setactive $guid
    Write-OK "Ultimate Performance Power Plan active!"
} else {
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-OK "High Performance Power Plan active!"
}

# Game Mode enable
Write-Info "Windows Game Mode enable kar raha hoon..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
Write-OK "Game Mode enabled!"

# Hardware Accelerated GPU Scheduling (HAGS)
Write-Info "Hardware Accelerated GPU Scheduling enable kar raha hoon..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force
Write-OK "HAGS enabled! (Reboot ke baad apply hoga)"

# Xbox Game Bar disable (FPS drain karta hai)
Write-Info "Xbox Game Bar disable kar raha hoon..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
Write-OK "Xbox Game Bar disabled!"

# Nagle's Algorithm disable (network latency kam karta hai)
Write-Info "Nagle's Algorithm disable kar raha hoon..."
$tcpParams = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem $tcpParams | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}
Write-OK "Nagle's Algorithm disabled! (Low latency gaming)"

# Mouse acceleration off
Write-Info "Mouse acceleration disable kar raha hoon..."
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
Write-OK "Mouse acceleration disabled!"

# Visual effects performance ke liye
Write-Info "Visual effects optimize kar raha hoon..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force
Write-OK "Visual effects: Performance mode!"

# ─── 2. RAM & CACHE OPTIMIZATION ──────────────────────────
Write-Section "RAM & CACHE OPTIMIZATION"

# Virtual Memory optimize
Write-Info "Virtual Memory (Pagefile) optimize kar raha hoon..."
$ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1MB
$initialSize = [math]::Round($ram * 1.5)
$maximumSize = [math]::Round($ram * 3)
$cs = Get-WmiObject -Class Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $false
$cs.Put() | Out-Null
$pagefileSetting = Get-WmiObject -Class Win32_PageFileSetting
if ($pagefileSetting) {
    $pagefileSetting.InitialSize = $initialSize
    $pagefileSetting.MaximumSize = $maximumSize
    $pagefileSetting.Put() | Out-Null
}
Write-OK "Pagefile set: Initial=${initialSize}MB, Max=${maximumSize}MB"

# Standby memory clear karne ka scheduled task
Write-Info "RAM cache auto-clear scheduled task bana raha hoon..."
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NonInteractive -WindowStyle Hidden -Command `"& {`$mem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(500MB); [System.Runtime.InteropServices.Marshal]::FreeHGlobal(`$mem); [GC]::Collect()}`""
$taskTrigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 30) -Once -At (Get-Date)
$taskSettings = New-ScheduledTaskSettingsSet -Hidden
Register-ScheduledTask -TaskName "WinOptimize-RAMClear" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -RunLevel Highest -Force | Out-Null
Write-OK "RAM auto-clear task registered (har 30 min)!"

# SysMain (SuperFetch) — Gaming ke liye off
Write-Info "SysMain service optimize kar raha hoon..."
Set-Service -Name "SysMain" -StartupType Disabled
Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
Write-OK "SysMain disabled! (RAM free rahegi)"

# Large System Cache disable
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -Type DWord -Force
Write-OK "Large System Cache disabled!"

# ─── 3. STARTUP CLEANUP ────────────────────────────────────
Write-Section "STARTUP CLEANUP"

# Unnecessary startup programs disable
Write-Info "Gereksiz startup programs check kar raha hoon..."
$startupPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

$bloatStartup = @(
    "OneDrive", "Skype", "Discord", "Teams",
    "Spotify", "EpicGamesLauncher", "AdobeUpdater",
    "GoogleUpdate", "iTunesHelper"
)

$removedCount = 0
foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        $entries = Get-ItemProperty -Path $path
        foreach ($bloat in $bloatStartup) {
            if ($entries.$bloat) {
                Remove-ItemProperty -Path $path -Name $bloat -ErrorAction SilentlyContinue
                Write-OK "Startup se remove kiya: $bloat"
                $removedCount++
            }
        }
    }
}
if ($removedCount -eq 0) { Write-OK "Startup already clean hai!" }

# Unnecessary services disable
Write-Info "Unnecessary services disable kar raha hoon..."
$services = @(
    @{Name="DiagTrack"; Display="Telemetry"},
    @{Name="WSearch"; Display="Windows Search (Gaming ke liye off)"},
    @{Name="Fax"; Display="Fax Service"},
    @{Name="RetailDemo"; Display="Retail Demo Service"},
    @{Name="MapsBroker"; Display="Maps Broker"},
    @{Name="lfsvc"; Display="Geolocation Service"}
)

foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service) {
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Write-OK "$($svc.Display) disabled!"
    }
}

# Temp files clean
Write-Info "Temp files clean kar raha hoon..."
$tempPaths = @($env:TEMP, $env:TMP, "C:\Windows\Temp", "C:\Windows\Prefetch")
$totalCleaned = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $totalCleaned += $size
    }
}
$cleanedMB = [math]::Round($totalCleaned / 1MB, 2)
Write-OK "Temp files cleaned: ${cleanedMB}MB free hua!"

# DNS Cache flush
Write-Info "DNS Cache flush kar raha hoon..."
ipconfig /flushdns | Out-Null
Write-OK "DNS Cache flushed!"

# ─── DONE ──────────────────────────────────────────────────
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  🎉 OPTIMIZATION COMPLETE!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
Write-Host "  ⚡ Gaming FPS Boost    ✅ Done" -ForegroundColor White
Write-Host "  🧹 Startup Cleanup     ✅ Done" -ForegroundColor White
Write-Host "  🧠 RAM Optimization    ✅ Done" -ForegroundColor White
Write-Host "`n  ⚠️  REBOOT karo changes apply karne ke liye!" -ForegroundColor Yellow
Write-Host "`n  Reboot karna chahte ho? (Y/N): " -ForegroundColor Cyan -NoNewline
$reboot = Read-Host
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "  Rebooting in 5 seconds..." -ForegroundColor Red
    Start-Sleep 5
    Restart-Computer -Force
}
