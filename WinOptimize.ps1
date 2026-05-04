# ============================================================
# WinOptimize PRO (Menu + Boot + Gaming + RAM Focus)
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

# FIXED ASCII
Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

        WinOptimize PRO ENGINE
        github.com/minimalharry
"@ -ForegroundColor Magenta

# ============================================================
# MENU (LIKE PTERODACTYL STYLE)
# ============================================================
$options = @(
    "Full Optimize (Recommended)",
    "Gaming Mode (Max FPS)",
    "Boot Optimization Only",
    "RAM Cleanup + Background Kill",
    "Restore Defaults"
)

Write-Host "`nSelect Option:`n" -ForegroundColor Cyan
for ($i=0; $i -lt $options.Count; $i++){
    Write-Host " [$i] $($options[$i])"
}

$choice = Read-Host "`nEnter option"

# ============================================================
# [0] FULL OPTIMIZE
# ============================================================
if ($choice -eq "0") {

S "FULL SYSTEM OPTIMIZATION"

# POWER
powercfg -setactive SCHEME_MIN

# CPU priority
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
-Name Win32PrioritySeparation -Value 26 -Force

# GPU (IMPORTANT)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force

# RAM (SAFE)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys 8192 16384"

Set-Service SysMain -StartupType Automatic
Start-Service SysMain -ErrorAction SilentlyContinue

# STARTUP (REAL FIX)
bcdedit /timeout 2 | Out-Null
powercfg /hibernate on

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

# REMOVE STARTUP APPS
$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup | ForEach-Object {
    $_.PSObject.Properties | Where-Object {$_.Name -notmatch "SecurityHealth"} | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}

# SERVICES TRIM (SAFE)
$services = "DiagTrack","MapsBroker","RetailDemo","Fax"
foreach ($s in $services){
    Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
}

OK "Full optimization applied"
}

# ============================================================
# [1] GAMING MODE
# ============================================================
elseif ($choice -eq "1") {

S "GAMING MODE (FPS BOOST)"

powercfg -setactive SCHEME_MIN

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

Set-ItemProperty "HKCU:\System\GameConfigStore" GameDVR_Enabled 0 -Force

OK "Gaming mode enabled"
}

# ============================================================
# [2] BOOT OPTIMIZATION
# ============================================================
elseif ($choice -eq "2") {

S "BOOT TIME OPTIMIZATION"

bcdedit /timeout 2 | Out-Null
powercfg /hibernate on

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Updater|Telemetry"
} | Disable-ScheduledTask -ErrorAction SilentlyContinue

OK "Boot optimized"
}

# ============================================================
# [3] RAM CLEAN
# ============================================================
elseif ($choice -eq "3") {

S "RAM CLEAN + BACKGROUND KILL"

Get-Process | Where-Object {
    $_.ProcessName -match "Discord|Spotify|Teams|Skype"
} | Stop-Process -Force -ErrorAction SilentlyContinue

[System.GC]::Collect()

OK "RAM freed"
}

# ============================================================
# [4] RESTORE
# ============================================================
elseif ($choice -eq "4") {

S "RESTORE DEFAULTS"

Set-Service SysMain -StartupType Automatic
Start-Service SysMain

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force

Set-ItemProperty "HKCU:\System\GameConfigStore" GameDVR_Enabled 1 -Force

OK "System restored"
}

# ============================================================
# DONE
# ============================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✔ OPERATION COMPLETED" -ForegroundColor Green
Write-Host "  ⚡ WinOptimize PRO Active" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
