# Troubleshooting Guide

This guide helps resolve common issues when using the DevOps VAPT Automation framework.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Scanner Issues](#scanner-issues)
3. [CI/CD Pipeline Issues](#cicd-pipeline-issues)
4. [Report Generation Issues](#report-generation-issues)
5. [Performance Issues](#performance-issues)
6. [Network and Connectivity Issues](#network-and-connectivity-issues)

---

## Installation Issues

### Permission Denied Errors

**Problem**: Scripts fail with "Permission denied" error

```
bash: ./scripts/dependency-check.sh: Permission denied
```

**Solution**:
```bash
chmod +x scripts/*.sh
```

### Tool Not Found

**Problem**: Command not found errors

```
dependency-check: command not found
```

**Solutions**:

1. Check if tool is installed:
```bash
which dependency-check
which trivy
which semgrep
```

2. Add tools to PATH:
```bash
export PATH=$PATH:/path/to/tool/bin
# Make permanent by adding to ~/.bashrc or ~/.zshrc
echo 'export PATH=$PATH:/opt/dependency-check/bin' >> ~/.bashrc
```

3. Reinstall the tool following the [Setup Guide](setup-guide.md)

### Incompatible Versions

**Problem**: Version mismatch errors

**Solution**: Verify compatible versions:
```bash
# Check versions
dependency-check --version  # Should be 7.x+
trivy --version             # Should be 0.40+
semgrep --version           # Should be 1.x+
python3 --version           # Should be 3.8+
```

---

## Scanner Issues

### OWASP Dependency-Check Issues

#### Database Update Fails

**Problem**: NVD database update fails

```
ERROR: Unable to download NVD CVE data
```

**Solutions**:

1. Check internet connectivity:
```bash
ping nvd.nist.gov
```

2. Use proxy if behind corporate firewall:
```bash
dependency-check \
    --updateonly \
    --proxyserver proxy.company.com \
    --proxyport 8080
```

3. Manual database download:
```bash
# Download database manually
wget https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-recent.json.gz
```

#### Out of Memory Errors

**Problem**: Java heap space errors

```
java.lang.OutOfMemoryError: Java heap space
```

**Solution**:
```bash
# Increase Java heap size
export JAVA_OPTS="-Xmx4g"

# Or set in script
JAVA_OPTS="-Xmx4g" ./scripts/dependency-check.sh .
```

### Trivy Issues

#### Database Download Fails

**Problem**: Cannot download vulnerability database

**Solutions**:

1. Update Trivy:
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install trivy

# Using binary
wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-64bit.tar.gz
tar xzf trivy_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/
```

2. Manual database update:
```bash
trivy image --download-db-only
```

3. Use offline mode:
```bash
# Download DB on machine with internet
trivy image --download-db-only

# Copy cache to offline machine
cp -r ~/.cache/trivy /path/to/offline/machine/

# Use offline
trivy image --offline-scan your-image:tag
```

#### Docker Permission Errors

**Problem**: Cannot connect to Docker daemon

```
permission denied while trying to connect to the Docker daemon socket
```

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Or use sudo
sudo ./scripts/container-scan.sh image:tag
```

### Semgrep Issues

#### Rule Loading Errors

**Problem**: Cannot load Semgrep rules

**Solutions**:

1. Update Semgrep:
```bash
pip3 install --upgrade semgrep
```

2. Clear cache:
```bash
rm -rf ~/.semgrep
```

3. Use specific rulesets:
```bash
semgrep --config=p/security-audit --config=p/owasp-top-ten .
```

### GitLeaks Issues

#### False Positives

**Problem**: Too many false positives

**Solutions**:

1. Create `.gitleaksignore` file:
```
# Ignore test files
test/fixtures/sample-key.txt
**/test-data/**
```

2. Use baseline:
```bash
# Create baseline from current findings
gitleaks detect --report-path=baseline.json

# Only report new findings
gitleaks detect --baseline-path=baseline.json
```

---

## CI/CD Pipeline Issues

### GitHub Actions Issues

#### Workflow Not Triggering

**Problem**: Pipeline doesn't run on push

**Solutions**:

1. Check workflow file location:
```bash
# Must be in .github/workflows/
ls -la .github/workflows/
```

2. Validate YAML syntax:
```bash
# Use GitHub CLI
gh workflow view security-scan.yml
```

3. Check branch filters:
```yaml
on:
  push:
    branches: [ main, develop ]  # Ensure your branch is listed
```

#### Secret Not Available

**Problem**: Secret variables are undefined

**Solutions**:

1. Verify secrets are configured:
   - Go to Repository Settings → Secrets → Actions
   - Add missing secrets

2. Check secret name in workflow:
```yaml
env:
  TOKEN: ${{ secrets.SONAR_TOKEN }}  # Check spelling
```

### Jenkins Issues

#### Pipeline Fails to Start

**Problem**: Pipeline build fails immediately

**Solutions**:

1. Check Jenkinsfile syntax:
```groovy
// Validate syntax
pipeline {
    agent any
    // ...
}
```

2. Verify Git credentials configured
3. Check Jenkins agent has required tools

#### Email Notifications Not Working

**Problem**: Email notifications not sent

**Solutions**:

1. Configure SMTP in Jenkins:
   - Manage Jenkins → Configure System → Email Notification

2. Test email configuration:
   - Send test email from Jenkins

3. Check emailext plugin is installed

### GitLab CI Issues

#### Job Stuck in Pending

**Problem**: Jobs never start

**Solutions**:

1. Check GitLab Runner availability:
```bash
gitlab-runner verify
```

2. Register runner if needed:
```bash
gitlab-runner register
```

3. Check job tags match runner tags

#### Artifacts Not Uploading

**Problem**: Reports not available as artifacts

**Solutions**:

1. Verify artifact paths exist:
```yaml
artifacts:
  paths:
    - security-reports/  # Ensure this path exists
```

2. Check artifact size limits
3. Extend expiry time if needed

---

## Report Generation Issues

### HTML Report Not Displaying

**Problem**: HTML report is blank or malformed

**Solutions**:

1. Check report generation completed:
```bash
ls -lh security-reports/consolidated/
```

2. Validate HTML:
```bash
# Check for errors
cat security-reports/consolidated/security-report-*.html | grep -i error
```

3. Re-generate report:
```bash
./scripts/report-generator.sh "Project Name"
```

### Missing Data in Reports

**Problem**: Reports don't show all vulnerabilities

**Solutions**:

1. Ensure all scans completed successfully
2. Check scan output logs
3. Verify report aggregation logic

---

## Performance Issues

### Scans Taking Too Long

**Problem**: Security scans exceed timeout

**Solutions**:

1. Increase timeout:
```yaml
# GitHub Actions
timeout-minutes: 60

# GitLab CI
timeout: 1h
```

2. Use caching:
```yaml
# Cache dependency database
- uses: actions/cache@v3
  with:
    path: ~/.trivy-cache
    key: trivy-db-${{ github.run_id }}
```

3. Run scans in parallel:
```yaml
jobs:
  dependency-check:
    # ...
  sast-analysis:
    # Run concurrently
```

4. Exclude unnecessary paths:
```bash
# Exclude test directories
./scripts/dependency-check.sh . --exclude test --exclude node_modules
```

### High Memory Usage

**Problem**: Scans consume excessive memory

**Solutions**:

1. Limit Java heap:
```bash
export JAVA_OPTS="-Xmx2g"
```

2. Process files in batches
3. Use lightweight scanners for large repos

---

## Network and Connectivity Issues

### Proxy Configuration

**Problem**: Cannot download databases behind proxy

**Solutions**:

1. Set proxy environment variables:
```bash
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1
```

2. Configure tool-specific proxy:
```bash
# Dependency-Check
dependency-check --updateonly --proxyserver proxy.company.com --proxyport 8080

# Git
git config --global http.proxy http://proxy.company.com:8080
```

### SSL Certificate Errors

**Problem**: SSL verification failures

**Solutions**:

1. Add corporate CA certificate:
```bash
# Ubuntu/Debian
sudo cp company-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

2. Disable SSL verification (not recommended):
```bash
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

---

## Getting Additional Help

### Collect Debug Information

When reporting issues, include:

```bash
#!/bin/bash
# debug-info.sh

echo "=== System Information ==="
uname -a
cat /etc/os-release

echo -e "\n=== Tool Versions ==="
dependency-check --version 2>&1 || echo "Not installed"
trivy --version 2>&1 || echo "Not installed"
semgrep --version 2>&1 || echo "Not installed"
docker --version 2>&1 || echo "Not installed"

echo -e "\n=== Environment ==="
env | grep -E '(PATH|JAVA_OPTS|HTTP_PROXY)'

echo -e "\n=== Disk Space ==="
df -h

echo -e "\n=== Memory ==="
free -h
```

### Enable Verbose Logging

```bash
# Add to scripts
set -x  # Print commands
set -v  # Print script lines

# Run with verbose output
bash -x ./scripts/dependency-check.sh .
```

### Contact Support

- 📧 Email: security-team@company.com
- 💬 Slack: #security-automation
- 🐛 GitHub Issues: [Create Issue](https://github.com/your-repo/issues)
- 📖 Documentation: [Setup Guide](setup-guide.md)

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `ECONNREFUSED` | Cannot connect to service | Check service is running, firewall rules |
| `ETIMEDOUT` | Connection timeout | Check network connectivity, proxy settings |
| `EACCES` | Permission denied | Check file permissions, run with appropriate user |
| `ENOSPC` | No space left on device | Free up disk space |
| `exit code 137` | Out of memory (OOM killed) | Increase available memory, reduce heap size |
| `SSL certificate problem` | Certificate validation failed | Add CA certificate or configure SSL settings |

---

**Still need help?** Check the [Integration Guide](integration-guide.md) or open an issue on GitHub.
