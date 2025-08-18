#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux Hardware Detection                      #
#                                                                           #
#     Comprehensive hardware detection and driver recommendation           #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables for detected hardware
DETECTED_GPU=""
DETECTED_WIFI=""
DETECTED_BLUETOOTH=""
DETECTED_AUDIO=""
RECOMMENDED_PACKAGES=()

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_gpu() {
    print_info "Detecting graphics hardware..."
    
    # Detect NVIDIA
    if lspci | grep -i nvidia &>/dev/null; then
        DETECTED_GPU="nvidia"
        RECOMMENDED_PACKAGES+=("nvidia" "nvidia-utils" "nvidia-settings")
        print_success "NVIDIA GPU detected"
    fi
    
    # Detect AMD
    if lspci | grep -i amd | grep -i vga &>/dev/null || lspci | grep -i radeon &>/dev/null; then
        DETECTED_GPU="amd"
        RECOMMENDED_PACKAGES+=("mesa" "vulkan-radeon" "libva-mesa-driver" "mesa-vdpau")
        print_success "AMD GPU detected"
    fi
    
    # Detect Intel
    if lspci | grep -i intel | grep -i vga &>/dev/null; then
        DETECTED_GPU="intel"
        RECOMMENDED_PACKAGES+=("mesa" "vulkan-intel" "intel-media-driver" "libva-intel-driver")
        print_success "Intel GPU detected"
    fi
    
    if [[ -z "$DETECTED_GPU" ]]; then
        print_warning "No specific GPU detected, using generic drivers"
        RECOMMENDED_PACKAGES+=("mesa")
    fi
}

detect_wifi() {
    print_info "Detecting WiFi hardware..."
    
    # Common WiFi chipsets
    if lspci | grep -i "intel.*wireless\|iwl" &>/dev/null; then
        DETECTED_WIFI="intel"
        RECOMMENDED_PACKAGES+=("iwlwifi-firmware")
        print_success "Intel WiFi detected"
    fi
    
    if lspci | grep -i broadcom &>/dev/null; then
        DETECTED_WIFI="broadcom"
        RECOMMENDED_PACKAGES+=("broadcom-wl")
        print_success "Broadcom WiFi detected"
    fi
    
    if lspci | grep -i realtek &>/dev/null; then
        DETECTED_WIFI="realtek"
        RECOMMENDED_PACKAGES+=("linux-firmware")
        print_success "Realtek WiFi detected"
    fi
    
    if lspci | grep -i atheros &>/dev/null; then
        DETECTED_WIFI="atheros"
        RECOMMENDED_PACKAGES+=("linux-firmware")
        print_success "Atheros WiFi detected"
    fi
    
    # Add general WiFi support
    RECOMMENDED_PACKAGES+=("wpa_supplicant" "iw" "wireless_tools")
}

detect_bluetooth() {
    print_info "Detecting Bluetooth hardware..."
    
    if lsusb | grep -i bluetooth &>/dev/null || dmesg | grep -i bluetooth &>/dev/null; then
        DETECTED_BLUETOOTH="detected"
        RECOMMENDED_PACKAGES+=("bluez" "bluez-utils" "bluez-firmware")
        print_success "Bluetooth hardware detected"
    fi
}

detect_audio() {
    print_info "Detecting audio hardware..."
    
    if lspci | grep -i audio &>/dev/null; then
        DETECTED_AUDIO="detected"
        RECOMMENDED_PACKAGES+=("pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack" "wireplumber")
        print_success "Audio hardware detected"
        
        # Check for specific audio chipsets
        if lspci | grep -i "intel.*audio" &>/dev/null; then
            RECOMMENDED_PACKAGES+=("sof-firmware")
            print_success "Intel audio detected - adding SOF firmware"
        fi
    fi
}

detect_cpu() {
    print_info "Detecting CPU microcode..."
    
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        RECOMMENDED_PACKAGES+=("intel-ucode")
        print_success "Intel CPU detected - adding microcode"
    fi
    
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        RECOMMENDED_PACKAGES+=("amd-ucode")
        print_success "AMD CPU detected - adding microcode"
    fi
}

detect_storage() {
    print_info "Detecting storage devices..."
    
    # Check for NVMe drives
    if ls /dev/nvme* &>/dev/null; then
        RECOMMENDED_PACKAGES+=("nvme-cli")
        print_success "NVMe storage detected"
    fi
    
    # Add general storage utilities
    RECOMMENDED_PACKAGES+=("smartmontools" "hdparm")
}

detect_virtualization() {
    print_info "Checking for virtualization environment..."
    
    if systemd-detect-virt &>/dev/null; then
        local virt_type
        virt_type=$(systemd-detect-virt)
        print_success "Virtualization detected: $virt_type"
        
        case "$virt_type" in
            "vmware")
                RECOMMENDED_PACKAGES+=("open-vm-tools")
                ;;
            "oracle")
                RECOMMENDED_PACKAGES+=("virtualbox-guest-utils")
                ;;
            "qemu"|"kvm")
                RECOMMENDED_PACKAGES+=("qemu-guest-agent")
                ;;
        esac
    fi
}

check_hardware_compatibility() {
    print_info "Checking hardware compatibility..."
    
    # Check for UEFI
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        print_error "UEFI firmware required for Pyrite Linux"
        return 1
    fi
    
    # Check memory
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_mb=$((total_mem_kb / 1024))
    
    if [[ $total_mem_mb -lt 512 ]]; then
        print_error "Insufficient memory. Required: 512MB, Available: ${total_mem_mb}MB"
        return 1
    fi
    
    # Check architecture
    if [[ "$(uname -m)" != "x86_64" ]]; then
        print_error "Only x86_64 architecture is supported"
        return 1
    fi
    
    print_success "Hardware compatibility check passed"
    return 0
}

generate_hardware_report() {
    echo
    print_info "Hardware Detection Summary:"
    echo "=========================="
    
    echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo "Memory: $(grep MemTotal /proc/meminfo | awk '{print int($2/1024) " MB"}')"
    echo "GPU: ${DETECTED_GPU:-"Generic"}"
    echo "WiFi: ${DETECTED_WIFI:-"Not detected"}"
    echo "Bluetooth: ${DETECTED_BLUETOOTH:-"Not detected"}"
    echo "Audio: ${DETECTED_AUDIO:-"Not detected"}"
    
    echo
    print_info "Recommended additional packages:"
    if [[ ${#RECOMMENDED_PACKAGES[@]} -gt 0 ]]; then
        printf '%s\n' "${RECOMMENDED_PACKAGES[@]}" | sort -u
    else
        echo "None"
    fi
}

save_hardware_info() {
    local output_file="${1:-/tmp/pyrite-hardware.json}"
    
    cat > "$output_file" << EOF
{
    "cpu": "$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)",
    "memory_mb": $(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'),
    "gpu": "${DETECTED_GPU:-"generic"}",
    "wifi": "${DETECTED_WIFI:-"none"}",
    "bluetooth": "${DETECTED_BLUETOOTH:-"none"}",
    "audio": "${DETECTED_AUDIO:-"none"}",
    "recommended_packages": [$(printf '"%s",' "${RECOMMENDED_PACKAGES[@]}" | sed 's/,$//')],
    "timestamp": "$(date -Iseconds)"
}
EOF
    
    print_success "Hardware information saved to $output_file"
}

main() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██              Pyrite Linux Hardware Detection               ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
    
    if ! check_hardware_compatibility; then
        print_error "Hardware compatibility check failed!"
        exit 1
    fi
    
    detect_cpu
    detect_gpu
    detect_wifi
    detect_bluetooth
    detect_audio
    detect_storage
    detect_virtualization
    
    generate_hardware_report
    save_hardware_info
    
    echo
    print_success "Hardware detection completed successfully!"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi