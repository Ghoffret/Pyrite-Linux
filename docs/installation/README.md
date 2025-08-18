# Pyrite Linux Installation Guide

## Overview

Pyrite Linux is a comprehensive Arch-based distribution designed for users who want a minimal, efficient, and modern Linux system with advanced features like Btrfs snapshots, hardware auto-detection, and modular package installation.

## Pre-Installation Requirements

### Hardware Requirements
- **UEFI firmware** (Legacy BIOS not supported)
- **Minimum 8GB** disk space (20GB+ recommended)
- **512MB RAM** minimum (2GB+ recommended for desktop environments)
- **x86_64 architecture** (64-bit Intel/AMD processors)
- **Active internet connection** during installation

### Supported Hardware
- Intel, AMD, and compatible processors
- NVIDIA, AMD, and Intel graphics cards (with automatic driver detection)
- Common WiFi chipsets (Intel, Broadcom, Realtek, Atheros)
- Standard audio hardware with PipeWire support
- SATA, NVMe, and standard storage devices

## Installation Methods

### Method 1: Direct Installation (Recommended)

1. **Boot from Arch Linux ISO**
   ```bash
   # Download latest Arch Linux ISO from archlinux.org
   # Create bootable USB and boot in UEFI mode
   ```

2. **Download Pyrite Installer**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Ghoffret/Pyrite-Linux/main/installer/pyrite-install.sh -o pyrite-install.sh
   chmod +x pyrite-install.sh
   ```

3. **Run Installation**
   ```bash
   ./pyrite-install.sh
   ```

### Method 2: Enhanced Installation with Hardware Detection

1. **Run Hardware Detection First**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Ghoffret/Pyrite-Linux/main/installer/hardware-detect.sh -o hardware-detect.sh
   chmod +x hardware-detect.sh
   ./hardware-detect.sh
   ```

2. **Select Package Profile**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Ghoffret/Pyrite-Linux/main/installer/package-selector.sh -o package-selector.sh
   chmod +x package-selector.sh
   ./package-selector.sh
   ```

3. **Run Main Installation**
   ```bash
   ./pyrite-install.sh
   ```

## Installation Profiles

### Minimal Profile
- Core system packages only
- Command-line interface
- Basic development tools
- Essential utilities
- **Recommended for:** Servers, minimal systems, advanced users

### Development Profile
- Minimal profile + development tools
- Compilers (GCC, Clang, Rust, Go)
- Version control (Git, Mercurial)
- Development frameworks
- **Recommended for:** Developers, programming workstations

### Server Profile
- Minimal profile + server applications
- Web servers (Nginx, Apache)
- Database systems (MariaDB, PostgreSQL)
- Monitoring tools
- Container support
- **Recommended for:** Server deployments, hosting environments

### Desktop Profile
- Minimal profile + desktop environment
- Window managers (i3, Sway, XFCE)
- Audio/video support
- Basic applications
- **Recommended for:** Desktop workstations, multimedia systems

## Step-by-Step Installation Process

### 1. System Requirements Check
The installer automatically validates:
- UEFI boot mode
- Internet connectivity
- Memory requirements
- Disk space availability

### 2. Hardware Detection
Automatic detection and configuration of:
- CPU microcode (Intel/AMD)
- Graphics drivers (NVIDIA/AMD/Intel)
- WiFi chipsets and firmware
- Audio hardware
- Storage devices

### 3. Configuration Input
Interactive configuration of:
- System hostname
- User account creation
- Password setup
- Timezone detection
- Locale settings
- Network preferences

### 4. Disk Management
- Disk selection from available devices
- Automatic partitioning (EFI + Btrfs)
- Optional swap configuration
- Secure disk wiping option

### 5. Package Installation
- Base Arch Linux system
- Hardware-specific drivers
- Selected profile packages
- AUR helper (yay) if enabled
- Flatpak support if enabled

### 6. System Configuration
- Bootloader setup (systemd-boot)
- User and security configuration
- Network setup (NetworkManager)
- Firewall configuration (UFW)
- Btrfs optimization

### 7. Post-Installation Setup
- System validation checks
- Initial snapshot creation
- Performance optimization
- Service configuration

## Advanced Installation Options

### Custom Package Selection
Create custom package combinations:
```bash
# Combine multiple profiles
./package-selector.sh
# Select: Custom -> Development + Server
```

### Encryption Support
For encrypted installations:
```bash
# Enable encryption during disk setup
# Full disk encryption with LUKS
```

### Network Installation
For network-only installations:
```bash
# Minimal profile with network tools
# Remote management capabilities
```

## Post-Installation Tasks

### First Boot Checklist
1. **Update system packages**
   ```bash
   sudo pyrite-update
   ```

2. **Create initial snapshot**
   ```bash
   sudo pyrite-backup create "post-install"
   ```

3. **Configure hardware**
   ```bash
   pyrite-config
   ```

4. **Install additional software**
   ```bash
   # Official repositories
   sudo pacman -S package-name
   
   # AUR packages (if enabled)
   yay -S aur-package-name
   
   # Flatpak applications (if enabled)
   flatpak install flathub app-name
   ```

### System Management
- Use `pyrite-update` for system updates with snapshots
- Use `pyrite-config` for hardware configuration
- Use `pyrite-service` for service management
- Use `pyrite-logs` for troubleshooting
- Use `pyrite-backup` for snapshot management
- Use `pyrite-recovery` for system recovery

## Troubleshooting

### Installation Issues

**Boot Problems:**
- Ensure UEFI mode is enabled
- Disable Secure Boot if needed
- Check boot order in BIOS

**Network Issues:**
```bash
# Check connectivity
ping archlinux.org

# WiFi setup
iwctl
# Follow interactive prompts
```

**Disk Space Issues:**
```bash
# Check available space
lsblk
df -h

# Clean up if needed
pacman -Sc
```

### Hardware Issues

**Graphics Problems:**
```bash
# Auto-detect and install drivers
pyrite-config --graphics
```

**Audio Issues:**
```bash
# Configure audio system
pyrite-config --audio
```

**Network Hardware:**
```bash
# Detect network hardware
pyrite-config --network
```

### System Recovery

**Boot Failure:**
```bash
# Boot from live USB
# Mount system and chroot
# Run recovery tools
pyrite-recovery bootloader
```

**System Corruption:**
```bash
# Check filesystem
pyrite-recovery fscheck

# Recover from snapshot
pyrite-recovery snapshot
```

## Performance Optimization

### Automatic Optimizations
The installer automatically configures:
- SSD-optimized I/O schedulers
- Btrfs compression (zstd)
- Network stack optimization (BBR)
- CPU microcode updates
- Memory management tuning

### Manual Optimizations
Post-installation tuning:
```bash
# CPU governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Swap configuration
sudo sysctl vm.swappiness=10

# I/O scheduling
echo mq-deadline | sudo tee /sys/block/*/queue/scheduler
```

## Security Features

### Default Security Measures
- UFW firewall enabled
- Fail2ban for SSH protection (if enabled)
- Root login disabled for SSH
- User in wheel group for sudo access
- Secure file permissions

### Additional Security
```bash
# Enable additional security measures
sudo pyrite-config --services
# Configure firewall rules, SSH hardening, etc.
```

## Maintenance

### Regular Maintenance Tasks
```bash
# Weekly system update with snapshot
sudo pyrite-update

# Monthly cleanup
sudo pyrite-backup cleanup
sudo pacman -Sc

# Quarterly system check
sudo pyrite-recovery fscheck
```

### Monitoring
```bash
# System status
pyrite-service overview

# Log analysis
pyrite-logs

# Hardware health
pyrite-config --info
```

## Support and Resources

- **GitHub Repository:** [Pyrite-Linux](https://github.com/Ghoffret/Pyrite-Linux)
- **Issue Tracking:** GitHub Issues
- **Documentation:** Project Wiki
- **Arch Linux Wiki:** Comprehensive Linux documentation
- **Community Support:** GitHub Discussions

---

**Welcome to Pyrite Linux - Your efficient, modern, and feature-rich Linux distribution!**