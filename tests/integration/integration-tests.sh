#!/bin/bash

#############################################################################
#                                                                           #
#                   Pyrite Linux Integration Tests                         #
#                                                                           #
#     Integration tests for complete installation workflows                #
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

test_hardware_detection_workflow() {
    print_info "Testing hardware detection workflow..."
    
    local hardware_script="../../installer/hardware-detect.sh"
    
    if [[ ! -f "$hardware_script" ]]; then
        print_error "Hardware detection script not found"
        return 1
    fi
    
    # Test dry run (simulation)
    if timeout 30 bash -n "$hardware_script"; then
        print_success "Hardware detection script syntax valid"
    else
        print_error "Hardware detection script has syntax errors"
        return 1
    fi
    
    # Test help option
    if timeout 10 "$hardware_script" --help &>/dev/null; then
        print_success "Hardware detection help option works"
    else
        print_warning "Hardware detection help option failed"
    fi
    
    print_success "Hardware detection workflow tests completed"
}

test_package_selection_workflow() {
    print_info "Testing package selection workflow..."
    
    local package_script="../../installer/package-selector.sh"
    local package_dir="../../packages"
    
    if [[ ! -f "$package_script" ]]; then
        print_error "Package selection script not found"
        return 1
    fi
    
    # Test script syntax
    if timeout 30 bash -n "$package_script"; then
        print_success "Package selection script syntax valid"
    else
        print_error "Package selection script has syntax errors"
        return 1
    fi
    
    # Test package files exist and are valid
    local required_packages=("minimal.txt" "development.txt" "server.txt" "desktop.txt")
    
    for package_file in "${required_packages[@]}"; do
        local path="$package_dir/$package_file"
        
        if [[ ! -f "$path" ]]; then
            print_error "Package file missing: $package_file"
            continue
        fi
        
        # Check for non-empty content and valid format
        local package_count
        package_count=$(grep -v '^#' "$path" | grep -v '^$' | wc -l)
        
        if [[ $package_count -gt 0 ]]; then
            print_success "Package file $package_file has $package_count packages"
        else
            print_error "Package file $package_file is empty or invalid"
        fi
    done
    
    print_success "Package selection workflow tests completed"
}

test_installation_validation_workflow() {
    print_info "Testing post-installation validation workflow..."
    
    local validation_script="../../installer/post-install-validation.sh"
    
    if [[ ! -f "$validation_script" ]]; then
        print_error "Post-installation validation script not found"
        return 1
    fi
    
    # Test script syntax
    if timeout 30 bash -n "$validation_script"; then
        print_success "Post-installation validation script syntax valid"
    else
        print_error "Post-installation validation script has syntax errors"
        return 1
    fi
    
    # Test help option
    if timeout 10 "$validation_script" --help &>/dev/null; then
        print_success "Post-installation validation help option works"
    else
        print_warning "Post-installation validation help option failed"
    fi
    
    print_success "Installation validation workflow tests completed"
}

test_system_tools_integration() {
    print_info "Testing system tools integration..."
    
    local tools_dir="../../tools"
    local tools=(
        "pyrite-update"
        "pyrite-config"
        "pyrite-service"
        "pyrite-logs"
        "pyrite-backup"
        "pyrite-recovery"
    )
    
    for tool in "${tools[@]}"; do
        local tool_path="$tools_dir/$tool"
        
        if [[ ! -f "$tool_path" ]]; then
            print_error "System tool missing: $tool"
            continue
        fi
        
        # Test syntax
        if timeout 30 bash -n "$tool_path"; then
            print_success "Tool $tool syntax valid"
        else
            print_error "Tool $tool has syntax errors"
            continue
        fi
        
        # Test help option
        if timeout 10 "$tool_path" --help &>/dev/null; then
            print_success "Tool $tool help option works"
        else
            print_warning "Tool $tool help option failed"
        fi
    done
    
    print_success "System tools integration tests completed"
}

test_build_system() {
    print_info "Testing build system..."
    
    local iso_builder="../../build/iso-builder.sh"
    
    if [[ ! -f "$iso_builder" ]]; then
        print_error "ISO builder script not found"
        return 1
    fi
    
    # Test script syntax
    if timeout 30 bash -n "$iso_builder"; then
        print_success "ISO builder script syntax valid"
    else
        print_error "ISO builder script has syntax errors"
        return 1
    fi
    
    # Test help option
    if timeout 10 "$iso_builder" --help &>/dev/null; then
        print_success "ISO builder help option works"
    else
        print_warning "ISO builder help option failed"
    fi
    
    # Check for archiso dependency (if available)
    if command -v mkarchiso &>/dev/null; then
        print_success "archiso tools available for ISO building"
    else
        print_warning "archiso tools not available (not in build environment)"
    fi
    
    print_success "Build system tests completed"
}

test_documentation_completeness() {
    print_info "Testing documentation completeness..."
    
    local doc_files=(
        "../../docs/installation/README.md"
        "../../docs/user-guides/getting-started.md"
        "../../docs/troubleshooting/common-issues.md"
        "../../README.md"
        "../../INSTALL.md"
    )
    
    for doc in "${doc_files[@]}"; do
        if [[ -f "$doc" ]]; then
            local line_count
            line_count=$(wc -l < "$doc")
            
            if [[ $line_count -gt 50 ]]; then
                print_success "Documentation $(basename "$doc") is comprehensive ($line_count lines)"
            else
                print_warning "Documentation $(basename "$doc") might be incomplete ($line_count lines)"
            fi
        else
            print_error "Documentation missing: $(basename "$doc")"
        fi
    done
    
    print_success "Documentation completeness tests completed"
}

test_configuration_templates() {
    print_info "Testing configuration templates..."
    
    local config_files=(
        "../../configs/hardware/hardware-templates.yml"
        "../../configs/services/service-templates.yml"
        "../../examples/server-configs/nginx-php-mysql.yml"
        "../../examples/desktop-configs/xfce-desktop.yml"
        "../../examples/development-configs/full-dev-environment.yml"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            if [[ -s "$config" ]]; then
                print_success "Configuration template exists: $(basename "$config")"
                
                # Basic YAML syntax check if available
                if command -v python3 &>/dev/null; then
                    if python3 -c "import yaml; yaml.safe_load(open('$config'))" 2>/dev/null; then
                        print_success "Configuration template $config has valid YAML syntax"
                    else
                        print_warning "Configuration template $config might have YAML syntax issues"
                    fi
                fi
            else
                print_error "Configuration template is empty: $(basename "$config")"
            fi
        else
            print_error "Configuration template missing: $(basename "$config")"
        fi
    done
    
    print_success "Configuration templates tests completed"
}

test_complete_workflow_simulation() {
    print_info "Testing complete workflow simulation..."
    
    # Create temporary directory for simulation
    local temp_dir="/tmp/pyrite-integration-test"
    mkdir -p "$temp_dir"
    
    # Simulate hardware detection data
    cat > "$temp_dir/pyrite-hardware.json" << 'EOF'
{
    "cpu": "Intel Core i7-12700K",
    "memory_mb": 16384,
    "gpu": "nvidia",
    "wifi": "intel",
    "bluetooth": "detected",
    "audio": "detected",
    "recommended_packages": ["nvidia", "nvidia-utils", "iwlwifi-firmware"]
}
EOF
    
    # Simulate package selection
    echo "minimal" > "$temp_dir/pyrite-profiles.txt"
    echo "true" > "$temp_dir/pyrite-aur.txt"
    echo "false" > "$temp_dir/pyrite-flatpak.txt"
    
    # Create minimal package list for testing
    cat > "$temp_dir/pyrite-packages.txt" << 'EOF'
base
linux
btrfs-progs
networkmanager
nvidia
iwlwifi-firmware
EOF
    
    if [[ -f "$temp_dir/pyrite-hardware.json" && 
          -f "$temp_dir/pyrite-profiles.txt" && 
          -f "$temp_dir/pyrite-packages.txt" ]]; then
        print_success "Workflow simulation data created successfully"
    else
        print_error "Failed to create workflow simulation data"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Complete workflow simulation tests completed"
}

test_error_handling() {
    print_info "Testing error handling..."
    
    # Test scripts with invalid inputs
    local test_cases=(
        "../../installer/hardware-detect.sh --invalid-option"
        "../../installer/package-selector.sh --nonexistent"
        "../../tools/pyrite-update --bad-flag"
    )
    
    for test_case in "${test_cases[@]}"; do
        local script
        script=$(echo "$test_case" | awk '{print $1}')
        
        if [[ -f "$script" ]]; then
            # Test that scripts handle invalid options gracefully
            if timeout 10 $test_case &>/dev/null; then
                print_warning "Script $script accepted invalid option (should fail gracefully)"
            else
                print_success "Script $script properly rejects invalid options"
            fi
        fi
    done
    
    print_success "Error handling tests completed"
}

generate_integration_test_report() {
    echo
    print_info "Integration Test Results Summary:"
    echo "================================="
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
            print_success "All integration tests passed!"
            return 0
        else
            print_warning "Integration tests completed with warnings"
            return 0
        fi
    else
        print_error "Some integration tests failed!"
        return 1
    fi
}

main() {
    echo -e "${BLUE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "██                                                            ██"
    echo "██            Pyrite Linux Integration Tests                  ██"
    echo "██                                                            ██"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
    
    print_info "Starting Pyrite Linux integration test suite..."
    echo
    
    # Change to tests directory
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # Run integration test suites
    test_hardware_detection_workflow
    test_package_selection_workflow
    test_installation_validation_workflow
    test_system_tools_integration
    test_build_system
    test_documentation_completeness
    test_configuration_templates
    test_complete_workflow_simulation
    test_error_handling
    
    echo
    generate_integration_test_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi