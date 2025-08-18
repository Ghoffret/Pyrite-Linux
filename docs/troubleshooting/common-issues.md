# Pyrite Linux Troubleshooting Guide

## Common Installation Issues

### Boot and Installation Problems

#### System Won't Boot from USB
**Symptoms:** Computer doesn't boot from Pyrite Linux USB
**Causes:**
- UEFI/Legacy BIOS mismatch
- Secure Boot enabled
- Fast Boot enabled
- USB not properly created

**Solutions:**
1. **Check BIOS/UEFI Settings:**
   ```
   - Disable Secure Boot
   - Disable Fast Boot
   - Enable USB Boot
   - Set boot priority to USB first
   ```

2. **Recreate USB Drive:**
   ```bash
   # Linux
   sudo dd if=pyrite-linux.iso of=/dev/sdX bs=4M status=progress
   
   # Windows (use Rufus or Etcher)
   # macOS (use Etcher or command line)
   sudo dd if=pyrite-linux.iso of=/dev/diskX bs=4m
   ```

#### Installation Fails During Package Installation
**Symptoms:** Error during package installation phase
**Causes:**
- Network connectivity issues
- Mirror problems
- Insufficient disk space
- Corrupted packages

**Solutions:**
1. **Check Network Connection:**
   ```bash
   ping archlinux.org
   ```

2. **Update Mirrors:**
   ```bash
   sudo pyrite-update --mirrors
   ```

3. **Check Disk Space:**
   ```bash
   df -h
   lsblk
   ```

#### Hardware Detection Fails
**Symptoms:** Graphics, WiFi, or other hardware not working
**Causes:**
- Missing drivers
- Unsupported hardware
- Kernel module issues

**Solutions:**
1. **Run Hardware Detection:**
   ```bash
   sudo /opt/pyrite/installer/hardware-detect.sh
   ```

2. **Manual Driver Installation:**
   ```bash
   # NVIDIA
   sudo pacman -S nvidia nvidia-utils
   
   # AMD
   sudo pacman -S mesa vulkan-radeon
   
   # Intel
   sudo pacman -S mesa vulkan-intel
   ```

### Post-Installation Issues

#### System Won't Boot After Installation
**Symptoms:** Bootloader error, kernel panic, or black screen
**Causes:**
- Bootloader not installed correctly
- Wrong graphics drivers
- Kernel issues

**Solutions:**
1. **Boot from Live USB and Repair:**
   ```bash
   # Mount system
   sudo mount -o subvol=@ /dev/sdXY /mnt
   sudo mount /dev/sdX1 /mnt/boot
   
   # Chroot into system
   sudo arch-chroot /mnt
   
   # Repair bootloader
   bootctl install
   bootctl update
   ```

2. **Fix Graphics Issues:**
   ```bash
   # Add nomodeset to kernel parameters temporarily
   # Edit /boot/loader/entries/arch.conf
   # Add: nomodeset
   ```

#### Network Not Working
**Symptoms:** No internet connection, WiFi not visible
**Causes:**
- NetworkManager not running
- Missing WiFi drivers
- Wrong network configuration

**Solutions:**
1. **Check NetworkManager:**
   ```bash
   systemctl status NetworkManager
   sudo systemctl start NetworkManager
   sudo systemctl enable NetworkManager
   ```

2. **WiFi Configuration:**
   ```bash
   # Check WiFi device
   ip link show
   
   # Manual WiFi connection
   sudo nmcli device wifi connect "SSID" password "password"
   
   # Or use iwctl
   iwctl
   ```

3. **Install WiFi Drivers:**
   ```bash
   # Intel
   sudo pacman -S iwlwifi-firmware
   
   # Broadcom
   sudo pacman -S broadcom-wl
   
   # Realtek
   sudo pacman -S linux-firmware
   ```

#### Audio Not Working
**Symptoms:** No sound output, audio devices not detected
**Causes:**
- Audio system not configured
- Wrong audio drivers
- Muted channels

**Solutions:**
1. **Check Audio System:**
   ```bash
   systemctl --user status pipewire
   systemctl --user start pipewire
   systemctl --user start wireplumber
   ```

2. **Install Audio Drivers:**
   ```bash
   sudo pacman -S pipewire pipewire-alsa pipewire-pulse wireplumber
   ```

3. **Configure Audio:**
   ```bash
   # List audio devices
   pactl list sinks
   
   # Set default device
   pactl set-default-sink sink-name
   
   # Test audio
   speaker-test -t sine -f 1000 -l 3
   ```

## System Performance Issues

### Slow Boot Times
**Symptoms:** System takes long time to boot
**Causes:**
- Too many services starting
- Slow storage
- Hardware issues

**Solutions:**
1. **Analyze Boot Performance:**
   ```bash
   systemd-analyze
   systemd-analyze blame
   systemd-analyze critical-chain
   ```

2. **Disable Unnecessary Services:**
   ```bash
   sudo pyrite-service list enabled
   sudo systemctl disable unwanted-service
   ```

3. **Optimize Storage:**
   ```bash
   # Check if SSD optimization is enabled
   cat /sys/block/sda/queue/scheduler
   
   # Should show [mq-deadline] for SSD
   ```

### High Memory Usage
**Symptoms:** System running out of memory
**Causes:**
- Memory leaks
- Too many applications
- Insufficient swap

**Solutions:**
1. **Check Memory Usage:**
   ```bash
   free -h
   htop
   ps aux --sort=-%mem | head -10
   ```

2. **Add Swap:**
   ```bash
   # Create swap file
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   
   # Make permanent
   echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
   ```

3. **Optimize Memory:**
   ```bash
   # Adjust swappiness
   echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
   ```

### High CPU Usage
**Symptoms:** System slow, high CPU usage
**Causes:**
- Runaway processes
- Inefficient services
- Malware

**Solutions:**
1. **Identify CPU Hogs:**
   ```bash
   htop
   ps aux --sort=-%cpu | head -10
   ```

2. **Check for Issues:**
   ```bash
   # Check system logs
   pyrite-logs errors "1 hour ago"
   
   # Check failed services
   pyrite-logs failed
   ```

## Package Management Issues

### Pacman Errors
**Symptoms:** Package installation/update failures
**Causes:**
- Corrupted databases
- Key issues
- Disk space problems

**Solutions:**
1. **Fix Pacman Database:**
   ```bash
   # Update keyring
   sudo pacman -S archlinux-keyring
   
   # Clear cache
   sudo pacman -Sc
   
   # Force refresh
   sudo pacman -Syy
   ```

2. **Fix GPG Keys:**
   ```bash
   sudo pacman-key --init
   sudo pacman-key --populate archlinux
   sudo pacman-key --refresh-keys
   ```

### AUR Issues
**Symptoms:** AUR packages won't install
**Causes:**
- Missing dependencies
- Build failures
- Outdated packages

**Solutions:**
1. **Manual AUR Installation:**
   ```bash
   git clone https://aur.archlinux.org/package-name.git
   cd package-name
   makepkg -si
   ```

2. **Fix Dependencies:**
   ```bash
   # Install base-devel if missing
   sudo pacman -S base-devel
   ```

## Hardware-Specific Issues

### NVIDIA Graphics Issues
**Symptoms:** Poor performance, crashes, artifacts
**Causes:**
- Wrong drivers
- Configuration issues
- Power management

**Solutions:**
1. **Install Correct Drivers:**
   ```bash
   # Remove nouveau
   echo 'blacklist nouveau' | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
   
   # Install NVIDIA drivers
   sudo pacman -S nvidia nvidia-utils nvidia-settings
   ```

2. **Fix Configuration:**
   ```bash
   # Generate xorg.conf
   sudo nvidia-xconfig
   
   # Check configuration
   nvidia-settings
   ```

### WiFi Connection Problems
**Symptoms:** Frequent disconnections, slow speeds
**Causes:**
- Power management
- Driver issues
- Interference

**Solutions:**
1. **Disable Power Management:**
   ```bash
   echo 'options iwlwifi power_save=0' | sudo tee /etc/modprobe.d/iwlwifi.conf
   ```

2. **Check Signal Strength:**
   ```bash
   nmcli device wifi list
   iwconfig
   ```

### Bluetooth Issues
**Symptoms:** Devices won't pair, audio stuttering
**Causes:**
- Service not running
- Driver issues
- Configuration problems

**Solutions:**
1. **Check Bluetooth Service:**
   ```bash
   systemctl status bluetooth
   sudo systemctl start bluetooth
   sudo systemctl enable bluetooth
   ```

2. **Reset Bluetooth:**
   ```bash
   # Remove paired devices
   sudo rm -rf /var/lib/bluetooth/*
   sudo systemctl restart bluetooth
   ```

## Emergency Recovery

### Boot to Emergency Mode
**When:** System won't boot normally
**How:**
1. Boot from Pyrite Linux live USB
2. Mount your system
3. Use recovery tools

```bash
# Mount system
sudo mount -o subvol=@ /dev/sdXY /mnt
sudo mount /dev/sdX1 /mnt/boot

# Chroot into system
sudo arch-chroot /mnt

# Run recovery tools
/opt/pyrite/installer/post-install-validation.sh
```

### System Recovery Tools
```bash
# Use Pyrite recovery tools
sudo pyrite-recovery

# Check filesystem
sudo pyrite-recovery fscheck

# Fix bootloader
sudo pyrite-recovery bootloader

# Reset network
sudo pyrite-recovery network
```

### Snapshot Recovery
```bash
# List snapshots
pyrite-backup list

# Boot from live USB and restore snapshot
# (Manual process - requires advanced knowledge)
```

## Getting Help

### Log Collection
Before seeking help, collect system information:
```bash
# Generate system report
pyrite-logs export /tmp/system-report

# Hardware information
pyrite-config --info > /tmp/hardware-info.txt

# Package information
pacman -Q > /tmp/packages.txt
```

### Support Channels
- **GitHub Issues**: Report bugs and get help
- **Arch Linux Wiki**: Comprehensive documentation
- **Community Forums**: User discussions
- **IRC/Discord**: Real-time help

### Reporting Bugs
Include the following information:
- System specs (from `pyrite-config --info`)
- Error messages (from logs)
- Steps to reproduce
- Expected vs actual behavior

---

**Remember:** Most issues can be resolved with patience and systematic troubleshooting. When in doubt, check the logs first!