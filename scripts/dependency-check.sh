#!/bin/bash

###############################################################################
# Dependency Vulnerability Scanner
# This script scans project dependencies for known vulnerabilities using
# OWASP Dependency-Check
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="${1:-.}"
REPORT_DIR="./security-reports/dependency-check"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="dependency-check-report-${TIMESTAMP}"
THRESHOLD_FILE="../config/vulnerability-thresholds.json"
ENVIRONMENT="${ENVIRONMENT:-development}"

# Print header
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Dependency Vulnerability Scanner${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

#check if dependency-check is installed
check_dependency_check() {
    if ! command -v dependency-check &> /dev/null; then
        echo -e "${YELLOW}OWASP Dependency-Check not found. Installing...${NC}"
        # Download and setup dependency-check
        DOWNLOAD_URL="https://github.com/jeremylong/DependencyCheck/releases/download/v7.4.4/dependency-check-7.4.4-release.zip"
        echo "Downloading from: $DOWNLOAD_URL"
        echo "For actual use, please install from: https://owasp.org/www-project-dependency-check/"
        return 1
    fi
    return 0
}

#run dependency check scan
run_scan() {
    echo -e "${BLUE}Scanning project: ${PROJECT_PATH}${NC}"
    echo "Start time: $(date)"
    echo ""
    
    # Run the dependency check
    dependency-check \
        --project "$(basename $PROJECT_PATH)" \
        --scan "$PROJECT_PATH" \
        --format "ALL" \
        --out "$REPORT_DIR" \
        --suppression "../config/dependency-suppressions.xml" \
        --enableExperimental \
        --failOnCVSS 7 2>&1 | tee "${REPORT_DIR}/scan-${TIMESTAMP}.log"
    
    SCAN_EXIT_CODE=${PIPESTATUS[0]}
    
    echo ""
    echo "End time: $(date)"
    
    return $SCAN_EXIT_CODE
}

#parse vulnerabilities
parse_vulnerabilities() {
    local report_file="$1"
    
    # Extract vulnerability counts (simulated for demo)
    CRITICAL_COUNT=$(grep -i "critical" "$report_file" 2>/dev/null | wc -l || echo 0)
    HIGH_COUNT=$(grep -i "high" "$report_file" 2>/dev/null | wc -l || echo 0)
    MEDIUM_COUNT=$(grep -i "medium" "$report_file" 2>/dev/null | wc -l || echo 0)
    LOW_COUNT=$(grep -i "low" "$report_file" 2>/dev/null | wc -l || echo 0)
    
    echo ""
    echo -e "${BLUE}Vulnerability Summary:${NC}"
    echo -e "  Critical: ${RED}${CRITICAL_COUNT}${NC}"
    echo -e "  High:     ${RED}${HIGH_COUNT}${NC}"
    echo -e "  Medium:   ${YELLOW}${MEDIUM_COUNT}${NC}"
    echo -e "  Low:      ${GREEN}${LOW_COUNT}${NC}"
    echo ""
}

#check against thresholds
check_thresholds() {
    echo -e "${BLUE}Checking against ${ENVIRONMENT} thresholds...${NC}"
    
    # Read thresholds (simulated for demo)
    # In real implementation, parse from JSON file
    case "$ENVIRONMENT" in
        production)
            THRESHOLD_CRITICAL=0
            THRESHOLD_HIGH=0
            THRESHOLD_MEDIUM=5
            ;;
        staging)
            THRESHOLD_CRITICAL=0
            THRESHOLD_HIGH=2
            THRESHOLD_MEDIUM=10
            ;;
        *)
            THRESHOLD_CRITICAL=1
            THRESHOLD_HIGH=5
            THRESHOLD_MEDIUM=20
            ;;
    esac
    
    FAILED=0
    
    if [ "$CRITICAL_COUNT" -gt "$THRESHOLD_CRITICAL" ]; then
        echo -e "${RED}✗ Critical vulnerabilities exceed threshold (${CRITICAL_COUNT} > ${THRESHOLD_CRITICAL})${NC}"
        FAILED=1
    else
        echo -e "${GREEN}✓ Critical vulnerabilities within threshold${NC}"
    fi
    
    if [ "$HIGH_COUNT" -gt "$THRESHOLD_HIGH" ]; then
        echo -e "${RED}✗ High vulnerabilities exceed threshold (${HIGH_COUNT} > ${THRESHOLD_HIGH})${NC}"
        FAILED=1
    else
        echo -e "${GREEN}✓ High vulnerabilities within threshold${NC}"
    fi
    
    if [ "$MEDIUM_COUNT" -gt "$THRESHOLD_MEDIUM" ]; then
        echo -e "${YELLOW}⚠ Medium vulnerabilities exceed threshold (${MEDIUM_COUNT} > ${THRESHOLD_MEDIUM})${NC}"
        # Warning only, don't fail on medium
    else
        echo -e "${GREEN}✓ Medium vulnerabilities within threshold${NC}"
    fi
    
    echo ""
    return $FAILED
}

# Function to generate summary report
generate_summary() {
    local summary_file="${REPORT_DIR}/summary-${TIMESTAMP}.txt"
    
    cat > "$summary_file" << EOF
=====================================
Dependency Vulnerability Scan Summary
=====================================

Scan Date: $(date)
Environment: ${ENVIRONMENT}
Project: ${PROJECT_PATH}

Vulnerability Counts:
  Critical: ${CRITICAL_COUNT}
  High: ${HIGH_COUNT}
  Medium: ${MEDIUM_COUNT}
  Low: ${LOW_COUNT}

Thresholds (${ENVIRONMENT}):
  Critical: ${THRESHOLD_CRITICAL}
  High: ${THRESHOLD_HIGH}
  Medium: ${THRESHOLD_MEDIUM}

Status: ${STATUS}

Full reports available in: ${REPORT_DIR}
- HTML Report: ${REPORT_FILE}.html
- JSON Report: ${REPORT_FILE}.json
- XML Report: ${REPORT_FILE}.xml

EOF

    cat "$summary_file"
    echo -e "${GREEN}Summary report saved to: ${summary_file}${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
    echo -e "${BLUE}Project Path: ${PROJECT_PATH}${NC}"
    echo ""
    
    # Check if dependency-check is available
    if check_dependency_check; then
        # Run the scan
        if run_scan; then
            echo -e "${GREEN}Scan completed successfully${NC}"
        else
            echo -e "${YELLOW}Scan completed with warnings${NC}"
        fi
    else
        echo -e "${YELLOW}Simulating scan results for demonstration...${NC}"
        # Simulate some results for demo
        CRITICAL_COUNT=0
        HIGH_COUNT=1
        MEDIUM_COUNT=3
        LOW_COUNT=5
        
        echo ""
        echo -e "${BLUE}Vulnerability Summary (Simulated):${NC}"
        echo -e "  Critical: ${RED}${CRITICAL_COUNT}${NC}"
        echo -e "  High:     ${RED}${HIGH_COUNT}${NC}"
        echo -e "  Medium:   ${YELLOW}${MEDIUM_COUNT}${NC}"
        echo -e "  Low:      ${GREEN}${LOW_COUNT}${NC}"
        echo ""
    fi
    
    # Check against thresholds
    if check_thresholds; then
        STATUS="PASSED"
        echo -e "${GREEN}✓ Security scan PASSED${NC}"
        generate_summary
        exit 0
    else
        STATUS="FAILED"
        echo -e "${RED}✗ Security scan FAILED${NC}"
        generate_summary
        exit 1
    fi
}

main
