# DevSecOps Security Pipeline

This directory contains the complete DevSecOps security pipeline implementation for the Apartment Accounting Application, implementing a "Shift-Left" security strategy.

## 🎯 Overview

The security pipeline provides comprehensive security scanning across all layers of the application:

- **Pre-commit Hooks**: Prevent security issues from entering the codebase
- **Code Quality & Linting**: Ensure code standards and catch basic issues
- **SAST (Static Application Security Testing)**: Scan source code for security vulnerabilities
- **SCA (Software Composition Analysis)**: Scan dependencies for known vulnerabilities
- **IaC Scanning**: Scan infrastructure configuration for misconfigurations
- **Container Scanning**: Scan Docker images for vulnerabilities
- **DAST (Dynamic Application Security Testing)**: Test running application for security issues

## 📁 Directory Structure

```
devsecops/
├── README.md                           # This file
├── docs/                              # Documentation
│   ├── DevSecOps-Tool-Matrix.md      # Tool recommendations and alternatives
│   ├── Setup-Guide.md                 # Step-by-step setup instructions
│   ├── CI-CD-Integration.md           # CI/CD pipeline documentation
│   └── Security-Best-Practices.md     # Security guidelines
├── configs/                           # Configuration files
│   ├── bandit.yaml                    # Bandit configuration
│   └── .markdownlint.yaml             # Markdown linting configuration
└── scripts/                           # Security scanning scripts
    ├── install-tools.sh               # Tool installation script
    ├── run-all-scans.sh               # Comprehensive scanning script
    ├── dockerfile-security-check.sh   # Dockerfile security checks
    ├── env-file-check.sh              # Environment file security checks
    └── secrets-scan.sh                # Secrets detection script
```

## 🚀 Quick Start

### 1. Install Security Tools

```bash
# Make scripts executable
chmod +x devsecops/scripts/*.sh

# Install all required tools
./devsecops/scripts/install-tools.sh
```

### 2. Set Up Pre-commit Hooks

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks on all files
pre-commit run --all-files
```

### 3. Run Security Scans

```bash
# Run all security scans
./devsecops/scripts/run-all-scans.sh

# Run individual scans
./devsecops/scripts/dockerfile-security-check.sh backend/Dockerfile
./devsecops/scripts/secrets-scan.sh src/app.js
```

## 🔧 Tools Included

### Mandatory Tools (Must Have)
- **pre-commit**: Git hooks framework
- **black, flake8**: Python code formatting and linting
- **ESLint, Prettier**: JavaScript code quality
- **hadolint**: Dockerfile linting
- **bandit, safety**: Python security scanning
- **npm audit**: JavaScript dependency scanning
- **checkov, trivy**: Infrastructure and container scanning
- **OWASP ZAP**: Dynamic application security testing

### High Priority Tools (Should Have)
- **detect-secrets**: Secret detection
- **mypy**: Python type checking
- **TypeScript**: JavaScript type safety
- **semgrep**: Multi-language SAST
- **pip-audit**: Python dependency scanning

## 📊 Security Categories

### 1. Pre-commit Hooks
- **Purpose**: Prevent security issues from entering the codebase
- **Tools**: pre-commit, detect-secrets, git-secrets
- **Configuration**: `.pre-commit-config.yaml`

### 2. Code Quality & Linting
- **Python**: black, flake8, isort, mypy, pylint
- **JavaScript**: ESLint, Prettier, TypeScript
- **Docker**: hadolint

### 3. Static Application Security Testing (SAST)
- **Python**: bandit, safety, semgrep
- **JavaScript**: ESLint Security, semgrep
- **Multi-language**: semgrep, Snyk Code

### 4. Software Composition Analysis (SCA)
- **Python**: safety, pip-audit
- **JavaScript**: npm audit, Snyk, OWASP Dependency Check

### 5. Infrastructure as Code (IaC) Scanning
- **Docker**: checkov, trivy
- **Docker Compose**: checkov, trivy
- **Terraform**: tfsec (if applicable)

### 6. Container Scanning
- **Images**: trivy, Snyk Container
- **Docker Security**: docker-bench-security

### 7. Dynamic Application Security Testing (DAST)
- **Web Applications**: OWASP ZAP, Burp Suite, Nikto

## 🔄 CI/CD Integration

The security pipeline is integrated with GitHub Actions and runs:

- **On every push** to main/develop branches
- **On every pull request** to main/develop branches
- **Daily at 2 AM UTC** for comprehensive scanning
- **Fail-fast approach**: Build fails on critical security findings

### GitHub Actions Workflow

The pipeline includes 7 jobs that run in parallel where possible:

1. **Code Quality & Linting** (15 min timeout)
2. **Static Application Security Testing** (20 min timeout)
3. **Software Composition Analysis** (15 min timeout)
4. **Infrastructure as Code Scanning** (10 min timeout)
5. **Container Scanning** (20 min timeout) - depends on previous jobs
6. **Dynamic Application Security Testing** (30 min timeout) - depends on container scanning
7. **Security Summary** - runs after all jobs complete

## 📈 Reports and Monitoring

### Report Locations
- **Local scans**: `devsecops/reports/YYYYMMDD_HHMMSS/`
- **CI/CD scans**: GitHub Actions artifacts
- **Pre-commit**: Console output

### Report Formats
- **JSON**: Machine-readable for automation
- **TXT/HTML**: Human-readable for review
- **Markdown**: Summary reports

### Key Metrics
- **Scan Success Rate**: Percentage of successful scans
- **Critical Issues**: High-severity security findings
- **Dependency Vulnerabilities**: Known CVE counts
- **Container Vulnerabilities**: OS and language-level issues

## 🛠️ Configuration

### Environment Variables
```bash
# Optional: Snyk token for enhanced SCA
export SNYK_TOKEN=your-snyk-token

# Optional: Custom tool configurations
export BANDIT_CONFIG=devsecops/configs/bandit.yaml
```

### Customization
- **Tool configurations**: Modify files in `devsecops/configs/`
- **Scan scripts**: Customize `devsecops/scripts/`
- **CI/CD pipeline**: Edit `.github/workflows/security-pipeline.yml`

## 🔒 Security Best Practices

### Development
1. **Never commit secrets** - Use environment variables
2. **Run pre-commit hooks** - Catch issues early
3. **Regular dependency updates** - Keep dependencies current
4. **Secure coding practices** - Follow OWASP guidelines

### CI/CD
1. **Fail on critical issues** - Prevent vulnerable code deployment
2. **Regular scheduled scans** - Continuous security monitoring
3. **Artifact retention** - Keep reports for compliance
4. **Notification integration** - Alert on security failures

### Production
1. **Container scanning** - Scan images before deployment
2. **Runtime monitoring** - Monitor for security incidents
3. **Regular updates** - Keep systems patched
4. **Access controls** - Implement least privilege

## 🚨 Troubleshooting

### Common Issues

#### Pre-commit Hooks Not Running
```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
```

#### Tool Installation Failures
```bash
# Check system requirements
python3 --version
node --version
docker --version

# Manual installation
pip install bandit safety checkov
npm install -g eslint prettier
```

#### Scan Failures
```bash
# Check tool versions
bandit --version
safety --version
trivy --version

# Run with verbose output
./devsecops/scripts/run-all-scans.sh 2>&1 | tee scan-output.log
```

### Getting Help

1. **Check logs**: Review scan output and error messages
2. **Tool documentation**: Each tool has detailed documentation
3. **Configuration files**: Verify tool configurations
4. **System requirements**: Ensure all dependencies are installed

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

## 🤝 Contributing

To contribute to the security pipeline:

1. **Test changes locally** - Run all scans before submitting
2. **Update documentation** - Keep docs current with changes
3. **Follow security practices** - Apply the same standards we enforce
4. **Review configurations** - Ensure tool configs are optimal

## 📄 License

This security pipeline is part of the Apartment Accounting Application project and follows the same licensing terms.