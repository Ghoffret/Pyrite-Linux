#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux Installation Script                     #
#                                                                           #
#     A minimal Arch-based CLI-only distribution with Btrfs focus          #
#                                                                           #
#############################################################################

set -euo pipefail

# Script version and constants
readonly SCRIPT_VERSION="1.0.0"
readonly PYRITE_VERSION="1.0.0"
readonly LOG_FILE="/tmp/pyrite-install.log"
readonly MIN_DISK_SIZE_GB=8
readonly MIN_RAM_MB=512
readonly BOOT_SIZE_MB=512

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
SELECTED_DISK=""
HOSTNAME=""
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
TIMEZONE=""
LOCALE="en_US.UTF-8"
ENABLE_SSH=false
ENABLE_FIREWALL=true
ENABLE_SWAP=false
SWAP_SIZE_GB=2

#############################################################################
# Utility Functions
#############################################################################

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██                    Pyrite Linux Installer                 ██"
    echo "██                      Version $PYRITE_VERSION                      ██"
    echo "██                                                            ██"
    echo "██        Minimal Arch-based CLI Distribution with Btrfs     ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n]: " response
        response=${response:-y}
    else
        read -r -p "$prompt [y/N]: " response
        response=${response:-n}
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

cleanup() {
    print_info "Cleaning up temporary files..."
    if [[ -f /tmp/pacman.conf ]]; then
        rm -f /tmp/pacman.conf
    fi
    # Note: cleanup_installation() handles more comprehensive cleanup
}

error_exit() {
    print_error "$1"
    cleanup
    exit 1
}

#############################################################################
# System Requirements Check
#############################################################################

check_boot_mode() {
    print_info "Checking boot mode..."
    
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        error_exit "System is not booted in UEFI mode. Pyrite Linux requires UEFI."
    fi
    
    print_success "UEFI boot mode confirmed"
}

check_internet() {
    print_info "Checking internet connectivity..."
    
    if ! ping -c 3 archlinux.org &>/dev/null; then
        error_exit "No internet connection. Please ensure you have a working internet connection."
    fi
    
    print_success "Internet connectivity confirmed"
}

check_memory() {
    print_info "Checking memory requirements..."
    
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_mb=$((total_mem_kb / 1024))
    
    if [[ $total_mem_mb -lt $MIN_RAM_MB ]]; then
        error_exit "Insufficient memory. Required: ${MIN_RAM_MB}MB, Available: ${total_mem_mb}MB"
    fi
    
    print_success "Memory requirements met (${total_mem_mb}MB available)"
}

check_disk_space() {
    print_info "Checking available disks..."
    
    local disks
    readarray -t disks < <(lsblk -dpno NAME,SIZE,TYPE | grep disk | awk '{print $1 " " $2}')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        error_exit "No suitable disks found for installation"
    fi
    
    local suitable_disks=()
    for disk_info in "${disks[@]}"; do
        local disk_name size_str
        read -r disk_name size_str <<< "$disk_info"
        
        # Convert size to GB (handle various size formats)
        local size_gb
        if [[ $size_str =~ ([0-9.]+)G ]]; then
            size_gb=${BASH_REMATCH[1]}
        elif [[ $size_str =~ ([0-9.]+)T ]]; then
            size_gb=$(echo "${BASH_REMATCH[1]} * 1000" | bc -l)
        else
            continue
        fi
        
        if (( $(echo "$size_gb >= $MIN_DISK_SIZE_GB" | bc -l) )); then
            suitable_disks+=("$disk_name:$size_str")
        fi
    done
    
    if [[ ${#suitable_disks[@]} -eq 0 ]]; then
        error_exit "No disk with sufficient space found. Required: ${MIN_DISK_SIZE_GB}GB"
    fi
    
    print_success "Found ${#suitable_disks[@]} suitable disk(s) for installation"
}

perform_system_checks() {
    print_header
    print_info "Performing system requirements check..."
    echo
    
    check_boot_mode
    check_internet
    check_memory
    check_disk_space
    
    echo
    print_success "All system requirements met!"
    echo
    read -r -p "Press Enter to continue..."
}

#############################################################################
# Disk Selection and Partitioning
#############################################################################

select_disk() {
    print_header
    print_info "Available disks for installation:"
    echo
    
    local disks
    readarray -t disks < <(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(sd|nvme|vd)')
    
    local disk_options=()
    local i=1
    
    for disk_line in "${disks[@]}"; do
        local disk_name size model
        read -r disk_name size model <<< "$disk_line"
        
        echo "  $i) $disk_name - $size - $model"
        disk_options+=("$disk_name")
        ((i++))
    done
    
    echo
    while true; do
        read -r -p "Select disk number (1-${#disk_options[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#disk_options[@]} ]]; then
            SELECTED_DISK="${disk_options[$((choice-1))]}"
            break
        else
            print_warning "Invalid selection. Please choose a number between 1 and ${#disk_options[@]}"
        fi
    done
    
    echo
    print_warning "Selected disk: $SELECTED_DISK"
    print_warning "ALL DATA ON THIS DISK WILL BE DESTROYED!"
    echo
    
    if ! confirm "Are you sure you want to proceed with disk $SELECTED_DISK?"; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    print_success "Disk $SELECTED_DISK selected for installation"
}

setup_swap_options() {
    echo
    if confirm "Do you want to create a swap partition?"; then
        ENABLE_SWAP=true
        
        while true; do
            read -r -p "Enter swap size in GB (default: 2): " swap_input
            swap_input=${swap_input:-2}
            
            if [[ "$swap_input" =~ ^[0-9]+$ ]] && [[ $swap_input -gt 0 ]]; then
                SWAP_SIZE_GB=$swap_input
                break
            else
                print_warning "Please enter a valid positive number"
            fi
        done
        
        print_success "Swap partition will be created (${SWAP_SIZE_GB}GB)"
    else
        ENABLE_SWAP=false
        print_info "No swap partition will be created"
    fi
}

partition_disk() {
    print_info "Partitioning disk $SELECTED_DISK..."
    
    # Unmount any existing partitions
    umount -R /mnt 2>/dev/null || true
    
    # Clear the disk
    wipefs -af "$SELECTED_DISK"
    sgdisk --zap-all "$SELECTED_DISK"
    
    # Create new GPT partition table
    sgdisk --clear \
           --new=1:0:+${BOOT_SIZE_MB}MiB --typecode=1:ef00 --change-name=1:"EFI System" \
           "$SELECTED_DISK"
    
    if [[ "$ENABLE_SWAP" == true ]]; then
        sgdisk --new=2:0:+"${SWAP_SIZE_GB}"GiB --typecode=2:8200 --change-name=2:"Linux swap" \
               --new=3:0:0 --typecode=3:8300 --change-name=3:"Linux filesystem" \
               "$SELECTED_DISK"
    else
        sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:"Linux filesystem" \
               "$SELECTED_DISK"
    fi
    
    # Inform kernel of partition changes
    partprobe "$SELECTED_DISK"
    sleep 2
    
    print_success "Disk partitioning completed"
}

format_partitions() {
    print_info "Formatting partitions..."
    
    # Determine partition names based on disk type
    local boot_part root_part swap_part
    if [[ $SELECTED_DISK =~ nvme ]]; then
        boot_part="${SELECTED_DISK}p1"
        if [[ "$ENABLE_SWAP" == true ]]; then
            swap_part="${SELECTED_DISK}p2"
            root_part="${SELECTED_DISK}p3"
        else
            root_part="${SELECTED_DISK}p2"
        fi
    else
        boot_part="${SELECTED_DISK}1"
        if [[ "$ENABLE_SWAP" == true ]]; then
            swap_part="${SELECTED_DISK}2"
            root_part="${SELECTED_DISK}3"
        else
            root_part="${SELECTED_DISK}2"
        fi
    fi
    
    # Format EFI partition
    print_info "Formatting EFI boot partition..."
    mkfs.fat -F32 -n "EFI" "$boot_part"
    
    # Format swap partition if enabled
    if [[ "$ENABLE_SWAP" == true ]]; then
        print_info "Formatting swap partition..."
        mkswap -L "SWAP" "$swap_part"
    fi
    
    # Format root partition with Btrfs
    print_info "Formatting root partition with Btrfs..."
    mkfs.btrfs -f -L "Pyrite" "$root_part"
    
    # Store partition paths for later use
    echo "$boot_part" > /tmp/boot_partition
    echo "$root_part" > /tmp/root_partition
    if [[ "$ENABLE_SWAP" == true ]]; then
        echo "$swap_part" > /tmp/swap_partition
    fi
    
    print_success "All partitions formatted successfully"
}

#############################################################################
# Btrfs Filesystem Setup
#############################################################################

setup_btrfs_subvolumes() {
    print_info "Setting up Btrfs subvolumes..."
    
    local root_part
    root_part=$(cat /tmp/root_partition)
    
    # Mount the root Btrfs filesystem
    mount "$root_part" /mnt
    
    # Create subvolumes
    print_info "Creating Btrfs subvolumes..."
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@snapshots
    
    # Unmount and remount with proper subvolumes
    umount /mnt
    
    # Mount options for Btrfs with compression and optimizations
    local mount_opts="rw,noatime,compress=zstd:3,space_cache=v2,discard=async"
    
    # Mount root subvolume
    mount -o "${mount_opts},subvol=@" "$root_part" /mnt
    
    # Create mount points
    mkdir -p /mnt/{boot,home,var,var/log,var/cache,.snapshots}
    
    # Mount other subvolumes
    mount -o "${mount_opts},subvol=@home" "$root_part" /mnt/home
    mount -o "${mount_opts},subvol=@var" "$root_part" /mnt/var
    mount -o "${mount_opts},subvol=@log" "$root_part" /mnt/var/log
    mount -o "${mount_opts},subvol=@cache" "$root_part" /mnt/var/cache
    mount -o "${mount_opts},subvol=@snapshots" "$root_part" /mnt/.snapshots
    
    # Mount EFI partition
    local boot_part
    boot_part=$(cat /tmp/boot_partition)
    mount "$boot_part" /mnt/boot
    
    # Enable swap if configured
    if [[ "$ENABLE_SWAP" == true ]]; then
        local swap_part
        swap_part=$(cat /tmp/swap_partition)
        swapon "$swap_part"
    fi
    
    print_success "Btrfs subvolumes created and mounted with zstd compression"
}

#############################################################################
# Base System Installation
#############################################################################

configure_pacman_mirrors() {
    print_info "Configuring pacman mirrors for optimal performance..."
    
    # Backup original mirrorlist
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    
    # Use reflector to find fastest mirrors
    print_info "Finding fastest mirrors..."
    if command -v reflector &> /dev/null; then
        reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    else
        print_warning "Reflector not available, using default mirrors"
    fi
    
    # Update package database
    pacman -Sy
    
    print_success "Pacman mirrors configured"
}

install_base_system() {
    print_info "Installing base Arch Linux system..."
    
    # Essential packages for Pyrite Linux
    local base_packages=(
        # Base system
        "base" "base-devel" "linux" "linux-firmware"
        
        # Bootloader and EFI
        "systemd" "efibootmgr"
        
        # Filesystem tools
        "btrfs-progs" "dosfstools" "e2fsprogs"
        
        # Network
        "networkmanager" "dhcpcd" "wpa_supplicant"
        
        # Essential CLI tools
        "bash-completion" "man-db" "man-pages" "texinfo"
        "nano" "vim" "git" "wget" "curl" "rsync"
        "htop" "tree" "unzip" "zip" "tar" "gzip"
        
        # System monitoring and utilities
        "lm_sensors" "smartmontools" "usbutils" "pciutils"
        "sudo" "which" "less" "grep" "sed" "awk"
        
        # Development tools (minimal)
        "gcc" "make" "pkg-config"
        
        # Security
        "gnupg" "openssh"
    )
    
    print_info "Installing ${#base_packages[@]} essential packages..."
    pacstrap /mnt "${base_packages[@]}"
    
    print_success "Base system installation completed"
}

generate_fstab() {
    print_info "Generating fstab..."
    
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Add some Btrfs-specific optimizations to fstab
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab
    
    print_success "fstab generated with UUID references"
}

#############################################################################
# System Configuration
#############################################################################

get_user_input() {
    print_header
    print_info "System Configuration Setup"
    echo
    
    # Hostname
    while [[ -z "$HOSTNAME" ]]; do
        read -r -p "Enter hostname for this system: " HOSTNAME
        if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
            print_warning "Invalid hostname. Use only letters, numbers, and hyphens."
            HOSTNAME=""
        fi
    done
    
    # Username
    while [[ -z "$USERNAME" ]]; do
        read -r -p "Enter username for the main user: " USERNAME
        if [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            print_warning "Invalid username. Use lowercase letters, numbers, underscore, and hyphen only."
            USERNAME=""
        fi
    done
    
    # User password
    while [[ -z "$USER_PASSWORD" ]]; do
        read -r -s -p "Enter password for user $USERNAME: " USER_PASSWORD
        echo
        if [[ ${#USER_PASSWORD} -lt 6 ]]; then
            print_warning "Password must be at least 6 characters long."
            USER_PASSWORD=""
            continue
        fi
        read -r -s -p "Confirm password: " password_confirm
        echo
        if [[ "$USER_PASSWORD" != "$password_confirm" ]]; then
            print_warning "Passwords do not match."
            USER_PASSWORD=""
        fi
    done
    
    # Root password
    while [[ -z "$ROOT_PASSWORD" ]]; do
        read -r -s -p "Enter root password: " ROOT_PASSWORD
        echo
        if [[ ${#ROOT_PASSWORD} -lt 6 ]]; then
            print_warning "Password must be at least 6 characters long."
            ROOT_PASSWORD=""
            continue
        fi
        read -r -s -p "Confirm root password: " password_confirm
        echo
        if [[ "$ROOT_PASSWORD" != "$password_confirm" ]]; then
            print_warning "Passwords do not match."
            ROOT_PASSWORD=""
        fi
    done
    
    # Timezone
    echo
    print_info "Detecting timezone..."
    TIMEZONE=$(curl -s http://ip-api.com/line?fields=timezone 2>/dev/null || echo "UTC")
    read -r -p "Enter timezone (detected: $TIMEZONE): " timezone_input
    TIMEZONE=${timezone_input:-$TIMEZONE}
    
    # Locale
    read -r -p "Enter locale (default: en_US.UTF-8): " locale_input
    LOCALE=${locale_input:-"en_US.UTF-8"}
    
    # SSH option
    echo
    if confirm "Enable SSH server?"; then
        ENABLE_SSH=true
    fi
    
    # Firewall option
    if confirm "Enable firewall?" "y"; then
        ENABLE_FIREWALL=true
    else
        ENABLE_FIREWALL=false
    fi
    
    print_success "Configuration input completed"
}

configure_system() {
    print_info "Configuring system in chroot environment..."
    
    # Create configuration script for chroot
    cat > /mnt/tmp/configure.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Read configuration variables
source /tmp/config.env

# Set timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Configure locale
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << HOSTS_EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS_EOF

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel,audio,video,optical,storage -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Configure sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel

# Enable essential services
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# Configure SSH if enabled
if [[ "$ENABLE_SSH" == "true" ]]; then
    systemctl enable sshd
    
    # Basic SSH security configuration
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
fi

# Configure mkinitcpio for Btrfs
sed -i 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

EOF

    # Create configuration environment file
    cat > /mnt/tmp/config.env << CONFIG_EOF
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
USER_PASSWORD="$USER_PASSWORD"
ROOT_PASSWORD="$ROOT_PASSWORD"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
ENABLE_SSH="$ENABLE_SSH"
ENABLE_FIREWALL="$ENABLE_FIREWALL"
CONFIG_EOF

    # Make configuration script executable
    chmod +x /mnt/tmp/configure.sh
    
    # Execute configuration in chroot
    arch-chroot /mnt /tmp/configure.sh
    
    # Clean up configuration files
    rm -f /mnt/tmp/configure.sh /mnt/tmp/config.env
    
    print_success "System configuration completed"
}

configure_bootloader() {
    print_info "Configuring systemd-boot bootloader..."
    
    # Install systemd-boot
    arch-chroot /mnt bootctl install
    
    # Create boot loader configuration
    cat > /mnt/boot/loader/loader.conf << 'EOF'
default  pyrite.conf
timeout  3
console-mode max
editor   no
EOF

    # Get root partition UUID
    local root_part
    root_part=$(cat /tmp/root_partition)
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$root_part")
    
    # Create boot entry
    cat > /mnt/boot/loader/entries/pyrite.conf << BOOT_EOF
title   Pyrite Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rootflags=subvol=@ rw noatime compress=zstd:3 space_cache=v2 discard=async
BOOT_EOF

    # Create fallback boot entry
    cat > /mnt/boot/loader/entries/pyrite-fallback.conf << BOOT_EOF
title   Pyrite Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=UUID=$root_uuid rootflags=subvol=@ rw noatime compress=zstd:3 space_cache=v2 discard=async
BOOT_EOF
    
    print_success "Systemd-boot configured with Btrfs optimizations"
}

#############################################################################
# Pyrite-specific Optimizations
#############################################################################

install_pyrite_optimizations() {
    print_info "Installing Pyrite-specific optimizations..."
    
    # Create Btrfs maintenance script
    cat > /mnt/usr/local/bin/btrfs-maintenance << 'EOF'
#!/bin/bash
# Pyrite Linux Btrfs Maintenance Script

set -euo pipefail

LOGFILE="/var/log/btrfs-maintenance.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Balance filesystem (monthly)
balance_filesystem() {
    log "Starting Btrfs balance"
    btrfs balance start -dusage=75 -musage=75 / || true
    log "Btrfs balance completed"
}

# Scrub filesystem (weekly)
scrub_filesystem() {
    log "Starting Btrfs scrub"
    btrfs scrub start / || true
    log "Btrfs scrub completed"
}

# Clean old snapshots (daily)
clean_snapshots() {
    log "Cleaning old snapshots"
    find /.snapshots -name "snapshot-*" -mtime +7 -delete || true
    log "Snapshot cleanup completed"
}

case "${1:-}" in
    balance)
        balance_filesystem
        ;;
    scrub)
        scrub_filesystem
        ;;
    clean-snapshots)
        clean_snapshots
        ;;
    *)
        echo "Usage: $0 {balance|scrub|clean-snapshots}"
        exit 1
        ;;
esac
EOF

    chmod +x /mnt/usr/local/bin/btrfs-maintenance
    
    # Create systemd service for Btrfs maintenance
    cat > /mnt/etc/systemd/system/btrfs-scrub.service << 'EOF'
[Unit]
Description=Btrfs filesystem scrub
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/btrfs-maintenance scrub
EOF

    cat > /mnt/etc/systemd/system/btrfs-scrub.timer << 'EOF'
[Unit]
Description=Run Btrfs scrub weekly
Requires=btrfs-scrub.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Create snapshot script
    cat > /mnt/usr/local/bin/create-snapshot << 'EOF'
#!/bin/bash
# Pyrite Linux Snapshot Creation Script

set -euo pipefail

SNAPSHOT_DIR="/.snapshots"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_NAME="snapshot-$TIMESTAMP"

if [[ $# -gt 0 ]]; then
    SNAPSHOT_NAME="$1-$TIMESTAMP"
fi

mkdir -p "$SNAPSHOT_DIR"

# Create read-only snapshot of root subvolume
btrfs subvolume snapshot -r / "$SNAPSHOT_DIR/$SNAPSHOT_NAME"

echo "Snapshot created: $SNAPSHOT_DIR/$SNAPSHOT_NAME"

# Keep only last 10 snapshots
cd "$SNAPSHOT_DIR"
ls -1 | grep "^snapshot-" | sort | head -n -10 | xargs -r btrfs subvolume delete
EOF

    chmod +x /mnt/usr/local/bin/create-snapshot
    
    # Enable Btrfs maintenance timer
    arch-chroot /mnt systemctl enable btrfs-scrub.timer
    
    print_success "Pyrite-specific optimizations installed"
}

configure_kernel_parameters() {
    print_info "Configuring Btrfs-optimized kernel parameters..."
    
    # Create sysctl configuration for Btrfs optimizations
    cat > /mnt/etc/sysctl.d/99-pyrite-btrfs.conf << 'EOF'
# Pyrite Linux Btrfs Optimizations

# Virtual memory settings for Btrfs
vm.dirty_background_ratio = 2
vm.dirty_ratio = 20
vm.vfs_cache_pressure = 50

# Improve I/O scheduler for SSD
# This will be set per-device by udev rules

# Network optimizations
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
EOF

    # Create udev rule for SSD optimization
    cat > /mnt/etc/udev/rules.d/99-ssd-scheduler.rules << 'EOF'
# Set I/O scheduler for different storage types
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
    
    print_success "Kernel parameters optimized for Btrfs and SSD performance"
}

#############################################################################
# Security Hardening
#############################################################################

configure_security() {
    print_info "Implementing basic security hardening..."
    
    # Configure firewall if enabled
    if [[ "$ENABLE_FIREWALL" == true ]]; then
        # Install and configure ufw
        arch-chroot /mnt pacman -S --noconfirm ufw
        
        # Basic firewall rules
        arch-chroot /mnt ufw --force enable
        arch-chroot /mnt ufw default deny incoming
        arch-chroot /mnt ufw default allow outgoing
        
        # Allow SSH if enabled
        if [[ "$ENABLE_SSH" == true ]]; then
            arch-chroot /mnt ufw allow ssh
        fi
        
        arch-chroot /mnt systemctl enable ufw
        print_success "Firewall configured and enabled"
    fi
    
    # Disable unnecessary services
    print_info "Disabling unnecessary services..."
    local services_to_disable=(
        "bluetooth.service"
        "cups.service"
        "avahi-daemon.service"
    )
    
    for service in "${services_to_disable[@]}"; do
        arch-chroot /mnt systemctl disable "$service" 2>/dev/null || true
    done
    
    # Configure fail2ban if SSH is enabled
    if [[ "$ENABLE_SSH" == true ]]; then
        arch-chroot /mnt pacman -S --noconfirm fail2ban
        
        cat > /mnt/etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF
        
        arch-chroot /mnt systemctl enable fail2ban
        print_success "Fail2ban configured for SSH protection"
    fi
    
    # Set secure permissions
    arch-chroot /mnt chmod 700 /root
    arch-chroot /mnt chmod 750 /home/"$USERNAME"
    
    print_success "Basic security hardening completed"
}

#############################################################################
# Final Setup and Cleanup
#############################################################################

final_setup() {
    print_info "Performing final setup tasks..."
    
    # Create initial snapshot
    arch-chroot /mnt /usr/local/bin/create-snapshot "initial-install"
    
    # Update package database and system
    arch-chroot /mnt pacman -Syu --noconfirm
    
    # Create welcome message
    cat > /mnt/etc/motd << 'EOF'

██████╗ ██╗   ██╗██████╗ ██╗████████╗███████╗
██╔══██╗╚██╗ ██╔╝██╔══██╗██║╚══██╔══╝██╔════╝
██████╔╝ ╚████╔╝ ██████╔╝██║   ██║   █████╗  
██╔═══╝   ╚██╔╝  ██╔══██╗██║   ██║   ██╔══╝  
██║        ██║   ██║  ██║██║   ██║   ███████╗
╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝

Welcome to Pyrite Linux - Minimal Arch-based CLI Distribution

System Information:
- Btrfs filesystem with compression enabled
- Automatic snapshots configured
- Optimized for CLI-only operation

Useful commands:
- create-snapshot [name]    : Create a new Btrfs snapshot
- btrfs-maintenance scrub   : Run filesystem scrub
- sudo systemctl status     : Check system status

EOF
    
    # Clean package cache
    arch-chroot /mnt pacman -Sc --noconfirm
    
    print_success "Final setup completed"
}

cleanup_installation() {
    print_info "Cleaning up installation..."
    
    # Remove temporary files
    rm -f /tmp/boot_partition /tmp/root_partition /tmp/swap_partition
    
    # Unmount filesystems
    umount -R /mnt 2>/dev/null || true
    
    if [[ "$ENABLE_SWAP" == true ]] && [[ -f /tmp/swap_partition ]]; then
        swapoff "$(cat /tmp/swap_partition)" 2>/dev/null || true
    fi
    
    print_success "Installation cleanup completed"
}

show_completion_message() {
    clear
    print_header
    print_success "Pyrite Linux installation completed successfully!"
    echo
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "  • Hostname: $HOSTNAME"
    echo "  • Username: $USERNAME"
    echo "  • Timezone: $TIMEZONE"
    echo "  • Locale: $LOCALE"
    echo "  • Disk: $SELECTED_DISK"
    echo "  • Filesystem: Btrfs with zstd compression"
    echo "  • Swap: $([ "$ENABLE_SWAP" == true ] && echo "Enabled (${SWAP_SIZE_GB}GB)" || echo "Disabled")"
    echo "  • SSH: $([ "$ENABLE_SSH" == true ] && echo "Enabled" || echo "Disabled")"
    echo "  • Firewall: $([ "$ENABLE_FIREWALL" == true ] && echo "Enabled" || echo "Disabled")"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Remove the installation media"
    echo "  2. Reboot the system"
    echo "  3. Log in with your user credentials"
    echo "  4. Enjoy your minimal Pyrite Linux system!"
    echo
    echo -e "${BLUE}Documentation and support: https://github.com/Ghoffret/Pyrite-Linux${NC}"
    echo
    
    if confirm "Reboot now?" "y"; then
        reboot
    fi
}

#############################################################################
# Main Installation Flow
#############################################################################

main() {
    # Initialize log file
    touch "$LOG_FILE"
    log "Pyrite Linux installation started"
    
    # Set up cleanup trap
    trap cleanup_installation EXIT
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
    
    # Perform initial checks
    perform_system_checks
    
    # Get user configuration input
    get_user_input
    
    # Disk selection and partitioning
    select_disk
    setup_swap_options
    partition_disk
    format_partitions
    
    # Btrfs setup
    setup_btrfs_subvolumes
    
    # Configure pacman and install base system
    configure_pacman_mirrors
    install_base_system
    generate_fstab
    
    # System configuration
    configure_system
    configure_bootloader
    
    # Pyrite-specific optimizations
    install_pyrite_optimizations
    configure_kernel_parameters
    
    # Security hardening
    configure_security
    
    # Final setup
    final_setup
    
    # Show completion message
    show_completion_message
    
    log "Pyrite Linux installation completed successfully"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi