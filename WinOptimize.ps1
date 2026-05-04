# ============================================================
# WinOptimize PRO ULTIMATE
# Author: Harry (https://github.com/minimalharry/)
# ============================================================

# ADMIN CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run as Administrator!" -ForegroundColor Red
    pause; exit
}

# UI FUNCTIONS
function S($t){
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  ✦ $t" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}
function OK($m){Write-Host "  ✅ $m" -ForegroundColor Green}
function INFO($m){Write-Host "  ℹ️  $m" -ForegroundColor Cyan}

Clear-Host

# ASCII (FIXED)
Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

        WinOptimize PRO ULTIMATE
        github.com/minimalharry
"@ -ForegroundColor Magenta

# ============================================================
# RESET OLD SETTINGS (IMPORTANT FOR RE-RUN)
# ============================================================
S "RESET OLD SETTINGS"

Set-Service SysMain -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service SysMain -ErrorAction SilentlyContinue

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force -ErrorAction SilentlyContinue

Set-ItemProperty "HKCU:\System\GameConfigStore" `
-Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue

Remove-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -ErrorAction SilentlyContinue

OK "Old tweaks reset"

# ============================================================
# WINDOWS SELECTION MENU
# ============================================================
S "SELECT WINDOWS VERSION"

$winOptions = @(
    "Windows 10",
    "Windows 11"
)

for ($i=0; $i -lt $winOptions.Count; $i++){
    Write-Host " [$i] $($winOptions[$i])"
}

$winChoice = Read-Host "`nEnter Windows option"

# ============================================================
# MODE MENU
# ============================================================
S "SELECT OPTIMIZATION MODE"

$options = @(
    "Full Optimize (Recommended)",
    "Gaming Mode (Minecraft FPS)",
    "Boot Optimization Only",
    "RAM Cleanup Only"
)

for ($i=0; $i -lt $options.Count; $i++){
    Write-Host " [$i] $($options[$i])"
}

$choice = Read-Host "`nEnter option"

# ============================================================
# COMMON OPTIMIZATION
# ============================================================
S "COMMON OPTIMIZATION"

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
    S "WINDOWS 10 SETTINGS"

    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 1 -Force

    OK "Windows 10 optimized"
}
elseif ($winChoice -eq "1") {
    S "WINDOWS 11 SETTINGS"

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
    -Name HwSchMode -Value 2 -Force

    Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue

    OK "Windows 11 optimized"
}

# ============================================================
# MODE BASED LOGIC
# ============================================================

# FULL
if ($choice -eq "0") {

S "FULL OPTIMIZATION"

# Startup clean
$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup | ForEach-Object {
    $_.PSObject.Properties | Where-Object {$_.Name -notmatch "SecurityHealth"} | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}

# Services trim
$services = "DiagTrack","MapsBroker","Fax"
foreach ($s in $services){
    Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
}

# Pagefile safe
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys 8192 16384"

OK "Full optimization done"
}

# GAMING
elseif ($choice -eq "1") {

S "GAMING MODE"

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

Set-ItemProperty "HKCU:\System\GameConfigStore" GameDVR_Enabled 0 -Force

OK "Gaming optimized"
}

# BOOT
elseif ($choice -eq "2") {

S "BOOT OPTIMIZATION"

bcdedit /timeout 2 | Out-Null

Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Updater|Telemetry"
} | Disable-ScheduledTask -ErrorAction SilentlyContinue

OK "Boot improved"
}

# RAM
elseif ($choice -eq "3") {

S "RAM CLEAN"

Get-Process | Where-Object {
    $_.ProcessName -match "Discord|Spotify|Teams|Skype"
} | Stop-Process -Force -ErrorAction SilentlyContinue

[System.GC]::Collect()

OK "RAM freed"
}

# ============================================================
# CLEANUP
# ============================================================
S "FINAL CLEANUP"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "System cleaned"

# ============================================================
# DONE
# ============================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✔ ALL TASKS COMPLETED" -ForegroundColor Green
Write-Host "  ⚡ WinOptimize PRO ULTIMATE ACTIVE" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
