# ============================================================
# WinOptimize - i5 8350U + UHD620 + 8GB Optimized
# Author: Harry (minimalharry)
# ============================================================

# ADMIN CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run as admin!" -ForegroundColor Red
    pause; exit
}

function S($t){Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan;Write-Host " ✦ $t" -ForegroundColor Yellow}
function OK($m){Write-Host "  ✅ $m" -ForegroundColor Green}

Clear-Host

Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝
UHD620 OPTIMIZED BUILD (LOW-END TUNED)
github.com/minimalharry
"@ -ForegroundColor Magenta

# ============================================================
# 🎯 PROFILE LOCK (FOR YOUR PC)
# ============================================================
$PROFILE="LOW-END"

# ============================================================
# ⚡ POWER + CPU
# ============================================================
S "CPU + POWER OPTIMIZATION"

powercfg -setactive SCHEME_MIN
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100

OK "CPU unlocked for max performance"

# ============================================================
# 🎮 GPU (IMPORTANT FOR UHD620)
# ============================================================
S "GPU OPTIMIZATION (INTEL UHD)"

# HAGS OFF (important!)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 1 -Force

# GPU priority for Java
New-ItemProperty "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

OK "Intel GPU optimized"

# ============================================================
# 🧠 RAM (CRITICAL FIX)
# ============================================================
S "RAM FIX (MOST IMPORTANT)"

# Pagefile safe increase
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys 8192 16384"

# ENABLE SysMain (important for HDD/low RAM)
Set-Service SysMain -StartupType Automatic
Start-Service SysMain -ErrorAction SilentlyContinue

OK "RAM pressure fixed"

# ============================================================
# 🚀 STARTUP BOOST
# ============================================================
S "STARTUP OPTIMIZATION"

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

powercfg /hibernate on

OK "Boot speed improved"

# ============================================================
# 🧹 BACKGROUND CLEAN (BIG FPS BOOST)
# ============================================================
S "BACKGROUND PROCESS CLEAN"

$apps = @(
"OneDrive","Skype","Teams","Discord","Spotify","EpicGamesLauncher"
)

foreach ($app in $apps){
    Get-Process $app -ErrorAction SilentlyContinue | Stop-Process -Force
}

OK "Background apps killed"

# ============================================================
# 🎮 MINECRAFT (REAL BOOST)
# ============================================================
S "MINECRAFT OPTIMIZATION"

Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

# Disable fullscreen optimization
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f

OK "Minecraft optimized"

# ============================================================
# 🌐 NETWORK
# ============================================================
S "NETWORK LOW LATENCY"

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty $_.PSPath TcpAckFrequency 1 -Force
    Set-ItemProperty $_.PSPath TCPNoDelay 1 -Force
}

OK "Ping reduced"

# ============================================================
# 🧹 CLEANUP
# ============================================================
S "CLEANUP"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "Cleaned"

# ============================================================
# DONE
# ============================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " ✔ OPTIMIZED FOR UHD 620 SYSTEM" -ForegroundColor Green
Write-Host " ⚡ Expect smoother gameplay now" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
