# Pyrite Linux Installation Guide

## Quick Installation

### Step 1: Boot Arch Linux ISO
1. Download the latest Arch Linux ISO from [archlinux.org](https://archlinux.org/download/)
2. Create a bootable USB drive
3. Boot from the USB drive in UEFI mode

### Step 2: Prepare the Environment
```bash
# Ensure you have internet connectivity
ping archlinux.org

# Update system clock
timedatectl set-ntp true

# If using WiFi, connect using iwctl
iwctl
# Then in iwctl prompt:
# station wlan0 scan
# station wlan0 get-networks
# station wlan0 connect "Your-WiFi-SSID"
# exit
```

### Step 3: Download and Run Installer
```bash
# Download the installation script
curl -fsSL https://raw.githubusercontent.com/Ghoffret/Pyrite-Linux/main/install.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installer as root
./install.sh
```

### Step 4: Follow Interactive Setup
The installer will guide you through:

1. **System Requirements Check**
   - Automatically validates UEFI mode, internet, memory, and disk space

2. **Configuration Input**
   - Hostname for your system
   - Username and password for your user account
   - Root password
   - Timezone (auto-detected)
   - Locale settings
   - SSH and firewall preferences

3. **Disk Selection**
   - Choose target disk from available options
   - Configure swap partition (optional)
   - **WARNING**: All data on selected disk will be erased!

4. **Automated Installation**
   - Disk partitioning and formatting
   - Btrfs filesystem setup with subvolumes
   - Base Arch Linux installation
   - System configuration
   - Bootloader setup
   - Security hardening

### Step 5: Reboot and Enjoy
```bash
# Remove installation media and reboot
# The installer will offer to reboot automatically
```

## Installation Options

### Disk Configuration
- **Minimum disk space**: 8GB
- **EFI boot partition**: 512MB (automatically created)
- **Swap**: Optional, configurable size
- **Root filesystem**: Btrfs with compression

### Network Setup
- **Ethernet**: Automatically configured via DHCP
- **WiFi**: Use NetworkManager after installation
- **SSH**: Optional, can be enabled during installation

### Security Features
- **Firewall**: UFW enabled by default
- **Fail2ban**: Installed if SSH is enabled
- **User account**: Added to sudo group
- **Root login**: Disabled for SSH

## Post-Installation

### First Login
```bash
# Log in with your created user account
# Check system status
sudo systemctl status

# Update the system
sudo pacman -Syu

# Create first snapshot
create-snapshot first-boot
```

### Essential Commands
```bash
# Package management
sudo pacman -S package-name     # Install package
sudo pacman -Rs package-name    # Remove package
sudo pacman -Syu               # Update system

# Network management
nmcli device wifi list         # List WiFi networks
sudo nmcli device wifi connect "SSID" password "password"

# Btrfs snapshots
create-snapshot [name]          # Create snapshot
ls /.snapshots/                # List snapshots

# System monitoring
htop                           # Process monitor
journalctl -f                  # Live system logs
systemctl status service-name  # Check service status
```

## Troubleshooting

### Installation Fails
- Ensure you're booted in UEFI mode
- Check internet connectivity
- Verify minimum hardware requirements
- Check installation log: `/tmp/pyrite-install.log`

### Network Issues After Installation
```bash
# Check NetworkManager status
sudo systemctl status NetworkManager

# Restart network service
sudo systemctl restart NetworkManager

# Manual connection
sudo dhcpcd interface-name
```

### Boot Issues
1. Boot from Arch Linux ISO
2. Mount system: `mount -o subvol=@ /dev/sdXN /mnt`
3. Mount boot: `mount /dev/sdX1 /mnt/boot`
4. Chroot: `arch-chroot /mnt`
5. Fix bootloader: `bootctl install`

## Advanced Configuration

### AUR Support
```bash
# Install AUR helper (yay)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Use AUR
yay -S package-name
```

### Custom Services
```bash
# Create systemd service
sudo systemctl edit --force custom.service

# Enable and start
sudo systemctl enable --now custom.service
```

### Btrfs Management
```bash
# Check filesystem usage
sudo btrfs filesystem usage /

# Manual scrub
sudo btrfs scrub start /

# Balance filesystem
sudo btrfs balance start -dusage=75 /

# Create subvolume
sudo btrfs subvolume create /path/to/subvolume
```

## Support

- **GitHub Issues**: Report bugs and request features
- **Arch Wiki**: Comprehensive Linux documentation
- **Community**: Join discussions and get help

---

*Happy computing with Pyrite Linux!*