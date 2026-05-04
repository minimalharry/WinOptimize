# ============================================================
# WinOptimize ULTIMATE (Menu + Boot + Gaming + Safe Engine)
# Author: Harry (minimalharry)
# ============================================================

# ADMIN CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run as Administrator!" -ForegroundColor Red
    pause; exit
}

# UI
function S($t){
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  ✦ $t" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}
function OK($m){Write-Host "  ✅ $m" -ForegroundColor Green}

Clear-Host

Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

        WinOptimize ULTIMATE
        github.com/minimalharry
"@ -ForegroundColor Magenta

# ============================================================
# MAIN MENU
# ============================================================
S "MAIN MENU"

$mainOptions = @(
    "Optimization (Windows Tuning)",
    "System Info",
    "Exit"
)

for ($i=0; $i -lt $mainOptions.Count; $i++){
    Write-Host " [$i] $($mainOptions[$i])"
}

$mainChoice = Read-Host "`nSelect option"

if ($mainChoice -eq "2"){ exit }

# ============================================================
# SYSTEM INFO
# ============================================================
if ($mainChoice -eq "1") {
    S "SYSTEM INFO"

    $cpu = (Get-CimInstance Win32_Processor).Name
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $gpu = (Get-CimInstance Win32_VideoController).Name

    Write-Host "CPU: $cpu"
    Write-Host "RAM: ${ram}GB"
    Write-Host "GPU: $gpu"

    pause
    exit
}

# ============================================================
# RESET OLD SETTINGS
# ============================================================
S "RESET OLD SETTINGS"

Set-Service SysMain -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service SysMain -ErrorAction SilentlyContinue

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force -ErrorAction SilentlyContinue

OK "Old tweaks reset"

# ============================================================
# WINDOWS SELECTION
# ============================================================
S "SELECT WINDOWS VERSION"

$winOptions = @("Windows 10","Windows 11")

for ($i=0; $i -lt $winOptions.Count; $i++){
    Write-Host " [$i] $($winOptions[$i])"
}

$winChoice = Read-Host "`nEnter option"

# ============================================================
# MODE MENU
# ============================================================
S "SELECT MODE"

$options = @(
    "Full Optimize",
    "Gaming Mode",
    "Boot Optimization",
    "RAM Cleanup"
)

for ($i=0; $i -lt $options.Count; $i++){
    Write-Host " [$i] $($options[$i])"
}

$choice = Read-Host "`nEnter option"

# ============================================================
# COMMON OPTIMIZATION
# ============================================================
S "BASE OPTIMIZATION"

powercfg -setactive SCHEME_MIN
bcdedit /timeout 2 | Out-Null
powercfg /hibernate on

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

OK "Base tweaks applied"

# ============================================================
# WINDOWS SPECIFIC
# ============================================================
if ($winChoice -eq "0") {
    S "WINDOWS 10 TWEAKS"

    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 1 -Force
}

elseif ($winChoice -eq "1") {
    S "WINDOWS 11 TWEAKS"

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 2 -Force
}

# ============================================================
# MODE EXECUTION
# ============================================================

# FULL
if ($choice -eq "0") {

S "FULL OPTIMIZATION"

$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup | ForEach-Object {
    $_.PSObject.Properties | Where-Object {$_.Name -notmatch "SecurityHealth"} | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys 8192 16384"

OK "Full optimization applied"
}

# GAMING
elseif ($choice -eq "1") {

S "GAMING MODE"

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

OK "Gaming optimized"
}

# BOOT
elseif ($choice -eq "2") {

S "BOOT OPTIMIZATION"

Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Updater|Telemetry"
} | Disable-ScheduledTask -ErrorAction SilentlyContinue

OK "Boot optimized"
}

# RAM
elseif ($choice -eq "3") {

S "RAM CLEANUP"

Get-Process | Where-Object {
    $_.ProcessName -match "Discord|Spotify|Teams|Skype"
} | Stop-Process -Force -ErrorAction SilentlyContinue

[System.GC]::Collect()

OK "RAM cleaned"
}

# ============================================================
# CLEANUP
# ============================================================
S "FINAL CLEANUP"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "System cleaned"

# ============================================================
# REBOOT OPTION
# ============================================================
Write-Host "`nReboot recommended (Y/N): " -NoNewline
$r = Read-Host

if ($r -eq "Y" -or $r -eq "y") {
    Write-Host "Rebooting..." -ForegroundColor Red
    Start-Sleep 3
    Restart-Computer -Force
}

Write-Host "`nDone!"
