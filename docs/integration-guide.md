# CI/CD Integration Guide

This guide provides detailed instructions for integrating the DevOps VAPT Automation framework into various CI/CD platforms.

## Table of Contents

1. [GitHub Actions](#github-actions)
2. [Jenkins](#jenkins)
3. [GitLab CI/CD](#gitlab-cicd)
4. [Azure DevOps](#azure-devops)
5. [CircleCI](#circleci)
6. [Custom Integration](#custom-integration)

---

## GitHub Actions

### Basic Setup

1. **Add the workflow file** to your repository:

```bash
mkdir -p .github/workflows
cp devops-vapt-automation/.github/workflows/security-scan.yml .github/workflows/
```

2. **Configure repository secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `SECURITY_TEAM_EMAIL`
     - `SONAR_TOKEN` (if using SonarCloud)
     - `GITLEAKS_LICENSE` (optional)

3. **Customize the workflow**:

```yaml
env:
  ENVIRONMENT: ${{ github.ref == 'refs/heads/main' && 'production' || 'development' }}
```

### Advanced Configuration

#### Conditional Scans

Run certain scans only on specific branches:

```yaml
container-scan:
  if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/staging'
```

#### Scheduled Scans

Add nightly security scans:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

#### Custom Thresholds

Set environment-specific thresholds:

```yaml
- name: Security Gate
  run: |
    if [ "$ENVIRONMENT" == "production" ]; then
      MAX_CRITICAL=0
      MAX_HIGH=0
    elif [ "$ENVIRONMENT" == "staging" ]; then
      MAX_CRITICAL=0
      MAX_HIGH=2
    else
      MAX_CRITICAL=1
      MAX_HIGH=5
    fi
```

### Integration with GitHub Security

Enable Security tab integration:

```yaml
- name: Upload to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: security-results.sarif
```

---

## Jenkins

### Basic Setup

1. **Create a new Pipeline job**:
   - New Item → Pipeline
   - Name: "Security-Scan"

2. **Configure Pipeline**:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your repo URL
   - Script Path: `jenkins/Jenkinsfile`

3. **Set Environment Variables**:

Go to Manage Jenkins → Configure System → Global Properties:

```
SECURITY_TEAM_EMAIL=security@company.com
SONAR_TOKEN=your_sonar_token
```

### Advanced Configuration

#### Parameterized Builds

Add build parameters:

```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['development', 'staging', 'production'],
        description: 'Target environment'
    )
    booleanParam(
        name: 'SKIP_TESTS',
        defaultValue: false,
        description: 'Skip security tests'
    )
}
```

#### Email Notifications

Configure email notifications:

```groovy
post {
    failure {
        emailext(
            subject: "Security Scan Failed - ${JOB_NAME} #${BUILD_NUMBER}",
            body: """
                Security vulnerabilities detected!
                
                Build: ${BUILD_NUMBER}
                Environment: ${params.ENVIRONMENT}
                
                View report: ${BUILD_URL}Security_20Scan_20Report/
            """,
            to: "${env.SECURITY_TEAM_EMAIL}",
            mimeType: 'text/html'
        )
    }
}
```

#### Parallel Execution

Run scans in parallel:

```groovy
stage('Security Scans') {
    parallel {
        stage('Dependency Check') {
            steps {
                sh './scripts/dependency-check.sh .'
            }
        }
        stage('SAST Analysis') {
            steps {
                sh './scripts/sast-scan.sh .'
            }
        }
        stage('Secret Detection') {
            steps {
                sh './scripts/secret-detection.sh .'
            }
        }
    }
}
```

### Jenkins Shared Library

Create a shared library for reusability:

```groovy
// vars/securityScan.groovy
def call(Map config = [:]) {
    pipeline {
        agent any
        stages {
            stage('Security Scan') {
                steps {
                    script {
                        sh "./scripts/dependency-check.sh ${config.path ?: '.'}"
                        sh "./scripts/sast-scan.sh ${config.path ?: '.'}"
                    }
                }
            }
        }
    }
}
```

Usage in Jenkinsfile:

```groovy
@Library('security-lib') _
securityScan(path: '.')
```

---

## GitLab CI/CD

### Basic Setup

1. **Add `.gitlab-ci.yml`** to your repository:

```bash
cp devops-vapt-automation/gitlab/.gitlab-ci.yml .
```

2. **Configure CI/CD Variables**:
   - Go to Settings → CI/CD → Variables
   - Add:
     - `SECURITY_TEAM_EMAIL`
     - `SONAR_TOKEN` (if applicable)

3. **Commit and push**:

```bash
git add .gitlab-ci.yml
git commit -m "Add security scanning pipeline"
git push
```

### Advanced Configuration

#### Environment-Specific Jobs

Run jobs only for specific environments:

```yaml
production-scan:
  stage: security-scan
  script:
    - ./scripts/dependency-check.sh .
  only:
    - main
  environment:
    name: production
```

#### Manual Jobs

Add manual approval gates:

```yaml
security-gate:
  stage: gate
  script:
    - echo "Review security findings"
  when: manual
  only:
    - main
```

#### Dynamic Environments

Use dynamic environment variables:

```yaml
variables:
  ENVIRONMENT: ${CI_COMMIT_REF_NAME}

before_script:
  - |
    if [ "$CI_COMMIT_REF_NAME" == "main" ]; then
      export ENVIRONMENT="production"
    elif [ "$CI_COMMIT_REF_NAME" == "staging" ]; then
      export ENVIRONMENT="staging"
    else
      export ENVIRONMENT="development"
    fi
```

### GitLab Security Dashboard

Integrate with GitLab Security Dashboard:

```yaml
sast:
  stage: test
  script:
    - semgrep --config=auto --sarif --output=gl-sast-report.json .
  artifacts:
    reports:
      sast: gl-sast-report.json
```

---

## Azure DevOps

### Basic Setup

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop
      - staging

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: SecurityScan
    displayName: 'Security Vulnerability Scan'
    jobs:
      - job: DependencyCheck
        displayName: 'Dependency Vulnerability Scan'
        steps:
          - checkout: self
          
          - script: |
              chmod +x scripts/*.sh
              ./scripts/dependency-check.sh .
            displayName: 'Run Dependency Check'
          
          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'security-reports'
              artifactName: 'security-reports'
      
      - job: SASTAnalysis
        displayName: 'SAST Analysis'
        steps:
          - script: |
              ./scripts/sast-scan.sh .
            displayName: 'Run SAST'
      
      - job: SecretDetection
        displayName: 'Secret Detection'
        steps:
          - script: |
              ./scripts/secret-detection.sh .
            displayName: 'Detect Secrets'
```

### Pipeline Variables

Configure in Azure DevOps:
- Pipeline → Edit → Variables
- Add `SECURITY_TEAM_EMAIL`, `ENVIRONMENT`, etc.

---

## CircleCI

### Basic Setup

Create `.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  dependency-check:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - run:
          name: Dependency Scan
          command: |
            chmod +x scripts/*.sh
            ./scripts/dependency-check.sh .
      - store_artifacts:
          path: security-reports

  sast-analysis:
    docker:
      - image: cimg/python:3.9
    steps:
      - checkout
      - run:
          name: SAST Scan
          command: |
            pip install semgrep bandit
            ./scripts/sast-scan.sh .
      - store_artifacts:
          path: security-reports

workflows:
  security-scan:
    jobs:
      - dependency-check
      - sast-analysis
```

---

## Custom Integration

### Webhook Integration

Trigger scans via webhook:

```bash
#!/bin/bash
# webhook-handler.sh

# Receive webhook
PAYLOAD=$(cat)
BRANCH=$(echo $PAYLOAD | jq -r '.ref')

if [ "$BRANCH" == "refs/heads/main" ]; then
    export ENVIRONMENT="production"
    ./scripts/dependency-check.sh .
    ./scripts/sast-scan.sh .
    ./scripts/report-generator.sh "Webhook Scan"
fi
```

### API Integration

Create a REST API for scan triggers:

```python
from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route('/scan', methods=['POST'])
def trigger_scan():
    data = request.json
    project_path = data.get('path', '.')
    environment = data.get('environment', 'development')
    
    result = subprocess.run(
        [f'./scripts/dependency-check.sh', project_path],
        env={'ENVIRONMENT': environment},
        capture_output=True
    )
    
    return jsonify({
        'status': 'completed',
        'exit_code': result.returncode
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

## Best Practices

1. **Run scans on every commit** to development branches
2. **Block merges** if critical vulnerabilities found
3. **Schedule nightly scans** for comprehensive analysis
4. **Set environment-specific thresholds**
5. **Integrate with security dashboards**
6. **Automate notifications** to security teams
7. **Archive scan reports** for compliance
8. **Use caching** to speed up scans
9. **Implement retry logic** for transient failures
10. **Monitor scan duration** and optimize

---

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common integration issues.
