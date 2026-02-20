# DevOps VAPT Automation - Setup Guide

This guide will help you set up and configure the DevOps VAPT Automation framework in your environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Tool Setup](#tool-setup)
5. [CI/CD Integration](#cicd-integration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+, CentOS 7+, RHEL 8+) or macOS
- **Shell**: Bash 4.0+
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Disk Space**: Minimum 10GB free space
- **Network**: Internet connectivity for downloading security databases

### Required Tools

- **Git**: Version 2.0 or higher
- **Docker**: Version 20.0 or higher (for container scanning)
- **Python**: Version 3.8 or higher
- **Node.js**: Version 14 or higher (if scanning Node.js projects)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/devops-vapt-automation.git
cd devops-vapt-automation
```

### 2. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 3. Install Security Scanning Tools

#### Option A: Automated Installation (Recommended)

```bash
# Run the automated tool installer
./scripts/install-tools.sh
```

#### Option B: Manual Installation

**Install OWASP Dependency-Check:**

```bash
# Download Dependency-Check
VERSION=7.4.4
wget https://github.com/jeremylong/DependencyCheck/releases/download/v${VERSION}/dependency-check-${VERSION}-release.zip

# Extract
unzip dependency-check-${VERSION}-release.zip

# Move to /opt or add to PATH
sudo mv dependency-check /opt/
echo 'export PATH=$PATH:/opt/dependency-check/bin' >> ~/.bashrc
source ~/.bashrc
```

**Install Trivy:**

```bash
# Ubuntu/Debian
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# CentOS/RHEL
sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-64bit.rpm

# macOS
brew install aquasecurity/trivy/trivy
```

**Install Semgrep:**

```bash
pip3 install semgrep
```

**Install Bandit (for Python projects):**

```bash
pip3 install bandit
```

**Install GitLeaks:**

```bash
# Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# macOS
brew install gitleaks
```

## Configuration

### 1. Configure Security Thresholds

Edit `config/vulnerability-thresholds.json` to set acceptable vulnerability levels for each environment:

```json
{
  "production": {
    "critical": 0,
    "high": 0,
    "medium": 5,
    "low": 20
  }
}
```

### 2. Configure Security Policies

Edit `config/security-policies.yml` to define your security requirements:

```yaml
code_security:
  sast:
    enabled: true
    block_on_critical: true
```

### 3. Configure Scanner Settings

Edit `config/scan-config.json` to customize scanner behavior:

```json
{
  "dependency_check": {
    "fail_on_cvss": 7.0,
    "update_database": true
  }
}
```

### 4. Environment Variables

Create a `.env` file (optional):

```bash
# Environment
ENVIRONMENT=development

# Notifications
SECURITY_TEAM_EMAIL=security@company.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Tool Paths
DEPENDENCY_CHECK_PATH=/opt/dependency-check/bin/dependency-check.sh
TRIVY_PATH=/usr/local/bin/trivy
```

## Tool Setup

### Initialize Security Databases

```bash
# Update OWASP Dependency-Check database
dependency-check --updateonly

# Update Trivy database
trivy image --download-db-only
```

### Verify Tool Installation

```bash
# Check all tools are installed
dependency-check --version
trivy --version
semgrep --version
bandit --version
gitleaks version
```

## CI/CD Integration

### GitHub Actions

1. Copy the workflow file to your repository:
```bash
cp .github/workflows/security-scan.yml /path/to/your/repo/.github/workflows/
```

2. Configure GitHub Secrets:
   - `SONAR_TOKEN` (if using SonarCloud)
   - `SECURITY_TEAM_EMAIL`

3. Commit and push:
```bash
git add .github/workflows/security-scan.yml
git commit -m "Add security scanning workflow"
git push
```

### Jenkins

1. Import the Jenkinsfile:
```bash
cp jenkins/Jenkinsfile /path/to/your/repo/
```

2. Create a new Pipeline job in Jenkins
3. Point to the Jenkinsfile in your repository
4. Configure environment variables in Jenkins

### GitLab CI

1. Copy the GitLab CI configuration:
```bash
cp gitlab/.gitlab-ci.yml /path/to/your/repo/
```

2. Configure CI/CD variables in GitLab:
   - `SECURITY_TEAM_EMAIL`
   - Other required variables

3. Commit and push:
```bash
git add .gitlab-ci.yml
git commit -m "Add security scanning pipeline"
git push
```

## Verification

### Run Manual Scans

Test each scanner individually:

```bash
# Test dependency check
./scripts/dependency-check.sh .

# Test container scan (if you have a Docker image)
./scripts/container-scan.sh your-image:tag

# Test SAST
./scripts/sast-scan.sh .

# Test secret detection
./scripts/secret-detection.sh .

# Generate consolidated report
./scripts/report-generator.sh "Test Project"
```

### Check Reports

Reports are generated in `./security-reports/`:

```bash
ls -la security-reports/
```

View the consolidated HTML report:

```bash
# Linux
xdg-open security-reports/consolidated/security-report-*.html

# macOS
open security-reports/consolidated/security-report-*.html
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied

**Error**: `Permission denied: ./scripts/dependency-check.sh`

**Solution**:
```bash
chmod +x scripts/*.sh
```

#### 2. Tool Not Found

**Error**: `command not found: dependency-check`

**Solution**: Ensure tools are in your PATH:
```bash
which dependency-check
echo $PATH
```

#### 3. Database Update Fails

**Error**: `Failed to update NVD database`

**Solution**: Check internet connectivity and run:
```bash
dependency-check --updateonly --proxyserver proxy.company.com --proxyport 8080
```

#### 4. Out of Memory

**Error**: `java.lang.OutOfMemoryError`

**Solution**: Increase Java heap size:
```bash
export JAVA_OPTS="-Xmx4g"
```

#### 5. Docker Permission Issues

**Error**: `permission denied while trying to connect to Docker daemon`

**Solution**: Add user to docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Getting Help

- Check the [Troubleshooting Guide](troubleshooting.md)
- Review [Integration Guide](integration-guide.md)
- Open an issue on GitHub
- Contact security team

## Next Steps

1. ✅ Complete setup and verification
2. 📝 Customize configuration for your environment
3. 🔗 Integrate with your CI/CD pipeline
4. 📊 Set up monitoring and notifications
5. 🎓 Train team on security best practices

## Additional Resources

- [OWASP Dependency-Check Documentation](https://owasp.org/www-project-dependency-check/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Semgrep Documentation](https://semgrep.dev/docs/)
- [GitLeaks Documentation](https://github.com/gitleaks/gitleaks)

---

**Need Help?** Refer to the [Integration Guide](integration-guide.md) for detailed CI/CD setup instructions.
