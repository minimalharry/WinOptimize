# ============================================================
# WinOptimize FINAL (Stable + Smart + Boot Optimized)
# Author: Harry (minimalharry)
# ============================================================

# ADMIN CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run as Administrator!" -ForegroundColor Red
    pause; exit
}

# ================= UI =================
function Section($t){
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  ✦ $t" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}
function OK($m){Write-Host "  ✅ $m" -ForegroundColor Green}
function INFO($m){Write-Host "  ℹ️  $m" -ForegroundColor DarkCyan}

Clear-Host

Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

        WinOptimize FINAL ENGINE
        github.com/minimalharry
"@ -ForegroundColor Magenta

# ================= MAIN MENU =================
Section "MAIN MENU"

$main = @(
    "Start Optimization",
    "Show System Info",
    "Exit"
)

for ($i=0; $i -lt $main.Count; $i++){
    Write-Host " [$i] $($main[$i])"
}

$mainChoice = Read-Host "`nSelect option"

if ($mainChoice -eq "2"){ exit }

# ================= SYSTEM INFO =================
if ($mainChoice -eq "1") {
    Section "SYSTEM INFO"

    $cpu = (Get-CimInstance Win32_Processor).Name
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $gpu = (Get-CimInstance Win32_VideoController).Name

    INFO "CPU: $cpu"
    INFO "RAM: ${ram}GB"
    INFO "GPU: $gpu"

    pause
    exit
}

# ================= RESET =================
Section "RESET OLD SETTINGS"

Set-Service SysMain -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service SysMain -ErrorAction SilentlyContinue

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force -ErrorAction SilentlyContinue

Set-ItemProperty "HKCU:\System\GameConfigStore" `
-Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue

Remove-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -ErrorAction SilentlyContinue

OK "Old tweaks reset"

# ================= WINDOWS SELECT =================
Section "SELECT WINDOWS VERSION"

$win = @("Windows 10","Windows 11")

for ($i=0; $i -lt $win.Count; $i++){
    Write-Host " [$i] $($win[$i])"
}

$winChoice = Read-Host "`nEnter option"

# ================= MODE SELECT =================
Section "SELECT MODE"

$modes = @(
    "Full Optimize (Recommended)",
    "Gaming Mode",
    "Boot Optimization Only",
    "RAM Cleanup Only"
)

for ($i=0; $i -lt $modes.Count; $i++){
    Write-Host " [$i] $($modes[$i])"
}

$mode = Read-Host "`nEnter option"

# ================= BASE OPTIMIZATION =================
Section "BASE OPTIMIZATION"

powercfg -setactive SCHEME_MIN
powercfg /hibernate on
bcdedit /timeout 2 | Out-Null

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

OK "Boot base optimized"

# ================= WINDOWS SPECIFIC =================
if ($winChoice -eq "0") {
    Section "WINDOWS 10 TWEAKS"

    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 1 -Force

    OK "Windows 10 tuned"
}
elseif ($winChoice -eq "1") {
    Section "WINDOWS 11 TWEAKS"

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 2 -Force

    OK "Windows 11 tuned"
}

# ================= MODE LOGIC =================

# FULL
if ($mode -eq "0") {

Section "FULL OPTIMIZATION"

# Startup apps clean (safe)
$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup | ForEach-Object {
    $_.PSObject.Properties | Where-Object {$_.Name -notmatch "SecurityHealth"} | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}

# Services trim (safe only)
$services = "DiagTrack","MapsBroker","Fax"
foreach ($s in $services){
    Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
}

# Pagefile (safe)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys 8192 16384"

OK "Full optimization done"
}

# GAMING
elseif ($mode -eq "1") {

Section "GAMING MODE"

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

Set-ItemProperty "HKCU:\System\GameConfigStore" GameDVR_Enabled 0 -Force

OK "Gaming optimized"
}

# BOOT
elseif ($mode -eq "2") {

Section "BOOT OPTIMIZATION"

Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Updater|Telemetry"
} | Disable-ScheduledTask -ErrorAction SilentlyContinue

OK "Boot improved"
}

# RAM
elseif ($mode -eq "3") {

Section "RAM CLEAN"

Get-Process | Where-Object {
    $_.ProcessName -match "Discord|Spotify|Teams|Skype"
} | Stop-Process -Force -ErrorAction SilentlyContinue

[System.GC]::Collect()

OK "RAM freed"
}

# ================= FINAL CLEAN =================
Section "FINAL CLEAN"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "Cleaned"

# ================= REBOOT =================
Write-Host "`nReboot recommended (Y/N): " -NoNewline
$r = Read-Host

if ($r -eq "Y" -or $r -eq "y") {
    Write-Host "Rebooting..." -ForegroundColor Red
    Start-Sleep 3
    Restart-Computer -Force
}

Write-Host "`nDone!"
