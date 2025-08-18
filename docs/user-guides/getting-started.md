# Pyrite Linux User Guide

## Getting Started

Welcome to Pyrite Linux! This guide will help you get the most out of your new system.

## Essential Commands

### System Management Tools

Pyrite Linux includes several custom tools for system management:

#### pyrite-update - System Update Manager
```bash
# Interactive update with snapshot
sudo pyrite-update

# Check for updates only
sudo pyrite-update --check

# Update mirrors only
sudo pyrite-update --mirrors

# Update with specific options
sudo pyrite-update --update    # Full system update
sudo pyrite-update --aur       # AUR packages only
sudo pyrite-update --flatpak   # Flatpak packages only
```

#### pyrite-config - System Configuration
```bash
# Interactive configuration menu
pyrite-config

# Specific configuration tasks
pyrite-config --info        # System information
pyrite-config --graphics    # Graphics drivers
pyrite-config --audio       # Audio configuration
pyrite-config --network     # Network settings
```

#### pyrite-service - Service Management
```bash
# Interactive service manager
pyrite-service

# Common service operations
pyrite-service status nginx
pyrite-service start sshd
pyrite-service enable docker
pyrite-service logs NetworkManager
```

#### pyrite-backup - Snapshot Management
```bash
# Create manual snapshot
sudo pyrite-backup create "before-changes"

# List all snapshots
pyrite-backup list

# Delete old snapshots
sudo pyrite-backup cleanup

# Set up automatic snapshots
sudo pyrite-backup schedule
```

#### pyrite-logs - Log Analysis
```bash
# Interactive log analyzer
pyrite-logs

# Quick log checks
pyrite-logs boot          # Boot logs
pyrite-logs errors        # System errors
pyrite-logs failed        # Failed services
pyrite-logs hardware      # Hardware issues
```

#### pyrite-recovery - System Recovery
```bash
# Recovery menu (run as root)
sudo pyrite-recovery

# Specific recovery tasks
sudo pyrite-recovery fscheck     # Check filesystem
sudo pyrite-recovery bootloader  # Repair bootloader
sudo pyrite-recovery network     # Reset network
```

## Package Management

### Official Repositories (pacman)
```bash
# Update package database
sudo pacman -Sy

# Install packages
sudo pacman -S package-name

# Search for packages
pacman -Ss search-term

# Remove packages
sudo pacman -Rs package-name

# Update system
sudo pacman -Syu
```

### AUR Packages (yay - if enabled)
```bash
# Install AUR packages
yay -S aur-package-name

# Update AUR packages
yay -Sua

# Search AUR
yay -Ss search-term
```

### Flatpak Applications (if enabled)
```bash
# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications
flatpak install flathub app-name

# Update applications
flatpak update

# List installed apps
flatpak list
```

## Network Configuration

### WiFi Connection
```bash
# Command line (nmcli)
sudo nmcli device wifi connect "SSID" password "password"

# List available networks
nmcli device wifi list

# Check connection status
nmcli general status
```

### Ethernet Configuration
```bash
# Automatic DHCP (default)
# No configuration needed

# Static IP configuration
sudo nmcli connection modify "Wired connection 1" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns 8.8.8.8 \
  ipv4.method manual
```

## File System Management

### Btrfs Operations
```bash
# Check filesystem usage
sudo btrfs filesystem usage /

# Create subvolume
sudo btrfs subvolume create /path/to/subvolume

# List subvolumes
sudo btrfs subvolume list /

# Filesystem scrub
sudo btrfs scrub start /

# Balance filesystem
sudo btrfs balance start -dusage=75 /
```

### Snapshots
```bash
# Manual snapshot creation
sudo pyrite-backup create "snapshot-name"

# List snapshots
ls /.snapshots/

# View snapshot info
pyrite-backup info snapshot-name
```

## Audio Configuration

### PipeWire (Default)
```bash
# Control audio devices
pactl list sinks        # List output devices
pactl list sources      # List input devices

# Set default device
pactl set-default-sink sink-name

# Adjust volume
pactl set-sink-volume @DEFAULT_SINK@ +10%
pactl set-sink-volume @DEFAULT_SINK@ -10%
```

### Audio Troubleshooting
```bash
# Check audio services
systemctl --user status pipewire
systemctl --user status wireplumber

# Restart audio system
systemctl --user restart pipewire
systemctl --user restart wireplumber
```

## Security Management

### Firewall (UFW)
```bash
# Check firewall status
sudo ufw status

# Enable/disable firewall
sudo ufw enable
sudo ufw disable

# Allow services
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow from 192.168.1.0/24

# Block specific IPs
sudo ufw deny from suspicious-ip
```

### SSH Configuration
```bash
# Start SSH service
sudo systemctl start sshd
sudo systemctl enable sshd

# Connect to remote systems
ssh user@hostname

# Generate SSH keys
ssh-keygen -t ed25519
```

## System Monitoring

### System Information
```bash
# System overview
pyrite-config --info

# CPU information
lscpu

# Memory usage
free -h

# Disk usage
df -h
du -sh /*

# Hardware information
lspci           # PCI devices
lsusb           # USB devices
lsblk           # Block devices
```

### Process Management
```bash
# Process monitor
htop

# System processes
ps aux

# Kill processes
killall process-name
pkill pattern
```

### Service Status
```bash
# Service overview
pyrite-service overview

# Specific service status
systemctl status service-name

# Boot time analysis
systemd-analyze
systemd-analyze blame
```

## File Management

### Basic Operations
```bash
# Navigation
cd /path/to/directory
ls -la
pwd

# File operations
cp source destination
mv source destination
rm file
mkdir directory
rmdir directory

# Permissions
chmod 755 file
chown user:group file
```

### Advanced Operations
```bash
# Find files
find /path -name "pattern"
locate filename

# Archive operations
tar -czf archive.tar.gz directory/
tar -xzf archive.tar.gz

# Text processing
grep pattern file
sed 's/old/new/g' file
awk '{print $1}' file
```

## Development Tools

### Compilation
```bash
# C/C++ development
gcc source.c -o program
g++ source.cpp -o program
make

# Rust development
cargo new project
cargo build
cargo run

# Go development
go mod init project
go build
go run main.go
```

### Version Control
```bash
# Git operations
git clone repository
git add .
git commit -m "message"
git push origin main

# Initialize repository
git init
git remote add origin url
```

## Troubleshooting

### Common Issues

**System Won't Boot:**
```bash
# Boot from live USB and run
sudo pyrite-recovery bootloader
```

**Network Not Working:**
```bash
# Reset network configuration
sudo pyrite-recovery network

# Check network hardware
pyrite-config --network
```

**Audio Not Working:**
```bash
# Configure audio system
pyrite-config --audio

# Check audio logs
pyrite-logs | grep audio
```

**System Running Slow:**
```bash
# Check system resources
htop
pyrite-logs performance

# Clean up system
sudo pacman -Sc
sudo pyrite-backup cleanup
```

### Log Analysis
```bash
# Boot issues
pyrite-logs boot

# Service failures
pyrite-logs failed

# Hardware problems
pyrite-logs hardware

# Recent errors
pyrite-logs errors "1 hour ago"
```

## Customization

### Shell Configuration
```bash
# Bash configuration
~/.bashrc          # Bash configuration
~/.bash_profile    # Login shell configuration

# ZSH (if installed)
~/.zshrc           # ZSH configuration
```

### Desktop Environment (if installed)
```bash
# i3 window manager
~/.config/i3/config

# XFCE configuration
~/.config/xfce4/

# Sway (Wayland)
~/.config/sway/config
```

## Maintenance Tasks

### Daily
```bash
# Check system status
pyrite-service overview
```

### Weekly
```bash
# System update with snapshot
sudo pyrite-update
```

### Monthly
```bash
# Clean package cache
sudo pacman -Sc

# Cleanup old snapshots
sudo pyrite-backup cleanup

# Check filesystem
sudo pyrite-recovery fscheck
```

## Getting Help

### Built-in Help
```bash
# Command help
command --help
man command

# Pyrite tool help
pyrite-update --help
pyrite-config --help
```

### Online Resources
- Arch Linux Wiki: https://wiki.archlinux.org/
- Pyrite GitHub: https://github.com/Ghoffret/Pyrite-Linux
- Community forums and discussions

### System Information for Support
```bash
# Generate system report
pyrite-logs export /tmp/system-report
pyrite-config --info > /tmp/hardware-info.txt
```

---

**Happy computing with Pyrite Linux!**