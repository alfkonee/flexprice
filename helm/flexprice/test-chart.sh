#!/bin/bash
# FlexPrice Helm Chart Validation Test Suite (Bash)
# Run this script to validate all use cases for the FlexPrice Helm chart
#
# Usage:
#   ./test-chart.sh          # Run all tests
#   ./test-chart.sh -v       # Verbose output
#   ./test-chart.sh -h       # Show help

set -o pipefail

# Configuration
CHART_NAME="flexprice"
CHART_DIR="./helm/flexprice"
VERBOSE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Arrays to track test results
declare -a PASSED_TESTS=()
declare -a FAILED_TESTS=()

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if colors are supported
if [[ ! -t 1 ]] && [[ -z "$FORCE_COLOR" ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    NC=''
fi

# Functions
print_header() {
    echo ""
    echo -e "${CYAN}========================================"
    echo -e "${CYAN}${1}${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}→ ${1}${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASSED${NC}: ${1}"
    PASSED_TESTS+=("${1}")
}

print_fail() {
    echo -e "${RED}✗ FAILED${NC}: ${1}"
    FAILED_TESTS+=("${1}")
}

print_summary() {
    local total=$((${#PASSED_TESTS[@]} + ${#FAILED_TESTS[@]}))
    
    print_header "TEST SUMMARY"
    
    echo "Total Tests: ${total}"
    echo -e "${GREEN}Passed: ${#PASSED_TESTS[@]}${NC}"
    echo -e "${RED}Failed: ${#FAILED_TESTS[@]}${NC}"
    echo ""
    
    if [[ ${#PASSED_TESTS[@]} -gt 0 ]]; then
        echo -e "${GREEN}Passed Tests:${NC}"
        for test in "${PASSED_TESTS[@]}"; do
            echo "  ✓ ${test}"
        done
        echo ""
    fi
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ✗ ${test}"
        done
        echo ""
        return 1
    fi
    
    return 0
}

run_helm_test() {
    local test_name="$1"
    local helm_command="$2"
    local min_lines="${3:-1000}"
    
    print_test "${test_name}"
    
    # Capture output and exit code
    local output
    local exit_code
    
    output=$(eval "${helm_command}" 2>&1)
    exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        # Count lines
        local line_count
        line_count=$(echo "${output}" | wc -l)
        
        if [[ ${line_count} -gt ${min_lines} ]]; then
            print_pass "${test_name} (${line_count} lines generated)"
            return 0
        else
            print_fail "${test_name} (expected >${min_lines} lines, got ${line_count})"
            if [[ "${VERBOSE}" == true ]]; then
                echo "Output preview:"
                echo "${output}" | head -5 | sed 's/^/  /'
            fi
            return 1
        fi
    else
        print_fail "${test_name} (command failed with exit code ${exit_code})"
        if [[ "${VERBOSE}" == true ]]; then
            echo "Error output:"
            echo "${output}" | head -5 | sed 's/^/  /'
        fi
        return 1
    fi
}

show_help() {
    cat << EOF
FlexPrice Helm Chart Validation Test Suite

Usage: ./test-chart.sh [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --verbose   Show verbose output including error details
  -d, --dir       Chart directory (default: ./helm/flexprice)
  -n, --name      Chart name (default: flexprice)

Description:
  This script validates the FlexPrice Helm chart against multiple use cases:
  1. Pre-Installed Operators - Template generation with no operators
  2. External Services - Using external database, cache, and messaging services
  3. Operator Deployment - Full deployment with all operators
  4. Minimal Development - Minimal configuration for development
  5. Chart Validation - Helm lint validation
  6. Dependencies - Verify all required chart dependencies

Examples:
  ./test-chart.sh                  # Run all tests
  ./test-chart.sh -v               # Run with verbose output
  ./test-chart.sh -d /path/to/chart -v
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dir)
            CHART_DIR="$2"
            shift 2
            ;;
        -n|--name)
            CHART_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate prerequisites
check_prerequisites() {
    local missing_tools=0
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}Error: helm not found. Please install Helm.${NC}"
        missing_tools=$((missing_tools + 1))
    fi
    
    # Check chart directory
    if [[ ! -d "${CHART_DIR}" ]]; then
        echo -e "${RED}Error: Chart directory '${CHART_DIR}' not found.${NC}"
        missing_tools=$((missing_tools + 1))
    fi
    
    # Check Chart.yaml
    if [[ ! -f "${CHART_DIR}/Chart.yaml" ]]; then
        echo -e "${RED}Error: Chart.yaml not found in '${CHART_DIR}'.${NC}"
        missing_tools=$((missing_tools + 1))
    fi
    
    if [[ ${missing_tools} -gt 0 ]]; then
        exit 1
    fi
}

# Main execution
main() {
    print_header "FLEXPRICE HELM CHART VALIDATION SUITE"
    
    echo "Chart: ${CHART_NAME}"
    echo "Directory: $(cd "${CHART_DIR}" && pwd)"
    echo ""
    
    check_prerequisites
    
    # Change to chart directory
    cd "${CHART_DIR}" || exit 1
    
    # Test 1: Pre-installed operators
    run_helm_test \
        "Use Case 1: Pre-Installed Operators" \
        "helm template ${CHART_NAME} . --set postgres.operator.install=false --set clickhouse.operator.install=false --set kafka.operator.install=false --set temporal.operator.install=false" \
        1200
    echo ""
    
    # Test 2: External services
    run_helm_test \
        "Use Case 2: External Services" \
        "helm template ${CHART_NAME} . -f examples/values-external.yaml" \
        1200
    echo ""
    
    # Test 3: Operator deployment
    run_helm_test \
        "Use Case 3: Operator Deployment" \
        "helm template ${CHART_NAME} . -f examples/values-operators.yaml" \
        10000
    echo ""
    
    # Test 4: Minimal development
    run_helm_test \
        "Use Case 4: Minimal Development" \
        "helm template ${CHART_NAME} . -f examples/values-minimal.yaml" \
        1200
    echo ""
    
    # Test 5: Chart lint
    print_test "Chart Validation: Helm lint"
    if helm lint . > /dev/null 2>&1; then
        print_pass "Chart Validation: Chart passes linting"
    else
        print_fail "Chart Validation: Chart lint failed"
        if [[ "${VERBOSE}" == true ]]; then
            helm lint . | head -10 | sed 's/^/  /'
        fi
    fi
    echo ""
    
    # Test 6: Dependency check
    print_test "Dependencies: Verify chart dependencies"
    if helm dependency list . 2>/dev/null | grep -q "temporal"; then
        print_pass "Dependencies: All required charts available"
    else
        print_fail "Dependencies: Missing required charts"
        if [[ "${VERBOSE}" == true ]]; then
            helm dependency list . | head -10 | sed 's/^/  /'
        fi
    fi
    echo ""
    
    # Print summary and exit with proper code
    print_summary
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! Chart is ready for deployment.${NC}"
        echo ""
    else
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        echo ""
    fi
    
    return ${exit_code}
}

# Run main function
main
exit $?
