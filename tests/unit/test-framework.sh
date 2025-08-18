#!/bin/bash

#############################################################################
#                                                                           #
#                     Pyrite Linux Test Framework                          #
#                                                                           #
#     Basic testing framework for installer and tools                      #
#                                                                           #
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((TESTS_PASSED++))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((TESTS_SKIPPED++))
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((TESTS_FAILED++))
}

test_script_syntax() {
    local script="$1"
    print_info "Testing syntax: $script"
    
    if bash -n "$script"; then
        print_success "Syntax check passed: $script"
    else
        print_error "Syntax check failed: $script"
    fi
}

test_script_executable() {
    local script="$1"
    print_info "Testing executable: $script"
    
    if [[ -x "$script" ]]; then
        print_success "Executable check passed: $script"
    else
        print_error "Executable check failed: $script"
    fi
}

test_help_option() {
    local script="$1"
    print_info "Testing help option: $script"
    
    if "$script" --help &>/dev/null; then
        print_success "Help option works: $script"
    else
        print_error "Help option failed: $script"
    fi
}

test_package_lists() {
    print_info "Testing package list files..."
    
    local package_dir="../packages"
    local required_files=("minimal.txt" "development.txt" "server.txt" "desktop.txt")
    
    for file in "${required_files[@]}"; do
        local path="$package_dir/$file"
        if [[ -f "$path" ]]; then
            # Check if file has content
            if [[ -s "$path" ]]; then
                print_success "Package list exists and has content: $file"
            else
                print_error "Package list is empty: $file"
            fi
        else
            print_error "Package list missing: $file"
        fi
    done
}

test_directory_structure() {
    print_info "Testing directory structure..."
    
    local required_dirs=(
        "../../installer" "../../packages" "../../tools" "../../configs"
        "../../docs" "../../tests" "../../build" "../../examples"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Directory exists: $dir"
        else
            print_error "Directory missing: $dir"
        fi
    done
}

test_installer_scripts() {
    print_info "Testing installer scripts..."
    
    local installer_dir="../installer"
    local scripts=(
        "pyrite-install.sh"
        "hardware-detect.sh"
        "package-selector.sh"
        "post-install-validation.sh"
    )
    
    for script in "${scripts[@]}"; do
        local path="$installer_dir/$script"
        if [[ -f "$path" ]]; then
            test_script_syntax "$path"
            test_script_executable "$path"
            test_help_option "$path"
        else
            print_error "Installer script missing: $script"
        fi
    done
}

test_system_tools() {
    print_info "Testing system tools..."
    
    local tools_dir="../tools"
    local tools=(
        "pyrite-update"
        "pyrite-config"
        "pyrite-service"
        "pyrite-logs"
        "pyrite-backup"
        "pyrite-recovery"
    )
    
    for tool in "${tools[@]}"; do
        local path="$tools_dir/$tool"
        if [[ -f "$path" ]]; then
            test_script_syntax "$path"
            test_script_executable "$path"
            test_help_option "$path"
        else
            print_error "System tool missing: $tool"
        fi
    done
}

test_documentation() {
    print_info "Testing documentation..."
    
    local doc_files=(
        "../docs/installation/README.md"
        "../docs/user-guides/getting-started.md"
        "../README.md"
        "../INSTALL.md"
    )
    
    for doc in "${doc_files[@]}"; do
        if [[ -f "$doc" ]]; then
            if [[ -s "$doc" ]]; then
                print_success "Documentation exists and has content: $(basename "$doc")"
            else
                print_error "Documentation is empty: $(basename "$doc")"
            fi
        else
            print_error "Documentation missing: $(basename "$doc")"
        fi
    done
}

test_configuration_templates() {
    print_info "Testing configuration structure..."
    
    local config_dirs=(
        "../configs/templates"
        "../configs/hardware"
        "../configs/services"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Configuration directory exists: $(basename "$dir")"
        else
            print_warning "Configuration directory missing: $(basename "$dir")"
        fi
    done
}

test_example_configs() {
    print_info "Testing example configurations..."
    
    local example_dirs=(
        "../examples/server-configs"
        "../examples/desktop-configs"
        "../examples/development-configs"
    )
    
    for dir in "${example_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Example directory exists: $(basename "$dir")"
        else
            print_warning "Example directory missing: $(basename "$dir")"
        fi
    done
}

run_basic_functionality_tests() {
    print_info "Running basic functionality tests..."
    
    # Test package list parsing
    if command -v python3 &>/dev/null; then
        print_info "Testing package list parsing..."
        python3 -c "
import os
package_dir = '../../packages'
for file in ['minimal.txt', 'development.txt', 'server.txt', 'desktop.txt']:
    path = os.path.join(package_dir, file)
    if os.path.exists(path):
        with open(path, 'r') as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith('#')]
            if lines:
                print(f'Package list {file}: {len(lines)} packages')
            else:
                raise Exception(f'No packages found in {file}')
    else:
        raise Exception(f'Package list {file} not found')
print('Package list parsing test passed')
" && print_success "Package list parsing test passed" || print_error "Package list parsing test failed"
    else
        print_warning "Python3 not available, skipping package list parsing test"
    fi
}

generate_test_report() {
    echo
    print_info "Test Results Summary:"
    echo "===================="
    echo
    echo -e "${GREEN}Tests Passed:${NC} $TESTS_PASSED"
    echo -e "${YELLOW}Tests Skipped:${NC} $TESTS_SKIPPED" 
    echo -e "${RED}Tests Failed:${NC} $TESTS_FAILED"
    echo
    
    local total=$((TESTS_PASSED + TESTS_SKIPPED + TESTS_FAILED))
    if [[ $total -gt 0 ]]; then
        local success_rate=$(( (TESTS_PASSED * 100) / total ))
        echo "Success Rate: ${success_rate}%"
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        if [[ $TESTS_SKIPPED -eq 0 ]]; then
            print_success "All tests passed!"
            return 0
        else
            print_warning "Tests completed with warnings"
            return 0
        fi
    else
        print_error "Some tests failed!"
        return 1
    fi
}

main() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██                Pyrite Linux Test Framework                 ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
    
    print_info "Starting Pyrite Linux test suite..."
    echo
    
    # Change to tests directory
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # Run test suites
    test_directory_structure
    test_package_lists
    test_installer_scripts
    test_system_tools
    test_documentation
    test_configuration_templates
    test_example_configs
    run_basic_functionality_tests
    
    echo
    generate_test_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi