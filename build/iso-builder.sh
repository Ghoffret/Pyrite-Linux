#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux ISO Builder                             #
#                                                                           #
#     Custom ISO generation pipeline using archiso                         #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly PYRITE_VERSION="1.0.0"
readonly ISO_LABEL="PYRITE_$(date +%Y%m%d)"
readonly BUILD_DIR="/tmp/pyrite-build"
readonly OUTPUT_DIR="./iso-output"

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

check_dependencies() {
    print_info "Checking build dependencies..."
    
    local deps=("archiso" "mkarchiso" "pacman" "arch-install-scripts")
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            print_success "Found dependency: $dep"
        else
            print_error "Missing dependency: $dep"
            print_info "Install with: sudo pacman -S archiso"
            exit 1
        fi
    done
}

prepare_build_environment() {
    print_info "Preparing build environment..."
    
    # Clean previous builds
    if [[ -d "$BUILD_DIR" ]]; then
        print_info "Cleaning previous build directory..."
        sudo rm -rf "$BUILD_DIR"
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Copy archiso profile as base
    print_info "Copying archiso baseline profile..."
    cp -r /usr/share/archiso/configs/baseline/* "$BUILD_DIR/"
    
    print_success "Build environment prepared"
}

customize_archiso_profile() {
    print_info "Customizing archiso profile for Pyrite Linux..."
    
    # Update packages.x86_64
    cat >> "$BUILD_DIR/packages.x86_64" << 'EOF'

# Pyrite Linux additions
reflector
python
networkmanager
dhcpcd
wpa_supplicant
btrfs-progs
git
curl
wget
nano
vim
EOF
    
    # Create custom syslinux configuration
    cat > "$BUILD_DIR/syslinux/syslinux.cfg" << EOF
UI menu.c32
PROMPT 0
TIMEOUT 150
ONTIMEOUT pyrite

MENU TITLE Pyrite Linux Live/Install Environment
MENU BACKGROUND splash.png

LABEL pyrite
    MENU LABEL Pyrite Linux (x86_64)
    MENU DEFAULT
    LINUX /%INSTALL_DIR%/boot/x86_64/vmlinuz-linux
    INITRD /%INSTALL_DIR%/boot/x86_64/initramfs-linux.img
    APPEND archisobasedir=%INSTALL_DIR% archisolabel=$ISO_LABEL

LABEL pyritenomodeset
    MENU LABEL Pyrite Linux (x86_64, nomodeset)
    LINUX /%INSTALL_DIR%/boot/x86_64/vmlinuz-linux
    INITRD /%INSTALL_DIR%/boot/x86_64/initramfs-linux.img
    APPEND archisobasedir=%INSTALL_DIR% archisolabel=$ISO_LABEL nomodeset

LABEL memtest
    MENU LABEL Memory Test (memtest86+)
    LINUX /%INSTALL_DIR%/boot/memtest86+/memtest.bin

LABEL reboot
    MENU LABEL Reboot
    COM32 reboot.c32

LABEL poweroff
    MENU LABEL Power Off
    COM32 poweroff.c32
EOF
    
    print_success "Archiso profile customized"
}

add_pyrite_files() {
    print_info "Adding Pyrite Linux files to ISO..."
    
    # Create airootfs directory structure
    local airootfs="$BUILD_DIR/airootfs"
    mkdir -p "$airootfs/opt/pyrite"
    mkdir -p "$airootfs/etc/skel"
    
    # Copy Pyrite Linux installer and tools
    cp -r ../installer "$airootfs/opt/pyrite/"
    cp -r ../tools "$airootfs/opt/pyrite/"
    cp -r ../packages "$airootfs/opt/pyrite/"
    cp -r ../docs "$airootfs/opt/pyrite/"
    
    # Create installation script in PATH
    cat > "$airootfs/usr/local/bin/install-pyrite" << 'EOF'
#!/bin/bash
cd /opt/pyrite/installer
./pyrite-install.sh "$@"
EOF
    chmod +x "$airootfs/usr/local/bin/install-pyrite"
    
    # Add welcome message
    cat > "$airootfs/etc/motd" << EOF

████████████████████████████████████████████████████████████████
██                                                            ██
██                    Welcome to Pyrite Linux                 ██
██                      Version $PYRITE_VERSION                      ██
██                                                            ██
██        Minimal Arch-based CLI Distribution with Btrfs     ██
██                                                            ██
████████████████████████████████████████████████████████████████

Quick Start:
  install-pyrite     - Start Pyrite Linux installation
  pyrite-detect      - Detect hardware before installation
  pyrite-packages    - Select package profile

Documentation:
  /opt/pyrite/docs/  - Installation and user guides

Network Setup:
  iwctl              - WiFi configuration
  dhcpcd             - Ethernet DHCP client

For help: /opt/pyrite/installer/pyrite-install.sh --help

EOF
    
    # Create desktop shortcuts (if X11 is available)
    mkdir -p "$airootfs/etc/skel/Desktop"
    cat > "$airootfs/etc/skel/Desktop/install-pyrite.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Install Pyrite Linux
Comment=Start Pyrite Linux installation
Exec=lxterminal -e "sudo install-pyrite"
Icon=system-installer
Categories=System;
EOF
    
    print_success "Pyrite Linux files added to ISO"
}

customize_live_environment() {
    print_info "Customizing live environment..."
    
    local airootfs="$BUILD_DIR/airootfs"
    
    # Auto-start NetworkManager
    mkdir -p "$airootfs/etc/systemd/system/multi-user.target.wants"
    ln -sf /usr/lib/systemd/system/NetworkManager.service \
        "$airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
    
    # Create custom bash profile
    cat >> "$airootfs/etc/skel/.bashrc" << 'EOF'

# Pyrite Linux Live Environment
export PS1='\[\033[1;32m\]pyrite-live\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '

# Aliases for common tasks
alias install-pyrite='sudo /opt/pyrite/installer/pyrite-install.sh'
alias pyrite-detect='sudo /opt/pyrite/installer/hardware-detect.sh'
alias pyrite-packages='/opt/pyrite/installer/package-selector.sh'

# Show welcome message on first login
if [[ ! -f ~/.pyrite-welcome-shown ]]; then
    cat /etc/motd
    touch ~/.pyrite-welcome-shown
fi
EOF
    
    # Configure automatic login (optional)
    mkdir -p "$airootfs/etc/systemd/system/getty@tty1.service.d"
    cat > "$airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root %I $TERM
EOF
    
    print_success "Live environment customized"
}

build_iso() {
    print_info "Building Pyrite Linux ISO..."
    
    # Set ISO label in profiledef.sh
    sed -i "s/iso_label=.*/iso_label=\"$ISO_LABEL\"/" "$BUILD_DIR/profiledef.sh"
    sed -i "s/iso_name=.*/iso_name=\"pyrite-linux\"/" "$BUILD_DIR/profiledef.sh"
    sed -i "s/iso_version=.*/iso_version=\"$PYRITE_VERSION\"/" "$BUILD_DIR/profiledef.sh"
    
    # Build the ISO
    print_info "Starting mkarchiso (this may take a while)..."
    
    if sudo mkarchiso -v -w /tmp/archiso-tmp -o "$OUTPUT_DIR" "$BUILD_DIR"; then
        print_success "ISO build completed successfully!"
        
        # Find the generated ISO
        local iso_file
        iso_file=$(find "$OUTPUT_DIR" -name "*.iso" -type f | head -1)
        
        if [[ -n "$iso_file" ]]; then
            print_success "ISO created: $iso_file"
            print_info "ISO size: $(du -h "$iso_file" | cut -f1)"
            
            # Generate checksums
            cd "$OUTPUT_DIR"
            sha256sum "$(basename "$iso_file")" > "$(basename "$iso_file").sha256"
            print_success "SHA256 checksum generated"
        fi
    else
        print_error "ISO build failed!"
        return 1
    fi
}

test_iso() {
    print_info "ISO testing recommendations:"
    echo
    echo "1. Test in virtual machine:"
    echo "   qemu-system-x86_64 -m 2048 -cdrom pyrite-linux-*.iso"
    echo
    echo "2. Test on real hardware:"
    echo "   dd if=pyrite-linux-*.iso of=/dev/sdX bs=4M status=progress"
    echo
    echo "3. Verify checksum:"
    echo "   sha256sum -c pyrite-linux-*.iso.sha256"
    echo
}

cleanup() {
    print_info "Cleaning up build files..."
    
    if [[ -d "$BUILD_DIR" ]]; then
        sudo rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    fi
    
    if [[ -d "/tmp/archiso-tmp" ]]; then
        sudo rm -rf "/tmp/archiso-tmp"
        print_success "Temporary files cleaned"
    fi
}

show_help() {
    echo "Pyrite Linux ISO Builder - Custom ISO generation pipeline"
    echo
    echo "Usage: iso-builder.sh [OPTION]"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -b, --build      Build ISO (default)"
    echo "  -c, --clean      Clean build files only"
    echo "  -t, --test       Show testing recommendations"
    echo
    echo "Examples:"
    echo "  ./iso-builder.sh              # Build ISO"
    echo "  ./iso-builder.sh --clean      # Clean build files"
    echo "  ./iso-builder.sh --test       # Show test instructions"
}

main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            cleanup
            exit 0
            ;;
        -t|--test)
            test_iso
            exit 0
            ;;
        -b|--build|"")
            echo -e "${BLUE}"
            echo "████████████████████████████████████████████████████████████████"
            echo "██                                                            ██"
            echo "██                 Pyrite Linux ISO Builder                   ██"
            echo "██                      Version $PYRITE_VERSION                      ██"
            echo "██                                                            ██"
            echo "████████████████████████████████████████████████████████████████"
            echo -e "${NC}"
            echo
            
            # Trap cleanup on exit
            trap cleanup EXIT
            
            check_dependencies
            prepare_build_environment
            customize_archiso_profile
            add_pyrite_files
            customize_live_environment
            build_iso
            test_iso
            
            print_success "Pyrite Linux ISO build completed!"
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi