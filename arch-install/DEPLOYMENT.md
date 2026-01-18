# JesterNet OS Deployment Guide

```
╔══════════════════════════════════════════════════════════════════════════╗
║                    QUANTUM FIELD MEDIC                                   ║
║              Mobile-First Installation Orchestrator                      ║
╚══════════════════════════════════════════════════════════════════════════╝
```

Deploy JesterNet OS from:
- **Ventoy USB** - Multi-ISO boot drive
- **Android Device** - Via ADB/Termux (Quantum Field Medic)
- **Any Live Linux** - curl from anywhere

---

## Method 1: Ventoy USB (Recommended)

### Setup Ventoy Drive

1. **Download Ventoy**: https://www.ventoy.net/
2. **Install to USB**:
   ```bash
   # Linux
   sudo ./Ventoy2Disk.sh -i /dev/sdX

   # Windows: Run Ventoy2Disk.exe
   ```

3. **Copy ISOs to USB**:
   ```
   USB Drive/
   ├── archlinux-2024.01.01-x86_64.iso
   └── ventoy/
       └── ventoy.json  (optional config)
   ```

### Add JesterNet Installer

Copy the entire `arch-install/` folder to the Ventoy USB:

```
USB Drive/
├── archlinux-2024.01.01-x86_64.iso
├── JesterNet/
│   ├── jesternet-arch-install.sh
│   ├── install.conf.example
│   └── ... (theme files)
```

### Boot and Install

1. Boot target machine from Ventoy USB
2. Select Arch Linux ISO
3. Connect to internet:
   ```bash
   # WiFi
   iwctl station wlan0 connect "Your-SSID"

   # Ethernet: Usually auto-connects
   ```

4. Mount Ventoy partition and run installer:
   ```bash
   # Find Ventoy partition
   lsblk

   # Mount it (usually the larger partition on your USB)
   mount /dev/sdX1 /mnt

   # Run installer
   bash /mnt/JesterNet/arch-install/jesternet-arch-install.sh
   ```

---

## Method 2: Android Quantum Field Medic (ADB)

Transform your Android phone into a deployment command center.

### Prerequisites

1. **On Android - Install Termux**:
   - Download from F-Droid (recommended) or Play Store
   - https://f-droid.org/en/packages/com.termux/

2. **In Termux - Setup Environment**:
   ```bash
   pkg update && pkg upgrade
   pkg install android-tools openssh git
   ```

3. **Enable ADB on Target Machine**:
   - If target has any Linux running, enable ADB debugging
   - Or boot from Arch ISO and install ADB:
     ```bash
     pacman -Sy android-tools
     ```

### Wireless ADB Setup

**On Target Machine (Arch Live):**
```bash
# Start ADB server
adb tcpip 5555

# Get IP address
ip addr show | grep inet
```

**On Android (Termux):**
```bash
# Connect to target
adb connect 192.168.1.XXX:5555

# Verify connection
adb devices
```

### Deploy JesterNet

**Option A: Push script and execute**
```bash
# Clone JesterNet to Termux
git clone https://github.com/yourusername/jesternet-os.git

# Push to target
adb push jesternet-os/ /tmp/

# Execute on target
adb shell "chmod +x /tmp/jesternet-os/arch-install/jesternet-arch-install.sh"
adb shell "/tmp/jesternet-os/arch-install/jesternet-arch-install.sh"
```

**Option B: Remote shell**
```bash
# Open shell on target
adb shell

# Then run installer manually
cd /tmp/jesternet-os/arch-install
./jesternet-arch-install.sh
```

### Full Quantum Field Medic Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    QUANTUM FIELD MEDIC PROTOCOL                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [ANDROID DEVICE]              [TARGET MACHINE]                     │
│       │                              │                              │
│       │  1. Boot Arch ISO            │                              │
│       │  ────────────────────────►   │                              │
│       │                              │                              │
│       │  2. Connect WiFi             │                              │
│       │  ────────────────────────►   │  iwctl station wlan0...     │
│       │                              │                              │
│       │  3. Start ADB server         │                              │
│       │  ────────────────────────►   │  adb tcpip 5555             │
│       │                              │                              │
│       │  4. Connect via ADB          │                              │
│       │  ◄────────────────────────   │                              │
│       │  adb connect 192.168.x.x     │                              │
│       │                              │                              │
│       │  5. Push JesterNet           │                              │
│       │  ────────────────────────►   │                              │
│       │  adb push jesternet/ /tmp/   │                              │
│       │                              │                              │
│       │  6. Execute installer        │                              │
│       │  ────────────────────────►   │  Running installation...    │
│       │  adb shell ./install.sh      │                              │
│       │                              │                              │
│       │  7. Monitor progress         │                              │
│       │  ◄────────────────────────   │  [=========>    ] 60%       │
│       │                              │                              │
│       │  8. Reboot into JesterNet    │                              │
│       │  ────────────────────────►   │  🎉 COMPLETE                │
│       │                              │                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Method 3: curl from Live Environment

Boot any Arch ISO and run:

```bash
# Connect to internet first
iwctl station wlan0 connect "Your-SSID"

# Download and run
curl -sL https://raw.githubusercontent.com/yourusername/jesternet-os/main/arch-install/jesternet-arch-install.sh | bash
```

Or clone and run:

```bash
pacman -Sy git
git clone https://github.com/yourusername/jesternet-os.git
cd jesternet-os/arch-install
./jesternet-arch-install.sh
```

---

## Automated Installation (Config File)

For repeatable deployments, create a config file:

```bash
# Copy example config
cp install.conf.example install.conf

# Edit with your settings
nano install.conf
```

Then run:
```bash
./jesternet-arch-install.sh install.conf
```

### Example Config for Quick Deploy

```bash
# install.conf
TARGET_DISK="/dev/nvme0n1"
HOSTNAME="workstation"
USERNAME="developer"
TIMEZONE="America/Los_Angeles"
DESKTOP_STYLE="dock"
DEV_STACKS="tauri go python web"
```

---

## Post-Installation

After first boot, log in and run:

```bash
# 1. Install AUR helper
./install-yay.sh

# 2. Apply JesterNet theme
./setup-theme.sh

# 3. Install dev stacks (if selected)
./install-dev-stacks.sh

# 4. Reboot
reboot
```

---

## Troubleshooting

### Can't Connect ADB Wirelessly

```bash
# On target machine
adb kill-server
adb start-server
adb tcpip 5555

# Check firewall
iptables -A INPUT -p tcp --dport 5555 -j ACCEPT
```

### Ventoy Not Detecting ISO

- Ensure ISO is in root of USB, not in subfolders
- Check ISO isn't corrupted: `sha256sum archlinux-*.iso`
- Try Ventoy in Legacy mode if UEFI fails

### Installation Fails at Partitioning

- Ensure disk isn't mounted: `umount -R /mnt`
- Check for existing RAID: `mdadm --stop --scan`
- Wipe disk: `wipefs -a /dev/nvme0n1`

### No Internet in Live Environment

```bash
# Check interface
ip link

# For WiFi
iwctl
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "SSID"

# For Ethernet
dhcpcd enp0s3
```

---

## Security Notes

- The install script needs root access (runs with sudo)
- Passwords entered interactively are not logged
- Config files with passwords should be deleted after use
- ADB connections should be on trusted networks only

---

```
"Walk into any environment. Bring it to life."
                    - Quantum Field Medic Protocol
```
