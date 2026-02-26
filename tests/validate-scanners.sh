#!/bin/bash

###############################################################################
# Scanner Validation Script
# Tests all security scanners to ensure they're working correctly
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Security Scanner Validation${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name is installed"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is NOT installed"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to test script execution
test_script() {
    local script=$1
    local name=$2
    
    if [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} $name is executable"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is NOT executable"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo -e "${BLUE}Checking Required Tools:${NC}"
echo ""

# Check core tools
check_command "bash" "Bash"
check_command "git" "Git"
check_command "docker" "Docker"
check_command "python3" "Python 3"

echo ""
echo -e "${BLUE}Checking Security Scanning Tools:${NC}"
echo ""

# Check security tools
check_command "dependency-check" "OWASP Dependency-Check" || echo "  Install from: https://owasp.org/www-project-dependency-check/"
check_command "trivy" "Trivy" || echo "  Install from: https://aquasecurity.github.io/trivy/"
check_command "semgrep" "Semgrep" || echo "  Install: pip3 install semgrep"
check_command "bandit" "Bandit" || echo "  Install: pip3 install bandit"
check_command "gitleaks" "GitLeaks" || echo "  Install from: https://github.com/gitleaks/gitleaks"

echo ""
echo -e "${BLUE}Checking Scripts:${NC}"
echo ""

# Check scripts
test_script "../scripts/dependency-check.sh" "Dependency Check Script"
test_script "../scripts/container-scan.sh" "Container Scan Script"
test_script "../scripts/sast-scan.sh" "SAST Script"
test_script "../scripts/secret-detection.sh" "Secret Detection Script"
test_script "../scripts/report-generator.sh" "Report Generator Script"

echo ""
echo -e "${BLUE}Testing Script Execution:${NC}"
echo ""

# Test vulnerable app scan
if [ -f "test-vulnerable-app/app.py" ]; then
    echo -e "${YELLOW}Testing SAST on vulnerable application...${NC}"
    
    if ../scripts/sast-scan.sh test-vulnerable-app/ 2>&1 | grep -q "Issues Found\|vulnerabilities"; then
        echo -e "${GREEN}✓${NC} SAST detected vulnerabilities (expected)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} SAST did not detect vulnerabilities"
        ((TESTS_FAILED++))
    fi
    
    echo -e "${YELLOW}Testing secret detection on vulnerable application...${NC}"
    
    if ../scripts/secret-detection.sh test-vulnerable-app/ 2>&1 | grep -q "secrets\|credentials"; then
        echo -e "${GREEN}✓${NC} Secret detection found hardcoded secrets (expected)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Secret detection did not find secrets"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Test vulnerable application not found, skipping"
fi

echo ""
echo -e "${BLUE}Testing Report Generation:${NC}"
echo ""

# Test report generation
if ../scripts/report-generator.sh "Validation Test" > /dev/null 2>&1; then
    if [ -f "../security-reports/consolidated/security-summary-"*.txt ]; then
        echo -e "${GREEN}✓${NC} Report generation successful"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Report files not created"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Report generation failed"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validation tests passed!${NC}"
    echo -e "${GREEN}Your security scanning environment is ready.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validation tests failed.${NC}"
    echo -e "${YELLOW}Please install missing tools and fix issues before proceeding.${NC}"
    echo ""
    echo "Refer to the Setup Guide: docs/setup-guide.md"
    exit 1
fi
