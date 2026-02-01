# DevOps VAPT Automation

A comprehensive security automation framework that integrates Vulnerability Assessment and Penetration Testing (VAPT) into CI/CD pipelines, ensuring code security between development and deployment phases.

## Overview

This project implements an automated security testing environment that scans for vulnerabilities in application code before it moves through different environments (Dev → Staging → Production). By integrating security checks directly into the DevOps pipeline, we reduce manual intervention and maintain consistent security compliance across all builds.

## Key Features

- **Automated Vulnerability Scanning**: Automated scripts that run security tests before code promotion
- **CI/CD Integration**: Seamless integration with GitHub Actions, GitLab CI, and Jenkins
- **Multi-Tool Security Suite**: Integration of OWASP Dependency-Check, Trivy, and custom security scripts
- **Automated Reporting**: Generate comprehensive security reports for each build
- **Environment-Specific Testing**: Different security policies for dev, staging, and production environments
- **Compliance Tracking**: Maintain audit logs and ensure security compliance across builds
- **Fail-Safe Mechanisms**: Pipeline fails automatically if critical vulnerabilities are detected

## Architecture

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────┐
│ Developer   │─────▶│  Git Repository  │─────▶│  CI/CD      │
│ Commit      │      │  (Code Changes)  │      │  Triggered  │
└─────────────┘      └──────────────────┘      └─────────────┘
                                                       │
                     ┌─────────────────────────────────┘
                     ▼
          ┌────────────────────────┐
          │  Security Scan Stage   │
          ├────────────────────────┤
          │ • Dependency Check     │
          │ • SAST Analysis        │
          │ • Container Scanning   │
          │ • Secret Detection     │
          └────────────────────────┘
                     │
          ┌──────────┴───────────┐
          ▼                      ▼
    ✅ Pass                  ❌ Fail
          │                      │
          ▼                      ▼
  ┌──────────────┐      ┌──────────────┐
  │  Deploy to   │      │  Block       │
  │  Next Stage  │      │  Deployment  │
  └──────────────┘      └──────────────┘
          │                      │
          ▼                      ▼
  ┌──────────────┐      ┌──────────────┐
  │  Generate    │      │  Send        │
  │  Report      │      │  Alert       │
  └──────────────┘      └──────────────┘
```

## Project Structure

```
devops-vapt-automation/
├── .github/
│   └── workflows/
│       └── security-scan.yml          # GitHub Actions pipeline
├── scripts/
│   ├── dependency-check.sh            # Dependency vulnerability scanner
│   ├── container-scan.sh              # Container image security scan
│   ├── sast-scan.sh                   # Static Application Security Testing
│   ├── secret-detection.sh            # Secret/credential scanner
│   ├── compliance-check.sh            # Security compliance validation
│   └── report-generator.sh            # Automated report generation
├── config/
│   ├── security-policies.yml          # Security policy definitions
│   ├── vulnerability-thresholds.json  # Acceptable risk thresholds
│   └── scan-config.json               # Scanner configurations
├── jenkins/
│   └── Jenkinsfile                    # Jenkins pipeline configuration
├── gitlab/
│   └── .gitlab-ci.yml                 # GitLab CI configuration
├── docs/
│   ├── setup-guide.md                 # Installation and setup guide
│   ├── integration-guide.md           # CI/CD integration instructions
│   └── troubleshooting.md             # Common issues and solutions
├── tests/
│   ├── test-vulnerable-app/           # Sample vulnerable application
│   └── validate-scanners.sh           # Test suite for scanners
└── README.md                          # This file
```

## Quick Start

### Prerequisites

- Linux/Unix environment (or WSL on Windows)
- Docker installed
- Git
- CI/CD platform (GitHub Actions, GitLab CI, or Jenkins)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/devops-vapt-automation.git
cd devops-vapt-automation
```

2. Make scripts executable:
```bash
chmod +x scripts/*.sh
```

3. Install required scanning tools:
```bash
# Install OWASP Dependency-Check
./scripts/install-tools.sh

# Or install manually:
# - Trivy: https://aquasecurity.github.io/trivy/
# - OWASP Dependency-Check: https://owasp.org/www-project-dependency-check/
```

### Usage

#### Running Manual Scans

```bash
# Run all security scans
./scripts/dependency-check.sh ./your-project-path

# Run container scan
./scripts/container-scan.sh your-image:tag

# Run SAST analysis
./scripts/sast-scan.sh ./your-source-code

# Generate security report
./scripts/report-generator.sh
```

#### CI/CD Integration

**GitHub Actions**: Copy `.github/workflows/security-scan.yml` to your repository

**Jenkins**: Import `jenkins/Jenkinsfile` to your Jenkins pipeline

**GitLab CI**: Copy `gitlab/.gitlab-ci.yml` to your repository root

## Security Scanning Tools

| Tool | Purpose | Integration |
|------|---------|-------------|
| OWASP Dependency-Check | Identifies known vulnerabilities in project dependencies | All pipelines |
| Trivy | Container and filesystem vulnerability scanner | Container builds |
| GitLeaks | Detects secrets and credentials in code | Pre-commit & CI |
| Bandit | Python SAST scanner | Python projects |
| Semgrep | Multi-language SAST tool | All codebases |

## Security Reports

The automation generates comprehensive reports including:

- **Vulnerability Summary**: Total vulnerabilities by severity (Critical, High, Medium, Low)
- **Dependency Analysis**: Outdated and vulnerable dependencies
- **CVSS Scores**: Common Vulnerability Scoring System ratings
- **Remediation Guidance**: Actionable steps to fix identified issues
- **Compliance Status**: Pass/Fail based on security policies
- **Historical Trends**: Track security improvements over time

Reports are generated in multiple formats: HTML, JSON, PDF, and XML.

## Security Policy Configuration

Customize security thresholds in `config/vulnerability-thresholds.json`:

```json
{
  "production": {
    "critical": 0,
    "high": 0,
    "medium": 5,
    "low": 20
  },
  "staging": {
    "critical": 0,
    "high": 2,
    "medium": 10,
    "low": 50
  },
  "development": {
    "critical": 1,
    "high": 5,
    "medium": 20,
    "low": 100
  }
}
```

## Best Practices Implemented

- ✅ Shift-left security approach
- ✅ Automated security gates in CI/CD
- ✅ Fail-fast on critical vulnerabilities
- ✅ Comprehensive audit logging
- ✅ Environment-specific security policies
- ✅ Regular security tool updates
- ✅ Developer-friendly reporting
- ✅ Integration with issue tracking systems

## Benefits

- **Reduced Manual Effort**: 90% reduction in manual security testing
- **Faster Detection**: Identify vulnerabilities within minutes of commit
- **Consistent Security**: Uniform security standards across all environments
- **Cost Effective**: Catch issues early in the development cycle
- **Compliance Ready**: Automated audit trails for compliance requirements
- **Developer Empowerment**: Security feedback integrated into developer workflow

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 🔗 Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [DevSecOps Best Practices](https://www.devsecops.org/)
- [CI/CD Security Guide](https://snyk.io/learn/ci-cd-security/)
- [Vulnerability Disclosure Policy](https://www.cisa.gov/coordinated-vulnerability-disclosure-process)

---

