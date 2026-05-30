# ================================================================
# WinOptimize ULTRA - by minimalharry - v2.3
# github.com/minimalharry | wo.minimalharry.xyz
# ================================================================

# -- ADMIN CHECK
$curId    = [Security.Principal.WindowsIdentity]::GetCurrent()
$curPrinc = New-Object Security.Principal.WindowsPrincipal($curId)
$isAdmin  = $curPrinc.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-NOT $isAdmin) {
    Write-Host ""
    Write-Host "  [!]  Run as Administrator!" -ForegroundColor Red
    Write-Host "  Right-click PowerShell -> Run as Administrator" -ForegroundColor DarkGray
    Write-Host ""
    pause; exit 1
}

# -- UI HELPERS
function Section($title) {
    Write-Host ""
    Write-Host "  +====================================================+" -ForegroundColor DarkGreen
    Write-Host "  |  $($title.ToUpper().PadRight(50))|" -ForegroundColor Green
    Write-Host "  +====================================================+" -ForegroundColor DarkGreen
    Write-Host ""
}
function OK($m)   { Write-Host "  [+]  $m" -ForegroundColor Green }
function SKIP($m) { Write-Host "  [~]  $m" -ForegroundColor DarkYellow }
function INFO($m) { Write-Host "  [i]  $m" -ForegroundColor Cyan }

function Set-Reg($path, $name, $value, $type = "DWord") {
    try {
        if (-not (Test-Path $path)) { New-Item $path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
    } catch { SKIP "Registry skipped: $name" }
}

function Disable-Svc($svc) {
    try {
        $s = Get-Service -Name $svc -ErrorAction Stop
        if ($s.StartType -ne 'Disabled') {
            Set-Service $svc -StartupType Disabled -ErrorAction Stop
            Stop-Service $svc -Force -NoWait -ErrorAction SilentlyContinue
            OK "Disabled: $svc"
        } else { SKIP "Already disabled: $svc" }
    } catch { SKIP "Not found: $svc" }
}

function Enable-Svc($svc) {
    try {
        Set-Service $svc -StartupType Automatic -ErrorAction Stop
        Start-Service $svc -ErrorAction SilentlyContinue
        OK "Enabled: $svc"
    } catch { SKIP "Could not enable: $svc" }
}

function Run-Bcdedit($cmdArgs, $label) {
    try {
        & bcdedit $cmdArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { OK $label }
        else { SKIP "bcdedit skipped: $label" }
    } catch { SKIP "bcdedit not available: $label" }
}

function Run-Fsutil($cmdArgs, $label) {
    try {
        & fsutil $cmdArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { OK $label }
        else { SKIP "fsutil skipped: $label" }
    } catch { SKIP "fsutil not available: $label" }
}

function Run-Netsh($cmdArgs, $label) {
    try {
        & netsh $cmdArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { OK $label }
        else { SKIP "netsh skipped: $label" }
    } catch { SKIP "netsh not available: $label" }
}

# -- BANNER
Clear-Host
Write-Host ""
Write-Host "  ##  ##  ## # #  #  ##  ##  ##### # #  # # ###### ####" -ForegroundColor Green
Write-Host "  # # # #  #  ##  # #  # #    #   # ## # # #      #    " -ForegroundColor Green
Write-Host "  # # # #  #  # # # #  # #    #   # # ## # ####    ### " -ForegroundColor Green
Write-Host "  # # # #  #  #  ## #  # #    #   # #  ## #      #    #" -ForegroundColor Green
Write-Host "  ##   ##  # #  #  #  ##  ##   #   # #   # ###### #### " -ForegroundColor Green
Write-Host ""
Write-Host "  ** ULTRA EDITION v2.3 **" -ForegroundColor DarkGreen
Write-Host "  ** by minimalharry **" -ForegroundColor DarkGreen
Write-Host "  ** wo.minimalharry.xyz **" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  +====================================================+" -ForegroundColor DarkGreen
Write-Host "  |   [0] Full    [1] Gaming  [2] Boot   [3] RAM      |" -ForegroundColor DarkGreen
Write-Host "  |   [4] Network [5] Privacy [6] Visual [7] Exit     |" -ForegroundColor DarkGreen
Write-Host "  +====================================================+" -ForegroundColor DarkGreen
Write-Host ""

# -- RESTORE POINT
Section "Creating System Restore Point"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "WinOptimize ULTRA v2.3" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    OK "Restore point created - safe to proceed"
} catch {
    SKIP "Restore point skipped (one may already exist within 24h)"
}

# -- SYSTEM INFO
Section "System Information"
try   { $cpu    = (Get-CimInstance Win32_Processor).Name }                                              catch { $cpu    = "Unknown" }
try   { $ramGB  = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB) }    catch { $ramGB  = "?" }
try   { $gpu    = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name }              catch { $gpu    = "Unknown" }
try   { $os     = (Get-CimInstance Win32_OperatingSystem).Caption }                                    catch { $os     = "Unknown" }
try   { $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB) }                                         catch { $freeGB = "?" }
try   { $build  = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber } catch { $build = 0 }

$isWin11  = $build -ge 22000
$winLabel = if ($isWin11) { "Windows 11" } else { "Windows 10" }

INFO "OS    : $os"
INFO "CPU   : $cpu"
INFO "RAM   : $ramGB GB"
INFO "GPU   : $gpu"
INFO "Free  : $freeGB GB on C:\"
INFO "Build : $build  ($winLabel detected)"

# -- MAIN MENU
Section "Select Optimization Mode"
Write-Host "  [0]  Full Optimize       - Everything (recommended)" -ForegroundColor White
Write-Host "  [1]  Gaming Mode         - Low latency, max FPS" -ForegroundColor White
Write-Host "  [2]  Boot Optimize       - Faster startup and shutdown" -ForegroundColor White
Write-Host "  [3]  RAM Cleanup         - Free memory now" -ForegroundColor White
Write-Host "  [4]  Network Optimize    - DNS and TCP tuning" -ForegroundColor White
Write-Host "  [5]  Privacy Hardening   - Kill telemetry and tracking" -ForegroundColor White
Write-Host "  [6]  Visual Performance  - Disable animations" -ForegroundColor White
Write-Host "  [7]  Exit" -ForegroundColor DarkGray
Write-Host ""
$mode = Read-Host "  Select [0-7]"
if ($mode -eq "7") { Write-Host "`n  Bye! -- minimalharry`n" -ForegroundColor Green; exit }

# -- BASE TWEAKS (always run)
Section "Base Optimization"

try   { powercfg -setactive SCHEME_MIN 2>&1 | Out-Null; OK "Power plan: High Performance" }
catch { SKIP "Could not set power plan" }

try {
    powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
    powercfg /change hibernate-timeout-ac 0 2>&1 | Out-Null
    OK "Sleep and hibernate (AC) disabled"
} catch { SKIP "Could not change power timeouts" }

Run-Bcdedit @("/timeout","2") "Boot timeout: 2 seconds"

Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
OK "Explorer startup delay removed"

Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1
OK "Lock screen disabled"

Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "EnableFirstLogonAnimation" 0
OK "First logon animation disabled"

Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "2000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "HungAppTimeout" "1000" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "AutoEndTasks" "1" "String"
OK "Faster shutdown timers set"

Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
OK "Windows tips and suggestions disabled"

# -- WINDOWS VERSION TWEAKS
Section "$winLabel Tweaks"
if ($isWin11) {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    OK "HAGS enabled (Win11)"
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
    OK "Taskbar aligned left"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
    OK "Windows Recall disabled"
} else {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1
    OK "GPU scheduling set (Win10 mode)"
}
Disable-Svc "DiagTrack"
Disable-Svc "dmwappushservice"

# =============================================
# FULL OPTIMIZE [0]
# =============================================
if ($mode -eq "0") {
    Section "Full Optimization"

    $bloatSvcs = @(
        "DiagTrack","dmwappushservice","MapsBroker","Fax",
        "WMPNetworkSvc","RetailDemo","RemoteRegistry",
        "WerSvc","PcaSvc","lfsvc",
        "XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc"
    )
    foreach ($s in $bloatSvcs) { Disable-Svc $s }

    Enable-Svc "SysMain"

    try {
        $startupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Get-ItemProperty $startupPath -ErrorAction Stop |
            ForEach-Object { $_.PSObject.Properties } |
            Where-Object { $_.Name -notmatch "SecurityHealth|WindowsDefender|PS" } |
            ForEach-Object { Remove-ItemProperty -Path $startupPath -Name $_.Name -ErrorAction SilentlyContinue }
        OK "Unnecessary startup apps removed"
    } catch { SKIP "Could not clean startup apps" }

    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$true} -ErrorAction Stop
        OK "Pagefile: system-managed"
    } catch { SKIP "Could not modify pagefile" }

    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 1
    OK "Prefetch and Superfetch tuned"

    Run-Fsutil @("behavior","set","disablelastaccess","1") "NTFS last-access timestamps disabled"
    Run-Fsutil @("behavior","set","disable8dot3","1") "NTFS 8.3 short names disabled"

    $telTasks = @(
        @{Name="Microsoft Compatibility Appraiser"; Path="\Microsoft\Windows\Application Experience\"},
        @{Name="ProgramDataUpdater";               Path="\Microsoft\Windows\Application Experience\"},
        @{Name="Consolidator";                     Path="\Microsoft\Windows\Customer Experience Improvement Program\"},
        @{Name="UsbCeip";                          Path="\Microsoft\Windows\Customer Experience Improvement Program\"},
        @{Name="Microsoft-Windows-DiskDiagnosticDataCollector"; Path="\Microsoft\Windows\DiskDiagnostic\"},
        @{Name="QueueReporting";                   Path="\Microsoft\Windows\Windows Error Reporting\"},
        @{Name="DmClient";                         Path="\Microsoft\Windows\Feedback\Siuf\"},
        @{Name="DmClientOnScenarioDownload";       Path="\Microsoft\Windows\Feedback\Siuf\"}
    )
    foreach ($t in $telTasks) {
        try {
            Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction Stop | Out-Null
            OK "Task disabled: $($t.Name)"
        } catch { SKIP "Task not found: $($t.Name)" }
    }

    try {
        $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        $cacheKeys = @(
            "Active Setup Temp Folders","Downloaded Program Files","Internet Cache Files",
            "Old ChkDsk Files","Recycle Bin","Temporary Files","Thumbnail Cache","Temporary Setup Files"
        )
        foreach ($k in $cacheKeys) {
            $p = "$regBase\$k"
            if (Test-Path $p) { Set-ItemProperty $p -Name StateFlags0064 -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue }
        }
        Start-Process cleanmgr -ArgumentList "/sagerun:64" -NoNewWindow -Wait -ErrorAction Stop
        OK "Disk cleanup complete"
    } catch { SKIP "Disk cleanup skipped" }

    OK "Full optimization done"
}

# =============================================
# GAMING MODE [1]
# =============================================
if ($mode -eq "1") {
    Section "Gaming Mode"

    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    OK "HAGS enabled"

    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    OK "Game DVR and Xbox Game Bar disabled"

    $gpuPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    $gameExes = @(
        "javaw.exe","steam.exe","epicgameslauncher.exe","leagueclient.exe",
        "valorant.exe","riotclientservices.exe","cs2.exe","csgo.exe",
        "gameoverlayui.exe","battle.net.exe","destiny2.exe","fortnite.exe"
    )
    foreach ($exe in $gameExes) { Set-Reg $gpuPath $exe "GpuPreference=2;" "String" }
    OK "GPU preference: High Performance for common launchers"

    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
    OK "Multimedia scheduler priority maxed"

    try {
        $ifaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction Stop
        foreach ($i in $ifaces) {
            Set-ItemProperty $i.PSPath "TcpAckFrequency" 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty $i.PSPath "TCPNoDelay" 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        OK "Nagle algorithm disabled (lower ping)"
    } catch { SKIP "Could not modify TCP interfaces" }

    $killList = @("Discord","Spotify","Teams","Skype","OneDrive","EpicWebHelper","YourPhone","SearchApp")
    foreach ($p in $killList) {
        if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
            Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
            OK "Killed: $p"
        } else { SKIP "Not running: $p" }
    }

    foreach ($s in @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","BcastDVRUserService")) {
        Disable-Svc $s
    }

    OK "Gaming mode complete"
}

# =============================================
# BOOT OPTIMIZE [2]
# =============================================
if ($mode -eq "2") {
    Section "Boot Optimization"

    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 1
    OK "Fast Startup enabled"

    Run-Bcdedit @("/timeout","2") "Boot timeout: 2 seconds"
    Run-Bcdedit @("/set","quietboot","yes") "Quiet boot enabled"

    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
    OK "Explorer startup delay: 0ms"

    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -match "Updater|Telemetry|CEIP|Experience|Appraiser" } |
        ForEach-Object {
            try { $_ | Disable-ScheduledTask -ErrorAction Stop | Out-Null; OK "Disabled task: $($_.TaskName)" }
            catch { SKIP "Could not disable: $($_.TaskName)" }
        }

    foreach ($s in @("WSearch","DiagTrack","MapsBroker","RetailDemo","WMPNetworkSvc")) {
        Disable-Svc $s
    }

    OK "Boot optimization complete"
}

# =============================================
# RAM CLEANUP [3]
# =============================================
if ($mode -eq "3") {
    Section "RAM Cleanup"

    $beforeFree = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
    INFO "Free RAM before: ~$beforeFree GB"

    $killList = @(
        "Discord","Spotify","Teams","Skype","OneDrive","EpicWebHelper",
        "Cortana","YourPhone","SearchApp","People","BingWeather","MicrosoftEdgeUpdate"
    )
    foreach ($p in $killList) {
        if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
            Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
            OK "Killed: $p"
        }
    }

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    OK ".NET garbage collection done"

    $src = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
public class MemUtil {
    [DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr h);
    public static void FlushAll() {
        foreach (var p in Process.GetProcesses())
            try { EmptyWorkingSet(p.Handle); } catch {}
    }
}
"@
    try {
        Add-Type $src -ErrorAction Stop
        [MemUtil]::FlushAll()
        OK "Working sets flushed (RAM reclaimed)"
    } catch { SKIP "Could not flush working sets" }

    Start-Sleep 2
    $afterFree = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
    $freed = [math]::Round($afterFree - $beforeFree, 1)
    INFO "Free RAM after:  ~$afterFree GB"
    if ($freed -gt 0) { OK "Freed ~$freed GB" } else { INFO "Flush applied - OS manages actual reclaim" }

    OK "RAM cleanup complete"
}

# =============================================
# NETWORK OPTIMIZE [4]
# =============================================
if ($mode -eq "4") {
    Section "Network Optimization"

    try {
        $upAdapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $upAdapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction Stop
            OK "DNS set to Cloudflare on: $($a.Name)"
        }
    } catch { SKIP "Could not set DNS" }

    try { ipconfig /flushdns 2>&1 | Out-Null; OK "DNS cache flushed" } catch { SKIP "Could not flush DNS" }

    Run-Netsh @("int","tcp","set","global","autotuninglevel=normal")    "TCP auto-tuning: normal"
    Run-Netsh @("int","tcp","set","global","chimney=disabled")          "TCP chimney disabled"
    Run-Netsh @("int","tcp","set","global","ecncapability=enabled")     "ECN enabled"
    Run-Netsh @("int","tcp","set","global","timestamps=disabled")       "TCP timestamps disabled"
    Run-Netsh @("int","tcp","set","global","rss=enabled")               "RSS enabled"
    Run-Netsh @("int","tcp","set","supplemental","internet","congestionprovider=ctcp") "CTCP congestion set"

    try {
        $ifaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction Stop
        foreach ($i in $ifaces) {
            Set-ItemProperty $i.PSPath "TcpAckFrequency" 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty $i.PSPath "TCPNoDelay" 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        OK "Nagle algorithm disabled"
    } catch { SKIP "Could not modify TCP interfaces" }

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
    OK "QoS bandwidth reserve: 0%"

    OK "Network optimization complete"
}

# =============================================
# PRIVACY HARDENING [5]
# =============================================
if ($mode -eq "5") {
    Section "Privacy Hardening"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
    OK "Telemetry level: 0"

    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    OK "Advertising ID disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
    OK "Activity history disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1
    OK "Location tracking disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    OK "Cortana disabled"

    Set-Reg "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0
    OK "Feedback notifications disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 1
    OK "App diagnostics disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
    OK "Windows Recall and AI snapshots disabled"

    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSync" 2
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSyncUserOverride" 1
    OK "Settings sync disabled"

    Disable-Svc "DiagTrack"
    Disable-Svc "dmwappushservice"
    Disable-Svc "lfsvc"

    OK "Privacy hardening complete"
}

# =============================================
# VISUAL PERFORMANCE [6]
# =============================================
if ($mode -eq "6") {
    Section "Visual Performance"

    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    OK "Visual effects: Best performance"

    $uiAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-Reg $uiAdv "ListviewShadow" 0
    Set-Reg $uiAdv "TaskbarAnimations" 0
    Set-Reg $uiAdv "ListviewAlphaSelect" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
    Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
    OK "All UI animations disabled"

    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
    OK "Transparency effects disabled"

    Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothing" "2" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothingType" 2
    OK "ClearType font smoothing set"

    OK "Visual performance mode complete"
}

# -- FINAL CLEANUP
Section "Final Cleanup"

@("$env:TEMP\*","$env:SystemRoot\Temp\*","$env:LOCALAPPDATA\Temp\*") | ForEach-Object {
    Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
}
OK "Temp files cleared"

try { ipconfig /flushdns 2>&1 | Out-Null; OK "DNS cache flushed" } catch { SKIP "DNS flush skipped" }

Remove-Item "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
OK "Prefetch cleared (rebuilds automatically)"

foreach ($log in @("Application","System","Security")) {
    try {
        wevtutil cl $log 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { OK "Event log cleared: $log" }
        else { SKIP "Event log needs higher privileges: $log" }
    } catch { SKIP "Could not clear event log: $log" }
}

Write-Host ""
Write-Host "  Run System File Checker? [~5 min] [Y/N]: " -NoNewline -ForegroundColor Cyan
$sfcAns = Read-Host
if ($sfcAns -match "^[Yy]$") {
    INFO "Running sfc /scannow - please wait..."
    try { sfc /scannow; OK "SFC scan complete" } catch { SKIP "SFC could not run" }
}

# -- DONE
Write-Host ""
Write-Host "  +====================================================+" -ForegroundColor Green
Write-Host "  |                                                    |" -ForegroundColor Green
Write-Host "  |   [+]  WinOptimize ULTRA complete!                |" -ForegroundColor Green
Write-Host "  |   [!]  Reboot to apply all changes.               |" -ForegroundColor Green
Write-Host "  |   [>]  wo.minimalharry.xyz                        |" -ForegroundColor Green
Write-Host "  |                                                    |" -ForegroundColor Green
Write-Host "  +====================================================+" -ForegroundColor Green
Write-Host ""
Write-Host "  Reboot now? [Y/N]: " -NoNewline -ForegroundColor Cyan
$reboot = Read-Host
if ($reboot -match "^[Yy]$") {
    Write-Host "  Rebooting in 5 seconds..." -ForegroundColor Red
    Start-Sleep 5
    Restart-Computer -Force
}
Write-Host ""
Write-Host "  Done! -- minimalharry" -ForegroundColor Green
Write-Host "  wo.minimalharry.xyz" -ForegroundColor DarkGray
Write-Host ""
