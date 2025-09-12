# CI/CD Integration Guide

This guide explains how to integrate the DevSecOps security pipeline into various CI/CD systems and best practices for implementation.

## 🎯 Overview

The security pipeline is designed to integrate seamlessly with CI/CD systems to provide continuous security validation throughout the software development lifecycle.

## 🔄 Integration Patterns

### 1. Fail-Fast Approach
- **Critical scans run first** and fail the build on high-severity issues
- **Non-critical scans run in parallel** to provide comprehensive coverage
- **Build gates** prevent deployment of vulnerable code

### 2. Parallel Execution
- **Independent scans run in parallel** to minimize pipeline duration
- **Dependency-based execution** for scans that require previous steps
- **Resource optimization** through intelligent job scheduling

### 3. Artifact Management
- **Report storage** in CI/CD artifacts for compliance and review
- **Trend analysis** through historical report comparison
- **Notification integration** for security failures

## 🚀 GitHub Actions Integration

### Workflow Structure

The GitHub Actions workflow (`/.github/workflows/security-pipeline.yml`) includes:

```yaml
name: DevSecOps Security Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC

jobs:
  code-quality:     # 15 min timeout
  sast:            # 20 min timeout  
  sca:             # 15 min timeout
  iac-scanning:    # 10 min timeout
  container-scanning:  # 20 min timeout (depends on previous)
  dast:            # 30 min timeout (depends on container-scanning)
  security-summary:    # Runs after all jobs
```

### Key Features

#### 1. Conditional Execution
```yaml
# Only run on specific branches
if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'

# Skip on documentation changes
if: "!contains(github.event.head_commit.message, 'docs:')"
```

#### 2. Matrix Strategy
```yaml
strategy:
  matrix:
    python-version: [3.11, 3.12]
    node-version: [18, 20]
```

#### 3. Caching
```yaml
- name: Cache Python dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

- name: Cache Node modules
  uses: actions/cache@v3
  with:
    path: frontend/node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('frontend/package-lock.json') }}
```

#### 4. Artifact Management
```yaml
- name: Upload Security Reports
  uses: actions/upload-artifact@v3
  with:
    name: security-reports-${{ github.run_id }}
    path: |
      reports/
      *.json
      *.txt
    retention-days: 30
```

### Environment Variables

```yaml
env:
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '18'
  DOCKER_BUILDKIT: 1
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Secrets Configuration

Required secrets in GitHub repository settings:

| Secret | Description | Required |
|--------|-------------|----------|
| `SNYK_TOKEN` | Snyk API token for enhanced SCA | Optional |
| `GITHUB_TOKEN` | GitHub token for API access | Auto-provided |
| `DOCKER_USERNAME` | Docker Hub username | Optional |
| `DOCKER_PASSWORD` | Docker Hub password | Optional |

## 🔧 GitLab CI Integration

### GitLab CI Pipeline

Create `.gitlab-ci.yml`:

```yaml
stages:
  - security
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

security-scan:
  stage: security
  image: python:3.11
  services:
    - docker:dind
  before_script:
    - pip install --upgrade pip
    - pip install bandit safety checkov trivy
    - npm install -g eslint prettier
  script:
    - ./devsecops/scripts/run-all-scans.sh
  artifacts:
    reports:
      junit: devsecops/reports/*.xml
    paths:
      - devsecops/reports/
    expire_in: 30 days
  only:
    - main
    - develop
    - merge_requests

security-schedule:
  stage: security
  image: python:3.11
  script:
    - ./devsecops/scripts/run-all-scans.sh
  artifacts:
    paths:
      - devsecops/reports/
  only:
    - schedules
```

### GitLab CI Features

#### 1. Pipeline Schedules
- **Daily security scans** at 2 AM UTC
- **Weekly comprehensive scans** on Sundays
- **Custom schedules** for different environments

#### 2. Merge Request Integration
```yaml
security-mr:
  stage: security
  script:
    - ./devsecops/scripts/run-all-scans.sh
  only:
    - merge_requests
  allow_failure: false
```

#### 3. Environment-specific Scans
```yaml
security-staging:
  stage: security
  script:
    - ./devsecops/scripts/run-all-scans.sh --environment staging
  only:
    - main
  when: manual
```

## 🐳 Jenkins Integration

### Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        PYTHON_VERSION = '3.11'
        NODE_VERSION = '18'
        DOCKER_BUILDKIT = '1'
    }
    
    stages {
        stage('Security Scan') {
            parallel {
                stage('Code Quality') {
                    steps {
                        sh './devsecops/scripts/run-code-quality.sh'
                    }
                }
                stage('SAST') {
                    steps {
                        sh './devsecops/scripts/run-sast.sh'
                    }
                }
                stage('SCA') {
                    steps {
                        sh './devsecops/scripts/run-sca.sh'
                    }
                }
                stage('IaC Scanning') {
                    steps {
                        sh './devsecops/scripts/run-iac-scanning.sh'
                    }
                }
            }
        }
        
        stage('Container Scanning') {
            steps {
                sh './devsecops/scripts/run-container-scanning.sh'
            }
        }
        
        stage('DAST') {
            steps {
                sh './devsecops/scripts/run-dast.sh'
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'devsecops/reports/**/*', fingerprint: true
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'devsecops/reports',
                reportFiles: 'security-summary.html',
                reportName: 'Security Report'
            ])
        }
        failure {
            emailext (
                subject: "Security Scan Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Security scan failed. Please check the build logs.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

### Jenkins Plugins

Required Jenkins plugins:

| Plugin | Purpose |
|--------|---------|
| Docker Pipeline | Docker integration |
| HTML Publisher | Security report display |
| Email Extension | Notification |
| Build Timeout | Prevent hanging builds |
| Workspace Cleanup | Cleanup after builds |

## 🔄 Azure DevOps Integration

### Azure Pipelines YAML

```yaml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  pythonVersion: '3.11'
  nodeVersion: '18'

stages:
- stage: Security
  displayName: 'Security Scanning'
  jobs:
  - job: SecurityScan
    displayName: 'Run Security Scans'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(pythonVersion)'
    
    - task: NodeTool@0
      inputs:
        versionSpec: '$(nodeVersion)'
    
    - script: |
        pip install --upgrade pip
        pip install bandit safety checkov trivy
        npm install -g eslint prettier
      displayName: 'Install Security Tools'
    
    - script: |
        ./devsecops/scripts/run-all-scans.sh
      displayName: 'Run Security Scans'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFiles: 'devsecops/reports/*.xml'
        testRunTitle: 'Security Scan Results'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: 'devsecops/reports'
        artifactName: 'security-reports'
```

## 🚀 CircleCI Integration

### CircleCI Config

```yaml
version: 2.1

jobs:
  security-scan:
    docker:
      - image: python:3.11
      - image: node:18
    steps:
      - checkout
      - run:
          name: Install Security Tools
          command: |
            pip install bandit safety checkov trivy
            npm install -g eslint prettier
      - run:
          name: Run Security Scans
          command: ./devsecops/scripts/run-all-scans.sh
      - store_artifacts:
          path: devsecops/reports
          destination: security-reports

workflows:
  security-pipeline:
    jobs:
      - security-scan:
          filters:
            branches:
              only: [main, develop]
```

## 📊 Monitoring and Alerting

### 1. Build Status Monitoring

```yaml
# GitHub Actions notification
- name: Notify on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 2. Security Metrics

Track key security metrics:

- **Scan Success Rate**: Percentage of successful scans
- **Critical Issues**: High-severity security findings
- **Dependency Vulnerabilities**: Known CVE counts
- **Container Vulnerabilities**: OS and language-level issues
- **Scan Duration**: Time to complete security scans

### 3. Trend Analysis

```bash
# Generate trend report
./devsecops/scripts/generate-trend-report.sh

# Compare with previous scans
./devsecops/scripts/compare-scans.sh current previous
```

## 🔒 Security Best Practices

### 1. Secret Management

```yaml
# Use CI/CD secret management
env:
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}

# Never hardcode secrets
# ❌ BAD
SNYK_TOKEN: "abc123"

# ✅ GOOD
SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### 2. Access Control

```yaml
# Restrict security scans to specific branches
if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'

# Use environment-specific secrets
if: github.ref == 'refs/heads/main'
  env:
    ENVIRONMENT: production
```

### 3. Resource Management

```yaml
# Set appropriate timeouts
timeout-minutes: 30

# Use resource limits
resources:
  limits:
    memory: 4Gi
    cpu: 2
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Check build logs
# Look for specific error messages
# Verify tool installations
# Check resource constraints
```

#### 2. Scan Timeouts
```yaml
# Increase timeout
timeout-minutes: 60

# Optimize scan scope
script: |
  ./devsecops/scripts/run-all-scans.sh --quick
```

#### 3. Resource Constraints
```yaml
# Use larger runners
runs-on: ubuntu-latest-4-cores

# Optimize parallel execution
strategy:
  max-parallel: 4
```

### Debug Commands

```bash
# Debug individual tools
bandit --version
safety --version
trivy --version

# Run with verbose output
./devsecops/scripts/run-all-scans.sh --verbose

# Check system resources
free -h
df -h
```

## 📈 Performance Optimization

### 1. Caching Strategies

```yaml
# Cache dependencies
- name: Cache Python dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

# Cache Docker layers
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
```

### 2. Parallel Execution

```yaml
# Run independent scans in parallel
strategy:
  matrix:
    scan-type: [code-quality, sast, sca, iac-scanning]
```

### 3. Incremental Scanning

```bash
# Only scan changed files
git diff --name-only HEAD~1 | grep -E '\.(py|js|ts|yaml|yml)$' | xargs ./devsecops/scripts/run-targeted-scan.sh
```

## 🎯 Next Steps

After CI/CD integration:

1. **Monitor pipeline performance** - Track scan duration and success rates
2. **Optimize resource usage** - Adjust timeouts and resource limits
3. **Implement notifications** - Set up alerts for security failures
4. **Regular maintenance** - Update tools and configurations
5. **Team training** - Ensure developers understand the security pipeline
6. **Continuous improvement** - Regularly enhance the security pipeline
