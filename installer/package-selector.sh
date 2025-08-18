#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux Package Selector                       #
#                                                                           #
#     Interactive package selection for different use cases                #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Package list files
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(dirname "$SCRIPT_DIR")/packages"

# Global variables
SELECTED_PROFILES=()
SELECTED_PACKAGES=()
ENABLE_AUR=false
ENABLE_FLATPAK=false

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

show_package_profiles() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██              Pyrite Linux Package Selection                ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
    
    print_info "Available installation profiles:"
    echo
    echo "1) Minimal        - Core system only (basic CLI environment)"
    echo "2) Development    - Minimal + development tools and compilers"
    echo "3) Server         - Minimal + server applications and tools"
    echo "4) Desktop        - Minimal + basic desktop environment"
    echo "5) Custom         - Choose individual profiles to combine"
    echo
}

select_installation_profile() {
    show_package_profiles
    
    while true; do
        read -r -p "Select installation profile [1-5]: " choice
        
        case "$choice" in
            1)
                SELECTED_PROFILES=("minimal")
                print_success "Minimal profile selected"
                break
                ;;
            2)
                SELECTED_PROFILES=("minimal" "development")
                print_success "Development profile selected"
                break
                ;;
            3)
                SELECTED_PROFILES=("minimal" "server")
                print_success "Server profile selected"
                break
                ;;
            4)
                SELECTED_PROFILES=("minimal" "desktop")
                print_success "Desktop profile selected"
                break
                ;;
            5)
                select_custom_profiles
                break
                ;;
            *)
                print_warning "Invalid selection. Please choose 1-5."
                ;;
        esac
    done
}

select_custom_profiles() {
    print_info "Custom profile selection:"
    echo
    
    # Minimal is always included
    SELECTED_PROFILES=("minimal")
    print_info "✓ Minimal profile (always included)"
    
    # Ask about each additional profile
    if confirm "Include Development profile? (compilers, dev tools)"; then
        SELECTED_PROFILES+=("development")
        print_success "✓ Development profile added"
    fi
    
    if confirm "Include Server profile? (web servers, databases)"; then
        SELECTED_PROFILES+=("server")
        print_success "✓ Server profile added"
    fi
    
    if confirm "Include Desktop profile? (GUI environment)"; then
        SELECTED_PROFILES+=("desktop")
        print_success "✓ Desktop profile added"
    fi
}

configure_additional_options() {
    echo
    print_info "Additional software options:"
    echo
    
    if confirm "Enable AUR (Arch User Repository) support?"; then
        ENABLE_AUR=true
        print_success "AUR support will be enabled"
    fi
    
    if confirm "Enable Flatpak support?"; then
        ENABLE_FLATPAK=true
        print_success "Flatpak support will be enabled"
    fi
}

load_package_lists() {
    print_info "Loading package lists..."
    
    for profile in "${SELECTED_PROFILES[@]}"; do
        local package_file="$PACKAGES_DIR/${profile}.txt"
        
        if [[ -f "$package_file" ]]; then
            print_info "Loading packages from $profile profile..."
            
            # Read packages from file, ignoring comments and empty lines
            while IFS= read -r line; do
                # Skip comments and empty lines
                if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                    continue
                fi
                
                # Add package to list if not already present
                if [[ ! " ${SELECTED_PACKAGES[*]} " =~ " ${line} " ]]; then
                    SELECTED_PACKAGES+=("$line")
                fi
            done < "$package_file"
            
        else
            print_warning "Package file not found: $package_file"
        fi
    done
    
    # Add hardware-specific packages from hardware detection
    if [[ -f /tmp/pyrite-hardware.json ]]; then
        print_info "Adding hardware-specific packages..."
        
        # Extract recommended packages from hardware detection
        local hw_packages
        hw_packages=$(python3 -c "
import json
try:
    with open('/tmp/pyrite-hardware.json', 'r') as f:
        data = json.load(f)
    for pkg in data.get('recommended_packages', []):
        print(pkg)
except:
    pass
" 2>/dev/null || true)
        
        if [[ -n "$hw_packages" ]]; then
            while IFS= read -r package; do
                if [[ -n "$package" ]] && [[ ! " ${SELECTED_PACKAGES[*]} " =~ " ${package} " ]]; then
                    SELECTED_PACKAGES+=("$package")
                fi
            done <<< "$hw_packages"
        fi
    fi
    
    # Add AUR helper if enabled
    if [[ "$ENABLE_AUR" == true ]]; then
        # Note: yay will be installed separately via AUR after base system
        print_info "AUR helper (yay) will be installed after base system"
    fi
    
    # Add Flatpak if enabled
    if [[ "$ENABLE_FLATPAK" == true ]]; then
        if [[ ! " ${SELECTED_PACKAGES[*]} " =~ " flatpak " ]]; then
            SELECTED_PACKAGES+=("flatpak")
        fi
    fi
}

show_package_summary() {
    echo
    print_info "Installation Summary:"
    echo "===================="
    echo
    
    print_info "Selected profiles:"
    printf ' • %s\n' "${SELECTED_PROFILES[@]}"
    echo
    
    print_info "Additional options:"
    echo " • AUR support: $([ "$ENABLE_AUR" == true ] && echo "Enabled" || echo "Disabled")"
    echo " • Flatpak support: $([ "$ENABLE_FLATPAK" == true ] && echo "Enabled" || echo "Disabled")"
    echo
    
    print_info "Total packages to install: ${#SELECTED_PACKAGES[@]}"
    
    if confirm "Show detailed package list?"; then
        echo
        print_info "Packages to be installed:"
        printf ' • %s\n' "${SELECTED_PACKAGES[@]}" | sort
    fi
}

save_package_selection() {
    local output_file="${1:-/tmp/pyrite-packages.txt}"
    
    # Save packages one per line
    printf '%s\n' "${SELECTED_PACKAGES[@]}" | sort -u > "$output_file"
    
    # Save configuration
    cat > /tmp/pyrite-package-config.sh << EOF
#!/bin/bash
# Pyrite Linux Package Configuration
SELECTED_PROFILES=($(printf '"%s" ' "${SELECTED_PROFILES[@]}"))
ENABLE_AUR=$ENABLE_AUR
ENABLE_FLATPAK=$ENABLE_FLATPAK
TOTAL_PACKAGES=${#SELECTED_PACKAGES[@]}
EOF
    
    print_success "Package selection saved to $output_file"
    print_success "Configuration saved to /tmp/pyrite-package-config.sh"
}

estimate_installation_size() {
    print_info "Estimating installation size..."
    
    # Rough estimates based on package count and profiles
    local size_mb=500  # Base system size
    
    for profile in "${SELECTED_PROFILES[@]}"; do
        case "$profile" in
            "minimal")
                size_mb=$((size_mb + 200))
                ;;
            "development")
                size_mb=$((size_mb + 800))
                ;;
            "server")
                size_mb=$((size_mb + 600))
                ;;
            "desktop")
                size_mb=$((size_mb + 1200))
                ;;
        esac
    done
    
    if [[ "$ENABLE_FLATPAK" == true ]]; then
        size_mb=$((size_mb + 100))
    fi
    
    local size_gb=$((size_mb / 1024))
    print_info "Estimated installation size: ${size_gb}GB (${size_mb}MB)"
}

main() {
    # Check if package files exist
    if [[ ! -d "$PACKAGES_DIR" ]]; then
        print_error "Packages directory not found: $PACKAGES_DIR"
        exit 1
    fi
    
    select_installation_profile
    configure_additional_options
    load_package_lists
    estimate_installation_size
    show_package_summary
    
    echo
    if confirm "Proceed with this package selection?" "y"; then
        save_package_selection
        print_success "Package selection completed successfully!"
        echo
        print_info "Next steps:"
        echo " • Packages saved to /tmp/pyrite-packages.txt"
        echo " • Configuration saved to /tmp/pyrite-package-config.sh"
        echo " • Ready for system installation"
    else
        print_info "Package selection cancelled"
        exit 0
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi