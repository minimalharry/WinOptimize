# ⚡ WinOptimize — Windows Performance & Gaming Optimizer

> 🚀 Smart, menu-driven PowerShell optimizer for Windows 10 & 11
> 🎮 Gaming (Minecraft) + ⚡ Faster Boot + 🧠 Better RAM Usage

---

## 🔥 Features

* ⚡ **Boot Time Optimization**

  * Faster startup (reduced timeout)
  * Startup delay removed
  * Scheduled tasks trimmed

* 🎮 **Gaming Mode**

  * Minecraft FPS tuning (java priority)
  * GPU preference for games
  * Game DVR off

* 🧠 **RAM Optimization**

  * Background apps cleanup
  * Safe pagefile tuning
  * Reduced system lag

* 🪟 **Windows 10 / 11 Support**

  * OS-specific tweaks
  * Stable (no risky hacks)

* 🔁 **Re-run Safe**

  * Resets old tweaks before applying new ones

---

## 🚀 Run (CMD / PowerShell)

> ⚠️ **Run as Administrator**

### 🔥 Recommended (Force Latest Version)

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/minimalharry/WinOptimize/main/WinOptimize.ps1?nocache=%RANDOM% | iex"
```

---

### ⚡ Simple Run

```powershell
irm https://raw.githubusercontent.com/minimalharry/WinOptimize/main/WinOptimize.ps1 | iex
```

---

### 🔁 Force Update (No Cache)

```powershell
powershell -c "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/minimalharry/WinOptimize/main/WinOptimize.ps1?nocache=$(Get-Random)' | Invoke-Expression"
```

---

## ❗ If Script Is Blocked

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Then run again.

---

## 🧪 Run Locally (Manual Way)

```powershell
git clone https://github.com/minimalharry/WinOptimize.git
cd WinOptimize
powershell -ExecutionPolicy Bypass -File WinOptimize.ps1
```

---

## 🧭 How To Use

1. Run script as admin
2. Select:

   * Windows version (10 / 11)
   * Mode:

     * Full Optimize
     * Gaming Mode
     * Boot Optimization
     * RAM Cleanup
3. Let it apply tweaks
4. Reboot (recommended)

---

## ⚠️ Requirements

* Windows 10 / 11
* Administrator access
* PowerShell enabled

---

## 🧠 Important Notes

* Uses **safe optimizations only**
* No system-breaking tweaks
* Performance gain depends on hardware

### 🔴 Best Upgrade

* Upgrade to **16GB RAM (dual channel)** for real FPS boost

---

## ❌ What This Script Does NOT Do

* ❌ No activation bypass
* ❌ No unsafe registry hacks
* ❌ No malware-like behavior

---

## 👨‍💻 Author

**Harry**
🔗 https://github.com/minimalharry/

---

## ⭐ Support

* ⭐ Star this repo
* 🍴 Fork it
* 💬 Suggest improvements

---

## 🚀 Future Plans

* GUI version (.exe)
* FPS benchmark system
* Auto hardware detection
* Advanced gaming tweaks

---

> 💬 Built for performance lovers — Linux-style tuning on Windows.
