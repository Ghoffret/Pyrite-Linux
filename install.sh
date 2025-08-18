#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux Main Installer                         #
#                                                                           #
#     Enhanced installer with hardware detection and package selection     #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script and version info
readonly SCRIPT_VERSION="2.0.0"
readonly PYRITE_VERSION="2.0.0"

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

show_header() {
    clear
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██                    Pyrite Linux Installer                 ██"
    echo "██                      Version $PYRITE_VERSION                      ██"
    echo "██                                                            ██"
    echo "██        Enhanced Arch-based Distribution with Btrfs        ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

check_installer_components() {
    print_info "Checking installer components..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local required_scripts=(
        "installer/hardware-detect.sh"
        "installer/package-selector.sh" 
        "installer/pyrite-install.sh"
        "installer/post-install-validation.sh"
    )
    
    local missing_components=()
    
    for script in "${required_scripts[@]}"; do
        local script_path="$script_dir/$script"
        if [[ ! -f "$script_path" ]]; then
            missing_components+=("$script")
        fi
    done
    
    if [[ ${#missing_components[@]} -gt 0 ]]; then
        print_error "Missing installer components:"
        printf ' • %s\n' "${missing_components[@]}"
        print_info "Falling back to basic installation..."
        return 1
    fi
    
    print_success "All installer components found"
    return 0
}

run_hardware_detection() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local hardware_script="$script_dir/installer/hardware-detect.sh"
    
    print_info "Running hardware detection..."
    
    if [[ -f "$hardware_script" ]]; then
        if "$hardware_script"; then
            print_success "Hardware detection completed"
            return 0
        else
            print_warning "Hardware detection failed, continuing with installation"
            return 1
        fi
    else
        print_warning "Hardware detection script not found"
        return 1
    fi
}

run_package_selection() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local package_script="$script_dir/installer/package-selector.sh"
    
    print_info "Running package selection..."
    
    if [[ -f "$package_script" ]]; then
        if "$package_script"; then
            print_success "Package selection completed"
            return 0
        else
            print_warning "Package selection cancelled or failed"
            return 1
        fi
    else
        print_warning "Package selection script not found"
        return 1
    fi
}

run_main_installation() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_script="$script_dir/installer/pyrite-install.sh"
    
    print_info "Starting main installation process..."
    
    if [[ -f "$install_script" ]]; then
        if "$install_script"; then
            print_success "Main installation completed"
            return 0
        else
            print_error "Main installation failed"
            return 1
        fi
    else
        print_error "Main installation script not found"
        return 1
    fi
}

run_post_install_validation() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local validation_script="$script_dir/installer/post-install-validation.sh"
    
    print_info "Running post-installation validation..."
    
    if [[ -f "$validation_script" ]]; then
        if "$validation_script"; then
            print_success "Post-installation validation completed"
            return 0
        else
            print_warning "Post-installation validation had issues"
            return 1
        fi
    else
        print_warning "Post-installation validation script not found"
        return 1
    fi
}

show_installation_mode_menu() {
    echo "Installation Mode Selection:"
    echo "=========================="
    echo
    echo "1) Express Installation   - Quick install with minimal profile"
    echo "2) Standard Installation  - Hardware detection + package selection"
    echo "3) Advanced Installation  - Full customization with all options"
    echo "4) Expert Mode           - Run individual components manually"
    echo "5) Exit"
    echo
}

express_installation() {
    print_info "Starting Express Installation..."
    print_warning "This will install Pyrite Linux with minimal packages"
    echo
    
    if confirm "Proceed with express installation?"; then
        # Create minimal package selection
        echo "minimal" > /tmp/pyrite-profiles.txt
        echo "false" > /tmp/pyrite-aur.txt
        echo "false" > /tmp/pyrite-flatpak.txt
        
        run_main_installation
        run_post_install_validation
    else
        print_info "Express installation cancelled"
    fi
}

standard_installation() {
    print_info "Starting Standard Installation..."
    echo
    
    # Run hardware detection
    if run_hardware_detection; then
        echo
        read -r -p "Press Enter to continue to package selection..."
    fi
    
    # Run package selection
    if run_package_selection; then
        echo
        if confirm "Proceed with installation using selected packages?"; then
            run_main_installation
            run_post_install_validation
        fi
    else
        print_error "Package selection is required for standard installation"
        return 1
    fi
}

advanced_installation() {
    print_info "Starting Advanced Installation..."
    echo
    
    # Hardware detection
    if confirm "Run hardware detection first?" "y"; then
        run_hardware_detection
        echo
        read -r -p "Press Enter to continue..."
    fi
    
    # Package selection
    print_info "Package selection is required for advanced installation"
    if run_package_selection; then
        echo
    else
        print_error "Package selection cancelled"
        return 1
    fi
    
    # Additional options
    echo "Additional Installation Options:"
    echo "==============================="
    
    # Custom partitioning option
    if confirm "Use custom partitioning?"; then
        export PYRITE_CUSTOM_PARTITIONING=true
        print_info "Custom partitioning enabled"
    fi
    
    # Encryption option
    if confirm "Enable full disk encryption?"; then
        export PYRITE_ENCRYPTION=true
        print_info "Disk encryption enabled"
    fi
    
    # Performance tuning
    if confirm "Enable performance optimizations?"; then
        export PYRITE_PERFORMANCE_TUNING=true
        print_info "Performance tuning enabled"
    fi
    
    echo
    if confirm "Proceed with advanced installation?"; then
        run_main_installation
        run_post_install_validation
    fi
}

expert_mode() {
    while true; do
        echo -e "${BLUE}"
        echo "Expert Mode - Manual Component Execution"
        echo "========================================"
        echo -e "${NC}"
        echo
        echo "1) Run hardware detection"
        echo "2) Run package selection" 
        echo "3) Run main installation"
        echo "4) Run post-install validation"
        echo "5) View system logs"
        echo "6) Return to main menu"
        echo
        
        read -r -p "Select option [1-6]: " choice
        
        case "$choice" in
            1)
                run_hardware_detection
                ;;
            2)
                run_package_selection
                ;;
            3)
                run_main_installation
                ;;
            4)
                run_post_install_validation
                ;;
            5)
                print_info "Recent installation logs:"
                if [[ -f /tmp/pyrite-install.log ]]; then
                    tail -50 /tmp/pyrite-install.log
                else
                    print_warning "No installation log found"
                fi
                ;;
            6)
                return 0
                ;;
            *)
                print_warning "Invalid selection"
                ;;
        esac
        
        echo
        read -r -p "Press Enter to continue..."
        clear
    done
}

show_help() {
    echo "Pyrite Linux Enhanced Installer"
    echo
    echo "Usage: install.sh [OPTION]"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -e, --express     Express installation (minimal)"
    echo "  -s, --standard    Standard installation (recommended)"
    echo "  -a, --advanced    Advanced installation (full options)"
    echo "  -x, --expert      Expert mode (manual components)"
    echo "  --detect-only     Run hardware detection only"
    echo "  --packages-only   Run package selection only"
    echo "  --install-only    Run main installation only"
    echo "  --validate-only   Run validation only"
    echo
    echo "Examples:"
    echo "  ./install.sh                  # Interactive mode"
    echo "  ./install.sh --standard       # Standard installation"
    echo "  ./install.sh --detect-only    # Hardware detection only"
}

main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--express)
            show_header
            express_installation
            exit $?
            ;;
        -s|--standard)
            show_header
            standard_installation
            exit $?
            ;;
        -a|--advanced)
            show_header
            advanced_installation
            exit $?
            ;;
        -x|--expert)
            show_header
            expert_mode
            exit $?
            ;;
        --detect-only)
            show_header
            run_hardware_detection
            exit $?
            ;;
        --packages-only)
            show_header
            run_package_selection
            exit $?
            ;;
        --install-only)
            show_header
            run_main_installation
            exit $?
            ;;
        --validate-only)
            run_post_install_validation
            exit $?
            ;;
        "")
            # Interactive mode
            while true; do
                show_header
                
                # Check for enhanced components
                if ! check_installer_components; then
                    print_warning "Enhanced installer components not found"
                    print_info "Falling back to basic installation..."
                    echo
                    
                    if confirm "Run basic installation?"; then
                        # Try to find and run the basic installer
                        if [[ -f "installer/pyrite-install.sh" ]]; then
                            ./installer/pyrite-install.sh
                        elif [[ -f "pyrite-install.sh" ]]; then
                            ./pyrite-install.sh
                        else
                            print_error "No installation script found"
                            exit 1
                        fi
                    fi
                    exit $?
                fi
                
                show_installation_mode_menu
                read -r -p "Select installation mode [1-5]: " choice
                
                case "$choice" in
                    1)
                        clear
                        express_installation
                        break
                        ;;
                    2)
                        clear
                        standard_installation
                        break
                        ;;
                    3)
                        clear
                        advanced_installation
                        break
                        ;;
                    4)
                        clear
                        expert_mode
                        ;;
                    5)
                        print_info "Installation cancelled by user"
                        exit 0
                        ;;
                    *)
                        print_warning "Invalid selection"
                        sleep 1
                        ;;
                esac
            done
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