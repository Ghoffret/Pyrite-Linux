# Pyrite Linux

**A minimal Arch-based CLI-only distribution with Btrfs focus**

Pyrite Linux is designed for users who want a lightweight, efficient, and modern Linux distribution focused on command-line operations. Built on Arch Linux foundations with Btrfs filesystem optimizations, it provides a solid base for servers, development environments, and minimalist desktop usage.

## Features

### 🏗️ **Modern Architecture**
- **UEFI-only boot support** with systemd-boot
- **Btrfs filesystem** with advanced features:
  - Transparent compression (zstd)
  - Automatic snapshots
  - Subvolume organization
  - Built-in maintenance scripts

### 🛡️ **Security Hardened**
- **Firewall (UFW)** configured by default
- **Fail2ban** protection for SSH
- **Minimal attack surface** with disabled unnecessary services
- **Secure defaults** throughout the system

### ⚡ **Performance Optimized**
- **SSD-optimized** I/O schedulers
- **Kernel parameters** tuned for Btrfs
- **Network stack** optimizations (BBR, fq_codel)
- **Minimal package selection** for reduced overhead

### 🔧 **CLI-Focused**
- **Essential command-line tools** included
- **Development tools** for basic compilation
- **Network management** via NetworkManager
- **System monitoring** utilities

## Installation

### Prerequisites

Before running the installation script, ensure you have:

- A system with **UEFI firmware** (legacy BIOS not supported)
- **At least 8GB** of disk space
- **512MB RAM** minimum (2GB+ recommended)
- **Active internet connection**
- Booted from an **Arch Linux installation ISO**

### Quick Start

1. **Boot from Arch Linux ISO**
2. **Connect to the internet**
3. **Download and run the installer**:

```bash
# Download the installation script
curl -fsSL https://raw.githubusercontent.com/Ghoffret/Pyrite-Linux/main/install.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installer
sudo ./install.sh
```

### Installation Process

The installation script will guide you through:

1. **System Requirements Check**
   - UEFI boot mode verification
   - Internet connectivity test
   - Hardware requirements validation

2. **Disk Configuration**
   - Automatic disk detection
   - Interactive disk selection
   - Partition layout creation:
     - 512MB EFI boot partition (FAT32)
     - Optional swap partition
     - Remaining space for Btrfs root

3. **Btrfs Setup**
   - Subvolume creation (`@`, `@home`, `@var`, `@log`, `@cache`, `@snapshots`)
   - Compression enabling (zstd level 3)
   - Optimized mount options

4. **Base System Installation**
   - Arch Linux base system bootstrap
   - Essential CLI packages installation
   - Package manager optimization

5. **System Configuration**
   - Hostname, timezone, locale setup
   - User account creation
   - Network configuration
   - Bootloader installation (systemd-boot)

6. **Pyrite Optimizations**
   - Btrfs maintenance scripts
   - Automatic snapshot configuration
   - Performance tuning
   - Security hardening

## Post-Installation

### First Boot

After installation and reboot:

1. **Log in** with your created user account
2. **Check system status**: `sudo systemctl status`
3. **Update the system**: `sudo pacman -Syu`
4. **Create your first snapshot**: `create-snapshot post-install`

### Useful Commands

#### Snapshot Management
```bash
# Create a snapshot
create-snapshot [optional-name]

# List snapshots
ls /.snapshots/

# Remove old snapshots (done automatically)
btrfs subvolume delete /.snapshots/snapshot-name
```

#### Btrfs Maintenance
```bash
# Run filesystem scrub
sudo btrfs-maintenance scrub

# Run filesystem balance
sudo btrfs-maintenance balance

# Clean old snapshots
sudo btrfs-maintenance clean-snapshots
```

#### System Information
```bash
# Check Btrfs filesystem status
sudo btrfs filesystem show
sudo btrfs filesystem usage /

# Monitor system resources
htop

# Check enabled services
systemctl list-unit-files --state=enabled
```

## Package Management

Pyrite Linux uses **pacman** from Arch Linux:

```bash
# Update system
sudo pacman -Syu

# Install packages
sudo pacman -S package-name

# Remove packages
sudo pacman -Rs package-name

# Search packages
pacman -Ss search-term

# Clean package cache
sudo pacman -Sc
```

## Customization

### Adding Software

Since Pyrite Linux is based on Arch Linux, you have access to:

- **Official repositories** via pacman
- **AUR (Arch User Repository)** via AUR helpers like `yay` or `paru`
- **Flatpak** for sandboxed applications

### Network Configuration

NetworkManager is pre-configured:

```bash
# Connect to WiFi
sudo nmcli device wifi connect "SSID" password "password"

# List connections
nmcli connection show

# Show network status
nmcli general status
```

### Firewall Management

UFW (Uncomplicated Firewall) is enabled by default:

```bash
# Check firewall status
sudo ufw status

# Allow specific ports
sudo ufw allow 80/tcp
sudo ufw allow ssh

# Block specific IPs
sudo ufw deny from 192.168.1.100
```

## System Architecture

### Filesystem Layout

```
/               (Btrfs @)
├── /home       (Btrfs @home)
├── /var        (Btrfs @var)
├── /var/log    (Btrfs @log)
├── /var/cache  (Btrfs @cache)
├── /.snapshots (Btrfs @snapshots)
└── /boot       (FAT32 EFI)
```

### Services

#### Enabled by Default
- `NetworkManager` - Network management
- `systemd-timesyncd` - Time synchronization
- `ufw` - Firewall
- `btrfs-scrub.timer` - Weekly filesystem verification
- `fail2ban` - SSH brute-force protection (if SSH enabled)

#### Disabled by Default
- `bluetooth` - Bluetooth support
- `cups` - Printing system
- `avahi-daemon` - Network discovery

## Troubleshooting

### Boot Issues

If the system fails to boot:

1. **Boot from Arch ISO**
2. **Mount the system**:
   ```bash
   mount -o subvol=@ /dev/sdXN /mnt
   mount /dev/sdX1 /mnt/boot
   ```
3. **Chroot and fix**:
   ```bash
   arch-chroot /mnt
   # Fix configuration
   ```

### Btrfs Issues

For filesystem problems:

```bash
# Check filesystem
sudo btrfs check /dev/sdXN

# Scrub for errors
sudo btrfs scrub start /

# Check scrub status
sudo btrfs scrub status /
```

### Network Issues

If network is not working:

```bash
# Check NetworkManager status
sudo systemctl status NetworkManager

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Manual DHCP
sudo dhcpcd interface-name
```

## Contributing

We welcome contributions to Pyrite Linux! Please:

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

## License

Pyrite Linux installation scripts are released under the MIT License. The installed system follows Arch Linux licensing terms.

## Support

- **Issues**: [GitHub Issues](https://github.com/Ghoffret/Pyrite-Linux/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Ghoffret/Pyrite-Linux/discussions)
- **Arch Wiki**: [Arch Linux Documentation](https://wiki.archlinux.org/)

---

**Pyrite Linux** - *Minimal. Modern. Efficient.*
