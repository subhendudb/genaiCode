# DevSecOps Quick Start Guide

This guide provides quick commands and examples for running the DevSecOps security pipeline.

## 🚀 Quick Commands

### 1. Install All Tools
```bash
# Make scripts executable
chmod +x devsecops/scripts/*.sh

# Install all security tools
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
./devsecops/scripts/env-file-check.sh .env
```

## 🔧 Individual Tool Commands

### Python Security
```bash
# Code formatting
black backend/ --check --diff

# Linting
flake8 backend/ --count --statistics

# Security scanning
bandit -r backend/ -f json -o bandit-report.json
safety check --json --output safety-report.json

# Type checking
mypy backend/ --ignore-missing-imports
```

### JavaScript Security
```bash
# Linting
cd frontend && npx eslint src/ --ext .js,.jsx,.ts,.tsx

# Formatting
cd frontend && npx prettier --check src/

# Dependency scanning
cd frontend && npm audit --json > npm-audit-report.json
```

### Docker Security
```bash
# Dockerfile linting
hadolint backend/Dockerfile frontend/Dockerfile

# Container scanning
trivy image apartment-accounting-backend:latest
trivy image apartment-accounting-frontend:latest

# IaC scanning
checkov -f docker-compose.yml --framework docker_compose
checkov -f backend/Dockerfile --framework dockerfile
```

### Infrastructure Scanning
```bash
# Trivy IaC scan
trivy config . --format json --output trivy-iac-report.json

# Checkov scan
checkov -f docker-compose.yml --framework docker_compose --output json
```

### Dynamic Testing
```bash
# Start application
docker-compose up -d

# OWASP ZAP scan
docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:8000

# Stop application
docker-compose down
```

## 📊 Report Locations

### Local Scans
- **Reports**: `devsecops/reports/YYYYMMDD_HHMMSS/`
- **Summary**: `devsecops/reports/YYYYMMDD_HHMMSS/security-scan-summary.md`

### CI/CD Scans
- **GitHub Actions**: Check Actions tab → Artifacts
- **Reports**: Download from workflow artifacts

## 🚨 Common Issues & Solutions

### Pre-commit Hooks Not Running
```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install

# Run manually
pre-commit run --all-files
```

### Tool Installation Failures
```bash
# Check Python
python3 --version
pip install --upgrade pip

# Check Node.js
node --version
npm --version

# Manual installation
pip install bandit safety checkov
npm install -g eslint prettier
```

### Scan Failures
```bash
# Check tool versions
bandit --version
safety --version
trivy --version

# Run with verbose output
./devsecops/scripts/run-all-scans.sh 2>&1 | tee scan-output.log
```

## 🔄 CI/CD Integration

### GitHub Actions
The pipeline runs automatically on:
- **Push to main/develop**: Full security scan
- **Pull requests**: Security validation
- **Daily at 2 AM UTC**: Comprehensive scan

### Manual Trigger
```bash
# Trigger workflow manually
gh workflow run security-pipeline.yml
```

## 📈 Monitoring

### Check Scan Status
```bash
# View recent scans
ls -la devsecops/reports/

# Check scan summary
cat devsecops/reports/*/security-scan-summary.md
```

### View Reports
```bash
# Open reports directory
open devsecops/reports/

# View specific report
cat devsecops/reports/*/bandit-report.txt
cat devsecops/reports/*/safety-report.txt
```

## 🎯 Next Steps

1. **Review Reports**: Check all generated security reports
2. **Fix Issues**: Address critical and high-severity findings
3. **Customize**: Adjust tool configurations as needed
4. **Monitor**: Set up regular scanning schedule
5. **Train Team**: Ensure developers understand the pipeline

## 📚 Documentation

- **Main Guide**: `devsecops/README.md`
- **Setup Guide**: `devsecops/docs/Setup-Guide.md`
- **CI/CD Guide**: `devsecops/docs/CI-CD-Integration.md`
- **Best Practices**: `devsecops/docs/Security-Best-Practices.md`
- **Tool Matrix**: `devsecops/docs/DevSecOps-Tool-Matrix.md`

## 🆘 Support

- **Issues**: Create an issue in the repository
- **Documentation**: Check the docs/ directory
- **Scripts**: Review devsecops/scripts/ for examples
- **Configuration**: Check devsecops/configs/ for settings
