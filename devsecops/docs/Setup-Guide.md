# DevSecOps Setup Guide

This guide provides step-by-step instructions for setting up the complete DevSecOps security pipeline for the Apartment Accounting Application.

## 📋 Prerequisites

### System Requirements
- **Operating System**: macOS, Linux, or Windows with WSL2
- **Python**: 3.11 or higher
- **Node.js**: 18 or higher
- **Docker**: 20.10 or higher
- **Git**: 2.30 or higher
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Disk Space**: 2GB free space

### Required Accounts (Optional)
- **GitHub**: For CI/CD pipeline
- **Snyk**: For enhanced security scanning (optional)
- **Docker Hub**: For container registry (optional)

## 🚀 Installation Steps

### Step 1: Clone and Navigate to Project

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd apartment-accounting

# Navigate to project root
pwd  # Should show: /path/to/apartment-accounting
```

### Step 2: Run Automated Installation

```bash
# Make scripts executable
chmod +x devsecops/scripts/*.sh

# Run the installation script
./devsecops/scripts/install-tools.sh
```

The installation script will:
- Detect your operating system
- Install required system dependencies
- Install Python security tools
- Install Node.js security tools
- Install system security tools
- Set up git hooks
- Install pre-commit hooks
- Install project dependencies

### Step 3: Verify Installation

```bash
# Check critical tools
pre-commit --version
black --version
flake8 --version
bandit --version
safety --version
eslint --version
prettier --version
hadolint --version
checkov --version
trivy --version

# Check Docker
docker --version
docker-compose --version
```

### Step 4: Initialize Security Baseline

```bash
# Initialize detect-secrets baseline
detect-secrets scan --baseline .secrets.baseline

# Initialize git-secrets (if available)
git secrets --install
git secrets --register-aws
```

### Step 5: Test the Pipeline

```bash
# Run a quick test scan
./devsecops/scripts/run-all-scans.sh
```

## 🔧 Manual Installation (Alternative)

If the automated installation fails, you can install tools manually:

### Python Tools

```bash
# Install Python security tools
pip install pre-commit black flake8 isort mypy bandit safety detect-secrets checkov semgrep

# Install additional Python tools
pip install pylint pip-audit
```

### Node.js Tools

```bash
# Install global Node.js tools
npm install -g eslint prettier typescript snyk

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### System Tools (macOS)

```bash
# Install using Homebrew
brew install hadolint trivy git-secrets dependency-check

# Install OWASP ZAP
brew install --cask owasp-zap
```

### System Tools (Linux)

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y hadolint git-secrets

# Install Trivy
wget -qO- https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo 'deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main' | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Install OWASP Dependency Check
wget https://github.com/jeremylong/DependencyCheck/releases/latest/download/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip
sudo mv dependency-check /opt/
sudo ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
```

## ⚙️ Configuration

### Pre-commit Configuration

The pre-commit configuration is already set up in `.pre-commit-config.yaml`. To customize:

```bash
# Edit the configuration
nano .pre-commit-config.yaml

# Update hooks
pre-commit autoupdate

# Reinstall hooks
pre-commit uninstall
pre-commit install
```

### Tool-Specific Configuration

#### Bandit Configuration
```bash
# Edit bandit configuration
nano devsecops/configs/bandit.yaml
```

#### ESLint Configuration
```bash
# Edit ESLint configuration
nano frontend/.eslintrc.js
```

#### Prettier Configuration
```bash
# Edit Prettier configuration
nano frontend/.prettierrc
```

### Environment Variables

Create a `.env` file for sensitive configuration:

```bash
# Create environment file
cat > .env << EOF
# Snyk token (optional)
SNYK_TOKEN=your-snyk-token-here

# Custom tool configurations
BANDIT_CONFIG=devsecops/configs/bandit.yaml
ESLINT_CONFIG=frontend/.eslintrc.js
PRETTIER_CONFIG=frontend/.prettierrc

# Scan output directory
SCAN_OUTPUT_DIR=devsecops/reports
EOF

# Add to .gitignore
echo ".env" >> .gitignore
```

## 🧪 Testing the Setup

### Test Pre-commit Hooks

```bash
# Test pre-commit hooks on staged files
git add .
pre-commit run

# Test pre-commit hooks on all files
pre-commit run --all-files
```

### Test Individual Scans

```bash
# Test Python security scan
bandit -r backend/

# Test JavaScript security scan
cd frontend
npx eslint src/

# Test Docker security scan
hadolint backend/Dockerfile

# Test dependency scan
safety check

# Test container scan
trivy image apartment-accounting-backend:latest
```

### Test Comprehensive Scan

```bash
# Run all security scans
./devsecops/scripts/run-all-scans.sh
```

## 🔄 CI/CD Setup

### GitHub Actions Setup

1. **Enable GitHub Actions** in your repository settings
2. **Add secrets** (if using Snyk):
   - Go to Settings → Secrets and variables → Actions
   - Add `SNYK_TOKEN` with your Snyk API token

3. **Test the pipeline**:
   - Create a pull request
   - Check the Actions tab for security pipeline results

### Custom CI/CD Integration

For other CI/CD systems, adapt the GitHub Actions workflow:

```yaml
# Example for GitLab CI
security-scan:
  stage: security
  script:
    - ./devsecops/scripts/run-all-scans.sh
  artifacts:
    reports:
      junit: devsecops/reports/*.xml
    paths:
      - devsecops/reports/
```

## 🐛 Troubleshooting

### Common Installation Issues

#### Python Installation Issues
```bash
# Check Python version
python3 --version

# Upgrade pip
python3 -m pip install --upgrade pip

# Install with user flag
python3 -m pip install --user bandit safety
```

#### Node.js Installation Issues
```bash
# Check Node.js version
node --version
npm --version

# Clear npm cache
npm cache clean --force

# Install with specific version
npm install -g eslint@8.47.0
```

#### Docker Issues
```bash
# Check Docker status
docker --version
docker-compose --version

# Start Docker service (Linux)
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x devsecops/scripts/*.sh

# Fix Python permissions
python3 -m pip install --user --upgrade pip

# Fix npm permissions
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

### Scan Issues

#### Pre-commit Hook Failures
```bash
# Debug pre-commit
pre-commit run --verbose

# Skip hooks temporarily
git commit --no-verify -m "commit message"

# Update hooks
pre-commit autoupdate
```

#### Tool Execution Failures
```bash
# Check tool installation
which bandit
which safety
which trivy

# Run with verbose output
bandit -r backend/ -v
safety check -v
trivy image --debug apartment-accounting-backend:latest
```

#### Memory Issues
```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"

# Run scans with limited memory
ulimit -v 2097152  # 2GB limit
./devsecops/scripts/run-all-scans.sh
```

## 📊 Verification Checklist

After installation, verify the following:

- [ ] All tools installed successfully
- [ ] Pre-commit hooks working
- [ ] Individual scans running
- [ ] Comprehensive scan completing
- [ ] Reports generating correctly
- [ ] CI/CD pipeline working (if applicable)
- [ ] No critical security issues found
- [ ] Documentation accessible

## 🆘 Getting Help

### Self-Help Resources
1. **Tool Documentation**: Each tool has comprehensive documentation
2. **Log Files**: Check scan output and error messages
3. **Configuration Files**: Verify tool configurations
4. **System Requirements**: Ensure all dependencies are met

### Support Channels
1. **Project Issues**: Create an issue in the repository
2. **Tool Communities**: Each tool has its own community support
3. **Security Forums**: OWASP, SANS, and other security communities

### Debugging Steps
1. **Check versions**: Ensure all tools are compatible versions
2. **Review logs**: Look for specific error messages
3. **Test individually**: Run tools one at a time
4. **Check permissions**: Ensure proper file and directory permissions
5. **Verify paths**: Ensure tools are in PATH

## 🎯 Next Steps

After successful setup:

1. **Run regular scans**: Schedule daily/weekly security scans
2. **Review reports**: Analyze security findings and fix issues
3. **Update dependencies**: Keep tools and dependencies current
4. **Customize configuration**: Adjust tool settings for your needs
5. **Train team**: Ensure all developers understand the security pipeline
6. **Monitor CI/CD**: Watch for security failures in the pipeline
7. **Continuous improvement**: Regularly update and enhance the pipeline
