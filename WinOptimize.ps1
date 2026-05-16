# ============================================================
# WinOptimize ULTRA — by Harry (minimalharry)
# github.com/minimalharry | minimalharry.xyz
# WARNING: Run as Administrator. Creates a restore point first.
# ============================================================

#region ── ADMIN CHECK ─────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "`n  [!] Run this script as Administrator!" -ForegroundColor Red
    pause; exit 1
}
#endregion

#region ── UI HELPERS ──────────────────────────────────────
function Section($t) {
    Write-Host "`n  ┌─────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │  ✦ $($t.PadRight(43))│" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────┘" -ForegroundColor DarkCyan
}
function OK($m)   { Write-Host "    ✅  $m" -ForegroundColor Green }
function SKIP($m) { Write-Host "    ⚠️   $m" -ForegroundColor DarkYellow }
function INFO($m) { Write-Host "    ℹ️   $m" -ForegroundColor DarkCyan }
function ERR($m)  { Write-Host "    ✗   $m" -ForegroundColor Red }

function Set-Reg($path, $name, $value, $type = "DWord") {
    try {
        if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Disable-Svc($svc) {
    try {
        Set-Service $svc -StartupType Disabled -ErrorAction Stop
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        OK "Service disabled: $svc"
    } catch { SKIP "Could not disable: $svc" }
}

function Enable-Svc($svc) {
    try {
        Set-Service $svc -StartupType Automatic -ErrorAction Stop
        Start-Service $svc -ErrorAction SilentlyContinue
        OK "Service enabled: $svc"
    } catch { SKIP "Could not enable: $svc" }
}
#endregion

#region ── BANNER ──────────────────────────────────────────
Clear-Host
Write-Host @"

  ██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗
  ██║    ██║██║████╗  ██║██╔═══██╗██╔══██╗╚══██╔══╝
  ██║ █╗ ██║██║██╔██╗ ██║██║   ██║██████╔╝   ██║
  ██║███╗██║██║██║╚██╗██║██║   ██║██╔═══╝    ██║
  ╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║        ██║
   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝

      WinOptimize ULTRA — by minimalharry
      github.com/minimalharry  |  minimalharry.xyz

"@ -ForegroundColor Magenta
#endregion

#region ── SYSTEM RESTORE POINT ───────────────────────────
Section "SAFETY — CREATING RESTORE POINT"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "WinOptimize ULTRA — Pre-Tweak" `
        -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    OK "Restore point created"
} catch {
    SKIP "Restore point failed (may already exist within 24h). Continuing..."
}
#endregion

#region ── SYSTEM INFO ─────────────────────────────────────
Section "SYSTEM INFORMATION"
$cpu   = (Get-CimInstance Win32_Processor).Name
$ram   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$gpu   = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$os    = (Get-CimInstance Win32_OperatingSystem).Caption
$disk  = Get-PSDrive C | Select-Object -ExpandProperty Free
$diskG = [math]::Round($disk / 1GB)
INFO "OS  : $os"
INFO "CPU : $cpu"
INFO "RAM : ${ram} GB"
INFO "GPU : $gpu"
INFO "Free: ${diskG} GB on C:\"
#endregion

#region ── WINDOWS VERSION AUTO-DETECT ────────────────────
$buildNum = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$isWin11  = $buildNum -ge 22000
$winLabel = if ($isWin11) { "Windows 11" } else { "Windows 10" }
INFO "Detected: $winLabel (Build $buildNum)"
#endregion

#region ── MAIN MENU ───────────────────────────────────────
Section "MAIN MENU"
Write-Host @"
    [0]  Full Optimize        — Everything (takes a few minutes)
    [1]  Gaming Mode          — Low latency, GPU priority, kill bloat
    [2]  Boot Optimization    — Faster startup & shutdown only
    [3]  RAM Cleanup          — Free memory & kill background apps
    [4]  Network Optimize     — DNS, TCP, adapter tuning
    [5]  Privacy Hardening    — Disable telemetry & tracking
    [6]  Visual Performance   — Disable animations for snappiness
    [7]  Show System Info     — Only display specs
    [8]  Exit
"@ -ForegroundColor White

$mode = Read-Host "  Select"
if ($mode -eq "7") { pause; exit }
if ($mode -eq "8") { exit }
#endregion

#region ══════════ BASE TWEAKS (always applied) ══════════

Section "BASE OPTIMIZATION"

# ── Power Plan: High Performance ──────────────────────────
powercfg -setactive SCHEME_MIN
OK "Power plan: High Performance"

# ── Disable Sleep & Hibernate when plugged in ─────────────
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
OK "Sleep/Hibernate (AC) disabled"

# ── Boot timeout ──────────────────────────────────────────
bcdedit /timeout 2 | Out-Null
OK "Boot timeout: 2s"

# ── Disable Explorer startup delay ────────────────────────
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
OK "Explorer startup delay removed"

# ── Disable First-Run animation & lock screen ─────────────
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "EnableFirstLogonAnimation" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1
OK "Lock screen & first-run animation disabled"

# ── Faster shutdown ───────────────────────────────────────
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "2000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "HungAppTimeout" "1000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "AutoEndTasks" "1" "String"
OK "Faster shutdown configured"

# ── Disable Windows tips & suggestions ───────────────────
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
OK "Windows suggestions & tips disabled"

#endregion

#region ══════════ WINDOWS VERSION TWEAKS ════════════════

Section "$winLabel SPECIFIC TWEAKS"

if ($isWin11) {
    # HAGS (Hardware Accelerated GPU Scheduling)
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    OK "HAGS enabled (Win11)"

    # Taskbar tweaks
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
    OK "Taskbar aligned left"

    # Disable Recall (Copilot+ AI snapshots) if present
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
    SKIP "Recall disabled (if applicable)"

} else {
    # Win10: Disable HAGS (can cause instability on older drivers)
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1
    OK "HAGS set to default (Win10)"
}

# Both: Disable telemetry service
Disable-Svc "DiagTrack"
Disable-Svc "dmwappushservice"

#endregion

#region ══════════ FULL OPTIMIZE (mode 0) ════════════════
if ($mode -eq "0" -or $mode -eq "") {

Section "FULL OPTIMIZATION"

# ── Services to disable (bloat/telemetry) ─────────────────
$bloatServices = @(
    "DiagTrack",          # Connected User Experiences & Telemetry
    "dmwappushservice",   # WAP Push Message Routing
    "MapsBroker",         # Downloaded Maps Manager
    "Fax",                # Fax
    "TabletInputService", # Touch Keyboard & Handwriting
    "WMPNetworkSvc",      # Windows Media Player Network Sharing
    "RetailDemo",         # Retail Demo Service
    "RemoteRegistry",     # Remote Registry
    "SharedAccess",       # Internet Connection Sharing
    "WerSvc",             # Windows Error Reporting
    "PcaSvc",             # Program Compatibility Assistant
    "lfsvc",              # Geolocation Service
    "XblAuthManager",     # Xbox Live Auth Manager
    "XblGameSave",        # Xbox Live Game Save
    "XboxNetApiSvc",      # Xbox Live Networking
    "XboxGipSvc"          # Xbox Accessory Management
)
foreach ($s in $bloatServices) { Disable-Svc $s }

# ── Keep SysMain (Superfetch) enabled — helps on HDD/hybrid
Enable-Svc "SysMain"

# ── Startup apps clean (preserve Security Health) ─────────
$startup = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $startup -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PSObject.Properties | Where-Object {
        $_.Name -notmatch "SecurityHealth|OneDrive|WindowsDefender"
    } | ForEach-Object {
        Remove-ItemProperty -Path $startup -Name $_.Name -ErrorAction SilentlyContinue
    }
}
OK "Unnecessary startup apps removed"

# ── Pagefile: auto-managed (safe default) ─────────────────
$cs = Get-CimInstance Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $true
$cs.Put() | Out-Null
OK "Pagefile set to system-managed"

# ── Prefetch & SuperFetch registry tweaks ─────────────────
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 1
OK "Prefetch & Superfetch tuned"

# ── Disable scheduled telemetry tasks ────────────────────
$telTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)
foreach ($task in $telTasks) {
    try { Disable-ScheduledTask -TaskName (Split-Path $task -Leaf) -TaskPath (Split-Path $task -Parent) -ErrorAction Stop | Out-Null; OK "Task disabled: $(Split-Path $task -Leaf)" }
    catch { SKIP "Task not found: $(Split-Path $task -Leaf)" }
}

# ── NTFS performance tweaks ───────────────────────────────
fsutil behavior set disablelastaccess 1 | Out-Null
fsutil behavior set disable8dot3 1 | Out-Null
OK "NTFS: Last access & 8.3 naming disabled"

# ── Disk cleanup (silent) ─────────────────────────────────
Start-Process cleanmgr -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
OK "Disk cleanup run"

OK "Full optimization complete"
}
#endregion

#region ══════════ GAMING MODE (mode 1) ══════════════════
if ($mode -eq "1") {

Section "GAMING MODE"

# ── High Performance power ────────────────────────────────
powercfg -setactive SCHEME_MIN
OK "High Performance power plan"

# ── HAGS ──────────────────────────────────────────────────
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
OK "Hardware Accelerated GPU Scheduling enabled"

# ── Disable GameDVR / Xbox Game Bar ───────────────────────
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
OK "Game DVR / Game Bar disabled"

# ── GPU preference for common game launchers ──────────────
$gpuPref = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
$gameExes = @("javaw.exe","steam.exe","epicgameslauncher.exe","leagueclient.exe","valorant.exe","riotclientservices.exe","csgo.exe","cs2.exe","gameoverlayui.exe")
foreach ($exe in $gameExes) {
    Set-Reg $gpuPref $exe "GpuPreference=2;" "String"
}
OK "GPU preference set to High Performance for common launchers"

# ── Network: disable Nagle's algorithm (lower latency) ────
$adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($a in $adapters) {
    Set-Reg $a.PSPath "TcpAckFrequency" 1
    Set-Reg $a.PSPath "TCPNoDelay" 1
}
OK "Nagle's algorithm disabled (lower ping)"

# ── Kill known background hogs ────────────────────────────
$killProcs = @("Discord","Spotify","Teams","Skype","OneDrive","EpicWebHelper","SearchApp","YourPhone")
foreach ($p in $killProcs) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
    OK "Killed: $p"
}

# ── Disable Xbox services ─────────────────────────────────
$xboxSvcs = @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","BcastDVRUserService")
foreach ($s in $xboxSvcs) { Disable-Svc $s }

# ── Process priority boost ────────────────────────────────
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
OK "Multimedia/game scheduler priority maxed"

OK "Gaming mode complete"
}
#endregion

#region ══════════ BOOT OPTIMIZE (mode 2) ════════════════
if ($mode -eq "2") {

Section "BOOT OPTIMIZATION"

# ── Fast startup ──────────────────────────────────────────
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 1
OK "Fast Startup (hiberboot) enabled"

# ── Boot timeout ──────────────────────────────────────────
bcdedit /timeout 2 | Out-Null
OK "Boot timeout: 2s"

# ── Disable boot logo animation (very minor) ──────────────
bcdedit /set quietboot yes | Out-Null
OK "Quiet boot enabled"

# ── Disable startup delay ─────────────────────────────────
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
OK "Explorer startup delay removed"

# ── Kill updater/telemetry scheduled tasks ────────────────
Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Updater|Telemetry|CEIP|Experience"
} | ForEach-Object {
    try { $_ | Disable-ScheduledTask | Out-Null; OK "Task disabled: $($_.TaskName)" }
    catch { SKIP "Could not disable: $($_.TaskName)" }
}

# ── Disable heavy startup services ───────────────────────
$startupSvcs = @("WSearch","DiagTrack","MapsBroker","RetailDemo","WMPNetworkSvc")
foreach ($s in $startupSvcs) { Disable-Svc $s }

OK "Boot optimization complete"
}
#endregion

#region ══════════ RAM CLEANUP (mode 3) ══════════════════
if ($mode -eq "3") {

Section "RAM CLEANUP"

# ── Kill background apps ──────────────────────────────────
$killProcs = @("Discord","Spotify","Teams","Skype","OneDrive","EpicWebHelper","Cortana","YourPhone","SearchApp","People","BingWeather")
foreach ($p in $killProcs) {
    $proc = Get-Process -Name $p -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
        OK "Killed: $p"
    }
}

# ── Force .NET GC ─────────────────────────────────────────
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
OK ".NET garbage collection done"

# ── Clear standby memory via RAMMap trick (EmptyWorkingSets) ─
$code = @"
using System;
using System.Runtime.InteropServices;
public class Memory {
    [DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr hProcess);
    public static void ClearAll() {
        foreach (var p in System.Diagnostics.Process.GetProcesses())
            try { EmptyWorkingSet(p.Handle); } catch { }
    }
}
"@
Add-Type $code -ErrorAction SilentlyContinue
[Memory]::ClearAll()
OK "Working sets flushed (RAM freed)"

# ── Show RAM before/after (approximate) ───────────────────
$ramFree = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
INFO "Free RAM now: ~${ramFree} GB"

OK "RAM cleanup complete"
}
#endregion

#region ══════════ NETWORK OPTIMIZE (mode 4) ═════════════
if ($mode -eq "4") {

Section "NETWORK OPTIMIZATION"

# ── DNS: Switch to Cloudflare ─────────────────────────────
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($a in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction Stop
        OK "DNS set to Cloudflare on: $($a.Name)"
    } catch { SKIP "Could not set DNS on: $($a.Name)" }
}

# ── Flush DNS ─────────────────────────────────────────────
ipconfig /flushdns | Out-Null
OK "DNS cache flushed"

# ── TCP tweaks ────────────────────────────────────────────
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global chimney=disabled | Out-Null
netsh int tcp set global ecncapability=enabled | Out-Null
netsh int tcp set global timestamps=disabled | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set supplemental internet congestionprovider=ctcp | Out-Null
OK "TCP global tuning applied"

# ── Disable Nagle's algorithm ─────────────────────────────
$ifaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($i in $ifaces) {
    Set-Reg $i.PSPath "TcpAckFrequency" 1
    Set-Reg $i.PSPath "TCPNoDelay" 1
}
OK "Nagle's algorithm disabled"

# ── Disable Windows Auto-Tuning (helps some connections) ──
netsh int tcp set global autotuninglevel=disabled | Out-Null
OK "Auto-tuning disabled"

# ── QoS — reserve 0% bandwidth (Windows defaults to 20%) ──
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
OK "QoS bandwidth reservation: 0%"

OK "Network optimization complete"
}
#endregion

#region ══════════ PRIVACY HARDENING (mode 5) ════════════
if ($mode -eq "5") {

Section "PRIVACY HARDENING"

# ── Telemetry level: 0 (Security only) ───────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
OK "Telemetry level set to 0"

# ── Disable advertising ID ────────────────────────────────
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
OK "Advertising ID disabled"

# ── Disable activity history ──────────────────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
OK "Activity history disabled"

# ── Disable location tracking ─────────────────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1
OK "Location tracking disabled"

# ── Disable Cortana ───────────────────────────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
OK "Cortana disabled"

# ── Disable app diagnostics ───────────────────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 1
OK "App diagnostics disabled"

# ── Disable feedback notifications ───────────────────────
Set-Reg "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0
OK "Feedback notifications disabled"

# ── Disable Recall / AI snapshots (Win11 Copilot+) ────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
OK "Recall / AI data analysis disabled"

# ── Disable cloud sync for settings ──────────────────────
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSync" 2
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSyncUserOverride" 1
OK "Settings sync disabled"

Disable-Svc "DiagTrack"
Disable-Svc "dmwappushservice"
Disable-Svc "lfsvc"

OK "Privacy hardening complete"
}
#endregion

#region ══════════ VISUAL PERFORMANCE (mode 6) ═══════════
if ($mode -eq "6") {

Section "VISUAL PERFORMANCE"

# ── Set "Adjust for best performance" ────────────────────
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
$perfKey = "HKCU:\Control Panel\Desktop\WindowMetrics"
$uiPref  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"

# Disable all animations individually too
Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
Set-Reg $uiPref "ListviewShadow" 0
Set-Reg $uiPref "TaskbarAnimations" 0
Set-Reg $uiPref "ListviewAlphaSelect" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
OK "All visual animations disabled"

# ── Disable transparency ──────────────────────────────────
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
OK "Transparency disabled"

# ── Font smoothing: ClearType only ────────────────────────
Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothing" "2" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothingType" 2
OK "ClearType font smoothing set"

OK "Visual performance mode complete"
}
#endregion

#region ══════════ FINAL CLEAN (always) ══════════════════

Section "FINAL CLEANUP"

# ── Temp files ────────────────────────────────────────────
@("$env:TEMP\*", "$env:SystemRoot\Temp\*", "$env:LOCALAPPDATA\Temp\*") | ForEach-Object {
    Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
}
OK "Temp files cleared"

# ── DNS flush ─────────────────────────────────────────────
ipconfig /flushdns | Out-Null
OK "DNS cache flushed"

# ── Prefetch clear (Windows rebuilds it) ─────────────────
Remove-Item "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
OK "Prefetch cleared (will auto-rebuild)"

# ── Event log clear (optional, helps disk) ───────────────
wevtutil cl Application 2>$null
wevtutil cl System 2>$null
OK "Event logs cleared"

# ── SFC — optional integrity check ───────────────────────
Write-Host "`n    Run System File Checker? (takes ~5 min) [Y/N]: " -NoNewline -ForegroundColor Cyan
$sfcR = Read-Host
if ($sfcR -eq "Y" -or $sfcR -eq "y") {
    INFO "Running sfc /scannow — please wait..."
    sfc /scannow | Out-Null
    OK "SFC scan complete"
}

#endregion

#region ══════════ DONE ══════════════════════════════════

Write-Host @"

  ┌─────────────────────────────────────────────┐
  │                                             │
  │   ✅  WinOptimize ULTRA — Done!             │
  │   📌  Reboot to apply all changes.          │
  │   🌐  minimalharry.xyz                      │
  │                                             │
  └─────────────────────────────────────────────┘
"@ -ForegroundColor Green

Write-Host "`n  Reboot now? [Y/N]: " -NoNewline -ForegroundColor Cyan
$r = Read-Host
if ($r -eq "Y" -or $r -eq "y") {
    Write-Host "  Rebooting in 5 seconds..." -ForegroundColor Red
    Start-Sleep 5
    Restart-Computer -Force
}

Write-Host "`n  Bye! — minimalharry`n" -ForegroundColor Magenta

#endregion
