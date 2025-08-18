#!/bin/bash

#############################################################################
#                                                                           #
#                 Pyrite Linux Post-Installation Validation               #
#                                                                           #
#     Comprehensive system validation after installation                   #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((VALIDATION_PASSED++))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((VALIDATION_WARNINGS++))
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((VALIDATION_FAILED++))
}

validate_boot_system() {
    print_info "Validating boot system..."
    
    # Check if systemd-boot is installed
    if [[ -f /boot/loader/loader.conf ]]; then
        print_success "systemd-boot configuration found"
    else
        print_error "systemd-boot configuration missing"
    fi
    
    # Check EFI entries
    if command -v efibootmgr &>/dev/null; then
        if efibootmgr | grep -i "pyrite\|arch" &>/dev/null; then
            print_success "UEFI boot entry found"
        else
            print_warning "UEFI boot entry not found or not named properly"
        fi
    else
        print_error "efibootmgr not available"
    fi
}

validate_filesystem() {
    print_info "Validating filesystem setup..."
    
    # Check root filesystem is Btrfs
    if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
        print_success "Root filesystem is Btrfs"
    else
        print_error "Root filesystem is not Btrfs"
    fi
    
    # Check Btrfs subvolumes
    local expected_subvols=("@" "@home" "@var" "@cache" "@snapshots")
    for subvol in "${expected_subvols[@]}"; do
        if btrfs subvolume show "/$subvol" &>/dev/null; then
            print_success "Btrfs subvolume $subvol exists"
        else
            print_error "Btrfs subvolume $subvol missing"
        fi
    done
    
    # Check compression
    if findmnt -n -o OPTIONS / | grep -q "compress"; then
        print_success "Btrfs compression enabled"
    else
        print_warning "Btrfs compression not enabled"
    fi
    
    # Check snapshot directory
    if [[ -d /.snapshots ]]; then
        print_success "Snapshot directory exists"
    else
        print_error "Snapshot directory missing"
    fi
}

validate_essential_packages() {
    print_info "Validating essential packages..."
    
    local essential_packages=(
        "base" "base-devel" "linux" "linux-firmware"
        "btrfs-progs" "networkmanager" "sudo"
    )
    
    for package in "${essential_packages[@]}"; do
        if pacman -Qi "$package" &>/dev/null; then
            print_success "Package $package is installed"
        else
            print_error "Essential package $package is missing"
        fi
    done
}

validate_services() {
    print_info "Validating system services..."
    
    local essential_services=(
        "NetworkManager"
        "systemd-timesyncd"
        "systemd-resolved"
    )
    
    for service in "${essential_services[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            print_success "Service $service is enabled"
        else
            print_warning "Service $service is not enabled"
        fi
        
        if systemctl is-active "$service" &>/dev/null; then
            print_success "Service $service is active"
        else
            print_warning "Service $service is not active"
        fi
    done
}

validate_user_setup() {
    print_info "Validating user configuration..."
    
    # Check if non-root user exists
    local user_count
    user_count=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534' | wc -l)
    
    if [[ $user_count -gt 0 ]]; then
        print_success "Non-root user account exists"
    else
        print_error "No non-root user account found"
    fi
    
    # Check sudo configuration
    if [[ -f /etc/sudoers.d/wheel ]]; then
        print_success "Sudo configuration for wheel group exists"
    else
        print_error "Sudo configuration missing"
    fi
    
    # Check if user is in wheel group
    local wheel_users
    wheel_users=$(getent group wheel | cut -d: -f4)
    if [[ -n "$wheel_users" ]]; then
        print_success "Users in wheel group: $wheel_users"
    else
        print_warning "No users in wheel group"
    fi
}

validate_network() {
    print_info "Validating network configuration..."
    
    # Check network interfaces
    if ip link show | grep -v "lo:" | grep "UP" &>/dev/null; then
        print_success "Network interface is up"
    else
        print_warning "No active network interfaces"
    fi
    
    # Check DNS resolution
    if systemctl is-active systemd-resolved &>/dev/null; then
        print_success "DNS resolution service is active"
    else
        print_warning "DNS resolution service not active"
    fi
    
    # Test connectivity if possible (might not work in chroot)
    if [[ -n "${DISPLAY:-}" ]] || [[ -f /proc/net/route ]]; then
        if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
            print_success "Internet connectivity working"
        else
            print_warning "Internet connectivity test failed"
        fi
    fi
}

validate_security() {
    print_info "Validating security configuration..."
    
    # Check firewall
    if pacman -Qi ufw &>/dev/null; then
        print_success "UFW firewall is installed"
        
        if systemctl is-enabled ufw &>/dev/null; then
            print_success "UFW firewall is enabled"
        else
            print_warning "UFW firewall is not enabled"
        fi
    else
        print_warning "UFW firewall not installed"
    fi
    
    # Check fail2ban if SSH is enabled
    if systemctl is-enabled sshd &>/dev/null; then
        if pacman -Qi fail2ban &>/dev/null; then
            print_success "Fail2ban is installed (SSH protection)"
        else
            print_warning "Fail2ban not installed but SSH is enabled"
        fi
    fi
    
    # Check SSH configuration
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
            print_success "SSH root login is disabled"
        else
            print_warning "SSH root login might be enabled"
        fi
    fi
}

validate_hardware_support() {
    print_info "Validating hardware support..."
    
    # Check microcode
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        if pacman -Qi intel-ucode &>/dev/null; then
            print_success "Intel microcode is installed"
        else
            print_warning "Intel microcode not installed"
        fi
    fi
    
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        if pacman -Qi amd-ucode &>/dev/null; then
            print_success "AMD microcode is installed"
        else
            print_warning "AMD microcode not installed"
        fi
    fi
    
    # Check graphics drivers
    if lspci | grep -i nvidia &>/dev/null; then
        if pacman -Qi nvidia &>/dev/null || pacman -Qi nvidia-open &>/dev/null; then
            print_success "NVIDIA drivers installed"
        else
            print_warning "NVIDIA hardware detected but drivers not installed"
        fi
    fi
    
    # Check audio system
    if command -v pipewire &>/dev/null; then
        print_success "PipeWire audio system is installed"
    elif command -v pulseaudio &>/dev/null; then
        print_success "PulseAudio audio system is installed"
    else
        print_warning "No modern audio system detected"
    fi
}

validate_custom_tools() {
    print_info "Validating Pyrite-specific tools..."
    
    local pyrite_tools=(
        "create-snapshot"
        "btrfs-maintenance"
    )
    
    for tool in "${pyrite_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            print_success "Pyrite tool $tool is available"
        else
            print_warning "Pyrite tool $tool not found"
        fi
    done
}

validate_package_manager() {
    print_info "Validating package manager configuration..."
    
    # Check pacman configuration
    if pacman -Sy &>/dev/null; then
        print_success "Pacman database update successful"
    else
        print_error "Pacman database update failed"
    fi
    
    # Check mirrors
    if grep -q "^Server" /etc/pacman.d/mirrorlist; then
        print_success "Pacman mirrors are configured"
    else
        print_error "No pacman mirrors configured"
    fi
    
    # Check AUR helper if enabled
    if [[ -f /tmp/pyrite-package-config.sh ]]; then
        source /tmp/pyrite-package-config.sh
        if [[ "${ENABLE_AUR:-false}" == true ]]; then
            if command -v yay &>/dev/null; then
                print_success "AUR helper (yay) is installed"
            else
                print_warning "AUR helper requested but not installed"
            fi
        fi
        
        if [[ "${ENABLE_FLATPAK:-false}" == true ]]; then
            if command -v flatpak &>/dev/null; then
                print_success "Flatpak is installed"
            else
                print_warning "Flatpak requested but not installed"
            fi
        fi
    fi
}

generate_validation_report() {
    echo
    print_info "Validation Summary:"
    echo "=================="
    echo
    echo -e "${GREEN}Passed:${NC} $VALIDATION_PASSED"
    echo -e "${YELLOW}Warnings:${NC} $VALIDATION_WARNINGS"
    echo -e "${RED}Failed:${NC} $VALIDATION_FAILED"
    echo
    
    local total=$((VALIDATION_PASSED + VALIDATION_WARNINGS + VALIDATION_FAILED))
    local success_rate=0
    if [[ $total -gt 0 ]]; then
        success_rate=$(( (VALIDATION_PASSED * 100) / total ))
    fi
    
    echo "Success rate: ${success_rate}%"
    
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        if [[ $VALIDATION_WARNINGS -eq 0 ]]; then
            print_success "System validation completed with no issues!"
        else
            print_warning "System validation completed with warnings"
        fi
        return 0
    else
        print_error "System validation failed with $VALIDATION_FAILED errors"
        return 1
    fi
}

main() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██           Pyrite Linux Post-Install Validation            ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
    
    validate_boot_system
    validate_filesystem
    validate_essential_packages
    validate_services
    validate_user_setup
    validate_network
    validate_security
    validate_hardware_support
    validate_custom_tools
    validate_package_manager
    
    echo
    generate_validation_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi