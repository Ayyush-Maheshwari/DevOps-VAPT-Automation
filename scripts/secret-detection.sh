#!/bin/bash

###############################################################################
# Secret and Credential Detection Scanner
# This script scans source code for exposed secrets, API keys, and credentials
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_PATH="${1:-.}"
REPORT_DIR="./security-reports/secrets"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Print header
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Secret Detection Scanner${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

#check if gitleaks is installed
check_gitleaks() {
    if command -v gitleaks &> /dev/null; then
        return 0
    else
        echo -e "${YELLOW}GitLeaks not installed${NC}"
        echo "Install from: https://github.com/gitleaks/gitleaks"
        return 1
    fi
}

#run gitleaks scan
run_gitleaks() {
    echo -e "${BLUE}Running GitLeaks scan...${NC}"
    
    if check_gitleaks; then
        gitleaks detect \
            --source="$SOURCE_PATH" \
            --report-path="${REPORT_DIR}/gitleaks-${TIMESTAMP}.json" \
            --report-format=json \
            --verbose 2>&1 | tee "${REPORT_DIR}/gitleaks-${TIMESTAMP}.log"
        
        GITLEAKS_EXIT=$?
        
        if [ $GITLEAKS_EXIT -eq 0 ]; then
            echo -e "${GREEN}No secrets detected by GitLeaks${NC}"
        else
            echo -e "${RED}Secrets detected by GitLeaks!${NC}"
        fi
        
        return $GITLEAKS_EXIT
    else
        return 1
    fi
}

#run custom secret patterns scan
run_custom_scan() {
    echo -e "${BLUE}Running custom secret pattern scan...${NC}"
    
    local findings_file="${REPORT_DIR}/custom-scan-${TIMESTAMP}.txt"
    
    echo "Secret Detection Report" > "$findings_file"
    echo "Scan Date: $(date)" >> "$findings_file"
    echo "Source: ${SOURCE_PATH}" >> "$findings_file"
    echo "=================================" >> "$findings_file"
    echo "" >> "$findings_file"
    
    SECRETS_FOUND=0
    
    # AWS Access Keys
    echo "=== AWS Access Keys ===" >> "$findings_file"
    if grep -r -E -n "AKIA[0-9A-Z]{16}" "$SOURCE_PATH" 2>/dev/null >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + $(grep -r -E "AKIA[0-9A-Z]{16}" "$SOURCE_PATH" 2>/dev/null | wc -l)))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # Generic API Keys
    echo "=== Potential API Keys ===" >> "$findings_file"
    if grep -r -E -i -n "(api[_-]?key|apikey|api[_-]?secret)['\"\s]*[:=]['\"\s]*[a-zA-Z0-9]{20,}" "$SOURCE_PATH" 2>/dev/null | head -30 >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # Private Keys
    echo "=== Private Keys ===" >> "$findings_file"
    if grep -r -E -n "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY" "$SOURCE_PATH" 2>/dev/null >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + $(grep -r -E "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY" "$SOURCE_PATH" 2>/dev/null | wc -l)))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # GitHub Tokens
    echo "=== GitHub Personal Access Tokens ===" >> "$findings_file"
    if grep -r -E -n "ghp_[a-zA-Z0-9]{36}" "$SOURCE_PATH" 2>/dev/null >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + $(grep -r -E "ghp_[a-zA-Z0-9]{36}" "$SOURCE_PATH" 2>/dev/null | wc -l)))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # Slack Tokens
    echo "=== Slack Tokens ===" >> "$findings_file"
    if grep -r -E -n "xox[baprs]-[0-9a-zA-Z-]+" "$SOURCE_PATH" 2>/dev/null >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + $(grep -r -E "xox[baprs]-[0-9a-zA-Z-]+" "$SOURCE_PATH" 2>/dev/null | wc -l)))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # Passwords in config files
    echo "=== Hardcoded Passwords ===" >> "$findings_file"
    if grep -r -E -i -n "(password|passwd|pwd)['\"\s]*[:=]['\"\s]*[^'\"\s]{3,}" "$SOURCE_PATH" 2>/dev/null | grep -v "password.*=" | head -30 >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # Database connection strings
    echo "=== Database Connection Strings ===" >> "$findings_file"
    if grep -r -E -i -n "(mongodb|mysql|postgresql|jdbc):\/\/[^'\"\s]+" "$SOURCE_PATH" 2>/dev/null | head -20 >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    # JWT Tokens
    echo "=== JWT Tokens ===" >> "$findings_file"
    if grep -r -E -n "eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+" "$SOURCE_PATH" 2>/dev/null | head -20 >> "$findings_file"; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    else
        echo "None found" >> "$findings_file"
    fi
    echo "" >> "$findings_file"
    
    echo "=== Summary ===" >> "$findings_file"
    echo "Total potential secrets found: ${SECRETS_FOUND}" >> "$findings_file"
    echo "" >> "$findings_file"
    
    cat "$findings_file"
    echo -e "${GREEN}Custom scan completed${NC}"
    echo ""
    
    return 0
}

#check common secret locations
check_common_locations() {
    echo -e "${BLUE}Checking common secret locations...${NC}"
    
    local locations_file="${REPORT_DIR}/locations-check-${TIMESTAMP}.txt"
    
    echo "Common Secret Locations Check" > "$locations_file"
    echo "==============================" >> "$locations_file"
    echo "" >> "$locations_file"
    
    # Check for .env files
    echo "Checking for .env files..." >> "$locations_file"
    find "$SOURCE_PATH" -name ".env*" -type f 2>/dev/null >> "$locations_file" || echo "None found" >> "$locations_file"
    echo "" >> "$locations_file"
    
    # Check for config files
    echo "Checking for config files with potential secrets..." >> "$locations_file"
    find "$SOURCE_PATH" -name "*config*.yml" -o -name "*config*.yaml" -o -name "*config*.json" 2>/dev/null | head -20 >> "$locations_file" || echo "None found" >> "$locations_file"
    echo "" >> "$locations_file"
    
    # Check for credentials files
    echo "Checking for credential files..." >> "$locations_file"
    find "$SOURCE_PATH" -name "*credentials*" -o -name "*secret*" -type f 2>/dev/null | head -20 >> "$locations_file" || echo "None found" >> "$locations_file"
    echo "" >> "$locations_file"
    
    # Check for key files
    echo "Checking for private key files..." >> "$locations_file"
    find "$SOURCE_PATH" -name "*.pem" -o -name "*.key" -o -name "id_rsa" 2>/dev/null | head -20 >> "$locations_file" || echo "None found" >> "$locations_file"
    echo "" >> "$locations_file"
    
    echo -e "${GREEN}Location check completed${NC}"
}

#generate summary
generate_summary() {
    echo ""
    echo -e "${BLUE}===========================${NC}"
    echo -e "${BLUE}Secret Detection Summary${NC}"
    echo -e "${BLUE}===========================${NC}"
    
    if [ $SECRETS_FOUND -gt 0 ]; then
        echo -e "${RED}⚠ Potential secrets detected: ${SECRETS_FOUND}${NC}"
        echo ""
        echo -e "${YELLOW}Types of secrets found:${NC}"
        echo "  • API keys and tokens"
        echo "  • Hardcoded passwords"
        echo "  • Database connection strings"
        echo "  • Private keys"
        echo "  • Authentication tokens"
    else
        echo -e "${GREEN}✓ No obvious secrets detected${NC}"
    fi
    
    echo ""
}

# Function to provide remediation guidance
provide_remediation() {
    echo -e "${BLUE}===========================${NC}"
    echo -e "${BLUE}Remediation Guidance${NC}"
    echo -e "${BLUE}===========================${NC}"
    echo ""
    echo "If secrets were found:"
    echo ""
    echo "1. IMMEDIATE ACTIONS:"
    echo "   • Revoke/rotate all exposed credentials immediately"
    echo "   • Remove secrets from code and commit history"
    echo "   • Use 'git filter-branch' or 'BFG Repo-Cleaner' to clean history"
    echo ""
    echo "2. SECURE ALTERNATIVES:"
    echo "   • Use environment variables for secrets"
    echo "   • Implement secret management solutions (HashiCorp Vault, AWS Secrets Manager)"
    echo "   • Use CI/CD secret management features"
    echo ""
    echo "3. PREVENTION:"
    echo "   • Add .env files to .gitignore"
    echo "   • Use pre-commit hooks for secret detection"
    echo "   • Implement code review processes"
    echo "   • Regular security training"
    echo ""
    echo "4. MONITORING:"
    echo "   • Enable audit logging"
    echo "   • Monitor for unusual access patterns"
    echo "   • Set up alerts for secret exposure"
    echo ""
}

#create final report
create_final_report() {
    local report_file="${REPORT_DIR}/final-report-${TIMESTAMP}.txt"
    
    cat > "$report_file" << EOF
=====================================
Secret Detection Final Report
=====================================

Scan Date: $(date)
Source Path: ${SOURCE_PATH}

Scan Results:
  Potential Secrets Found: ${SECRETS_FOUND}
  
Status: ${SCAN_STATUS}

Tools Used:
  • GitLeaks (if available)
  • Custom regex patterns
  • File location analysis

Reports Location: ${REPORT_DIR}
  • Custom scan: custom-scan-${TIMESTAMP}.txt
  • Location check: locations-check-${TIMESTAMP}.txt
  • GitLeaks report: gitleaks-${TIMESTAMP}.json (if available)

CRITICAL FINDINGS:
$(if [ $SECRETS_FOUND -gt 0 ]; then
    echo "  ⚠ Secrets detected in source code"
    echo "  ⚠ Immediate action required"
    echo "  ⚠ Review all findings and rotate credentials"
else
    echo "  ✓ No obvious secrets detected"
fi)

RECOMMENDATIONS:
  1. Review all flagged files
  2. Rotate any exposed credentials
  3. Implement secret management
  4. Add pre-commit hooks
  5. Regular security audits

For detailed findings, review individual report files in ${REPORT_DIR}

EOF

    echo ""
    echo -e "${GREEN}Final report saved to: ${report_file}${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}Scanning path: ${SOURCE_PATH}${NC}"
    echo ""
    
    # Run GitLeaks if available
    GITLEAKS_AVAILABLE=0
    if run_gitleaks; then
        GITLEAKS_AVAILABLE=1
        echo -e "${GREEN}GitLeaks scan completed${NC}"
    else
        echo -e "${YELLOW}Continuing with custom scans...${NC}"
    fi
    echo ""
    
    # Run custom pattern matching
    run_custom_scan
    
    # Check common locations
    check_common_locations
    
    # Generate summary
    generate_summary
    
    # Provide remediation guidance
    provide_remediation
    
    # Determine final status
    if [ $SECRETS_FOUND -gt 0 ]; then
        SCAN_STATUS="FAILED"
        echo -e "${RED}✗ Secret detection scan FAILED${NC}"
        echo -e "${RED}Secrets were found in the codebase!${NC}"
    else
        SCAN_STATUS="PASSED"
        echo -e "${GREEN}✓ Secret detection scan PASSED${NC}"
    fi
    
    # Create final report
    create_final_report
    
    # Return appropriate exit code
    if [ "$SCAN_STATUS" = "FAILED" ]; then
        exit 1
    else
        exit 0
    fi
}

main
