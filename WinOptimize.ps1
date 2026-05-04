# ============================================================
#  WinOptimize ULTRA (Linux-style Smart Optimizer)
#  Author: Harry (https://github.com/minimalharry/)
# ============================================================

# ADMIN CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Run as Administrator!" -ForegroundColor Red
    pause
    exit
}

# UI
function S($t){Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan;Write-Host " ✦ $t" -ForegroundColor Yellow}
function OK($m){Write-Host "  ✅ $m" -ForegroundColor Green}
function INFO($m){Write-Host "  ℹ️  $m" -ForegroundColor Cyan}

Clear-Host

# FIXED CLEAN ASCII
Write-Host @"
██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

     WinOptimize ULTRA (AI + Linux Style)
     github.com/minimalharry
"@ -ForegroundColor Magenta

# ============================================================
# 🔍 FULL HARDWARE SCAN
# ============================================================
S "FULL HARDWARE SCAN"

$cpu = Get-CimInstance Win32_Processor
$ram = Get-CimInstance Win32_PhysicalMemory
$gpu = Get-CimInstance Win32_VideoController

$cpuName = $cpu.Name
$cores = $cpu.NumberOfCores
$threads = $cpu.NumberOfLogicalProcessors

$ramTotal = [math]::Round(($ram.Capacity | Measure-Object -Sum).Sum / 1GB)
$ramSpeed = ($ram.Speed | Select-Object -First 1)
$ramType = ($ram.MemoryType | Select-Object -First 1)

$gpuName = $gpu.Name

INFO "CPU: $cpuName"
INFO "Cores: $cores | Threads: $threads"
INFO "RAM: $ramTotal GB @ ${ramSpeed}MHz"
INFO "GPU: $gpuName"

# ============================================================
# 🧠 PROFILE ENGINE
# ============================================================
S "AI PERFORMANCE PROFILE"

if ($ramTotal -le 8 -or $cores -le 4) {
    $PROFILE="LOW"
}
elseif ($ramTotal -le 16) {
    $PROFILE="MID"
}
else {
    $PROFILE="HIGH"
}

OK "Profile: $PROFILE"

# ============================================================
# ⚡ BOOT TIME OPTIMIZATION (IMPORTANT)
# ============================================================
S "BOOT OPTIMIZATION"

# Disable startup delay
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
-Name StartupDelayInMSec -Value 0 -Force -ErrorAction SilentlyContinue

# Fast startup enable
powercfg /hibernate on
OK "Fast boot enabled"

# Disable useless startup apps (hard cleanup)
$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup | ForEach-Object {
    $_.PSObject.Properties | Where-Object {$_.Name -notmatch "SecurityHealth"} | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}

OK "Startup cleaned (fast boot)"

# ============================================================
# 🧠 CPU SCHEDULER TUNING
# ============================================================
S "CPU OPTIMIZATION"

# Prioritize foreground apps (games)
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
-Name Win32PrioritySeparation -Value 26 -Force

OK "CPU scheduling optimized"

# ============================================================
# 🎮 GPU + MINECRAFT ENGINE
# ============================================================
S "GAMING ENGINE"

# GPU scheduling
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
-Name HwSchMode -Value 2 -Force

# Minecraft boost
Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PriorityClass="High"
}

New-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
-Name "javaw.exe" -Value "GpuPreference=2;" -Force | Out-Null

OK "Minecraft + GPU optimized"

# ============================================================
# 🧠 RAM ENGINE (SAFE + SMART)
# ============================================================
S "MEMORY ENGINE"

$ramMB = [math]::Round(($ram.Capacity | Measure-Object -Sum).Sum / 1MB)

$initial = [math]::Min([math]::Max($ramMB*1.2,4096),16384)
$max = [math]::Min([math]::Max($ramMB*2,8192),32768)

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
-Name PagingFiles -Value "C:\pagefile.sys $initial $max"

Stop-Service SysMain -Force -ErrorAction SilentlyContinue
Set-Service SysMain -StartupType Disabled

OK "RAM optimized"

# ============================================================
# 🌐 NETWORK (LOW LATENCY)
# ============================================================
S "NETWORK ENGINE"

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty $_.PSPath TcpAckFrequency 1 -Force
    Set-ItemProperty $_.PSPath TCPNoDelay 1 -Force
}

OK "Network latency reduced"

# ============================================================
# 🧹 SYSTEM CLEANUP
# ============================================================
S "SYSTEM CLEANUP"

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns | Out-Null

OK "System cleaned"

# ============================================================
# 🎉 DONE
# ============================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " ✔ SYSTEM FULLY OPTIMIZED" -ForegroundColor Green
Write-Host " ⚡ Linux-style performance applied" -ForegroundColor Cyan
Write-Host " 👨‍💻 Credit: minimalharry" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

Write-Host "`nReboot recommended (Y/N): " -NoNewline
$r = Read-Host
if ($r -eq "Y"){Restart-Computer -Force}
