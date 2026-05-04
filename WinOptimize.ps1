# ============================================================
# WinOptimize PRO (Windows 10 / 11 Aware)
# Author: Harry (minimalharry)
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

Clear-Host

# CLEAN ASCII
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
# WINDOWS SELECTION MENU
# ============================================================
$options = @(
    "Windows 10 Optimization",
    "Windows 11 Optimization"
)

Write-Host "`nWhich Windows are you using?" -ForegroundColor Cyan
for ($i=0; $i -lt $options.Count; $i++){
    Write-Host " [$i] $($options[$i])"
}

$choice = Read-Host "`nEnter option"

# ============================================================
# COMMON OPTIMIZATION (BOTH)
# ============================================================
S "COMMON OPTIMIZATION"

# POWER
powercfg -setactive SCHEME_MIN

# CPU priority
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
-Name Win32PrioritySeparation -Value 26 -Force

# Startup delay remove
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

# Boot timeout reduce
bcdedit /timeout 2 | Out-Null

# Fast startup ON
powercfg /hibernate on

OK "Base optimization applied"

# ============================================================
# WINDOWS 10
# ============================================================
if ($choice -eq "0") {

S "WINDOWS 10 OPTIMIZATION"

# Disable Xbox DVR
Set-ItemProperty "HKCU:\System\GameConfigStore" GameDVR_Enabled 0 -Force

# Disable telemetry
Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue

# GPU scheduling OFF (stable)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force

# SysMain ON (important low RAM)
Set-Service SysMain -StartupType Automatic
Start-Service SysMain

OK "Windows 10 optimized"
}

# ============================================================
# WINDOWS 11
# ============================================================
elseif ($choice -eq "1") {

S "WINDOWS 11 OPTIMIZATION"

# HAGS ON (Win11 better support)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 2 -Force

# Disable widgets & background junk
Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue

# Disable telemetry
Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue

# SysMain ON
Set-Service SysMain -StartupType Automatic
Start-Service SysMain

OK "Windows 11 optimized"
}

# ============================================================
# STARTUP CLEAN (REAL IMPACT)
# ============================================================
S "STARTUP CLEAN"

$startupPaths = @(
"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        $props = Get-ItemProperty $path
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notmatch "SecurityHealth") {
                Remove-ItemProperty -Path $path -Name $p.Name -ErrorAction SilentlyContinue
            }
        }
    }
}

OK "Startup cleaned"

# ============================================================
# GAMING (MINECRAFT)
# ============================================================
S "GAMING BOOST"

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass = "High"
}

New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

OK "Minecraft optimized"

# ============================================================
# CLEANUP
# ============================================================
S "CLEANUP"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "Cleaned"

# ============================================================
# DONE
# ============================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✔ OPTIMIZATION COMPLETE" -ForegroundColor Green
Write-Host "  ⚡ Windows tuned successfully" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
