# Security Scanner Tests

This directory contains test files and validation scripts for the DevOps VAPT Automation framework.

## Contents

### Test Vulnerable Application

`test-vulnerable-app/` - A sample Python application with intentional security vulnerabilities for testing purposes.

**Vulnerabilities included:**
- SQL Injection
- Cross-Site Scripting (XSS)
- Command Injection
- Path Traversal
- Hardcoded Credentials
- Weak Cryptography
- Insecure Deserialization
- Missing Authentication
- Debug Mode Enabled

**⚠️ WARNING**: This application is intentionally insecure. DO NOT deploy to production or expose to the internet!

### Validation Script

`validate-scanners.sh` - Automated validation script that checks:
- Required tools installation
- Script executability
- Scanner functionality
- Report generation

## Usage

### Run Validation Tests

```bash
cd tests
chmod +x validate-scanners.sh
./validate-scanners.sh
```

The script will:
1. Check if all required tools are installed
2. Verify scripts are executable
3. Test scanners on the vulnerable application
4. Validate report generation
5. Display a summary of test results

### Test Individual Scanners

#### Test SAST Scanner

```bash
cd devops-vapt-automation
./scripts/sast-scan.sh tests/test-vulnerable-app/
```

Expected: Should detect multiple high and critical vulnerabilities

#### Test Secret Detection

```bash
./scripts/secret-detection.sh tests/test-vulnerable-app/
```

Expected: Should detect hardcoded credentials and API keys

#### Test Dependency Check

```bash
# If the app has a requirements.txt
./scripts/dependency-check.sh tests/test-vulnerable-app/
```

## Expected Results

When running scanners on the vulnerable test application, you should see:

**SAST Analysis:**
- ✗ SQL Injection vulnerabilities
- ✗ XSS vulnerabilities  
- ✗ Command Injection risks
- ✗ Path Traversal issues
- ✗ Weak cryptography (MD5 usage)
- ✗ Insecure deserialization
- ✗ Debug mode enabled

**Secret Detection:**
- ✗ Hardcoded passwords
- ✗ API keys in code
- ✗ AWS access keys
- ✗ Database credentials

## Creating Custom Tests

### Add New Test Cases

1. Create a new test file in `test-vulnerable-app/`
2. Add intentional vulnerabilities
3. Document expected scanner results
4. Add to validation script if needed

### Test New Scanners

```bash
# Add to validate-scanners.sh
check_command "newscan" "New Scanner" || echo "  Install from: URL"

# Test functionality
if ../scripts/new-scanner.sh test-vulnerable-app/ 2>&1 | grep -q "expected-output"; then
    echo -e "${GREEN}✓${NC} New scanner working"
else
    echo -e "${RED}✗${NC} New scanner failed"
fi
```

## Best Practices

1. **Never deploy test applications** - They contain real vulnerabilities
2. **Keep tests updated** - Add new vulnerability patterns as they emerge
3. **Validate after changes** - Run validation after modifying scanners
4. **Document expectations** - Note what each test should detect
5. **Use in CI/CD** - Integrate validation into your pipeline

## Troubleshooting

### Scanners Not Detecting Vulnerabilities

**Issue**: Validation fails because vulnerabilities aren't detected

**Solutions:**
1. Check scanner is properly installed
2. Verify scanner configuration
3. Update security rules/databases
4. Check scanner logs for errors

### False Positives

**Issue**: Scanner reports issues that aren't real vulnerabilities

**Solutions:**
1. Review scanner configuration
2. Adjust sensitivity settings
3. Add suppressions for known false positives
4. Update scanner to latest version

### Performance Issues

**Issue**: Tests take too long to run

**Solutions:**
1. Reduce scope of test files
2. Use faster scanners for CI/CD
3. Run comprehensive tests nightly only
4. Cache scanner databases

## Additional Resources

- [Setup Guide](../docs/setup-guide.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

## Contributing

To add new test cases:

1. Create a test file with documented vulnerabilities
2. Add expected results documentation
3. Update validation script
4. Test thoroughly
5. Submit pull request

---

**Remember**: These are intentionally vulnerable test applications. Handle with care and never expose to production environments!
