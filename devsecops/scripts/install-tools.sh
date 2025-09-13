#!/bin/bash

# DevSecOps Tools Installation Script
# This script installs all required security tools for the apartment accounting application

set -e

echo "🚀 Installing DevSecOps Security Tools"
echo "======================================"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install tool with error handling
install_tool() {
    local tool_name="$1"
    local install_command="$2"
    local check_command="$3"
    
    echo "📦 Installing $tool_name..."
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo "✅ $tool_name is already installed"
        return 0
    fi
    
    if eval "$install_command"; then
        echo "✅ $tool_name installed successfully"
    else
        echo "❌ Failed to install $tool_name"
        return 1
    fi
}

# Detect operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PACKAGE_MANAGER="brew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if command_exists apt-get; then
        PACKAGE_MANAGER="apt"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    else
        echo "❌ Unsupported Linux package manager"
        exit 1
    fi
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "🖥️  Detected OS: $OS"
echo "📦 Package Manager: $PACKAGE_MANAGER"
echo ""

# Update package manager
echo "🔄 Updating package manager..."
if [ "$PACKAGE_MANAGER" = "brew" ]; then
    brew update
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo apt-get update
elif [ "$PACKAGE_MANAGER" = "yum" ] || [ "$PACKAGE_MANAGER" = "dnf" ]; then
    sudo $PACKAGE_MANAGER update
fi

echo ""

# Install system dependencies
echo "📋 Installing system dependencies..."

if [ "$PACKAGE_MANAGER" = "brew" ]; then
    install_tool "Git" "brew install git" "git --version"
    install_tool "Python 3" "brew install python@3.11" "python3 --version"
    install_tool "Node.js" "brew install node" "node --version"
    install_tool "Docker" "brew install --cask docker" "docker --version"
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    install_tool "Git" "sudo apt-get install -y git" "git --version"
    install_tool "Python 3" "sudo apt-get install -y python3 python3-pip" "python3 --version"
    install_tool "Node.js" "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs" "node --version"
    install_tool "Docker" "sudo apt-get install -y docker.io" "docker --version"
elif [ "$PACKAGE_MANAGER" = "yum" ] || [ "$PACKAGE_MANAGER" = "dnf" ]; then
    install_tool "Git" "sudo $PACKAGE_MANAGER install -y git" "git --version"
    install_tool "Python 3" "sudo $PACKAGE_MANAGER install -y python3 python3-pip" "python3 --version"
    install_tool "Node.js" "curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - && sudo $PACKAGE_MANAGER install -y nodejs" "node --version"
    install_tool "Docker" "sudo $PACKAGE_MANAGER install -y docker" "docker --version"
fi

echo ""

# Install Python security tools
echo "🐍 Installing Python security tools..."

# Upgrade pip first
python3 -m pip install --upgrade pip

# Core Python tools
install_tool "pre-commit" "python3 -m pip install pre-commit" "pre-commit --version"
install_tool "black" "python3 -m pip install black" "black --version"
install_tool "flake8" "python3 -m pip install flake8" "flake8 --version"
install_tool "isort" "python3 -m pip install isort" "isort --version"
install_tool "mypy" "python3 -m pip install mypy" "mypy --version"
install_tool "pylint" "python3 -m pip install pylint" "pylint --version"

# Python security tools
install_tool "bandit" "python3 -m pip install bandit" "bandit --version"
install_tool "safety" "python3 -m pip install safety" "safety --version"
install_tool "pip-audit" "python3 -m pip install pip-audit" "pip-audit --version"
install_tool "detect-secrets" "python3 -m pip install detect-secrets" "detect-secrets --version"

# SAST and IaC tools
install_tool "semgrep" "python3 -m pip install semgrep" "semgrep --version"
install_tool "checkov" "python3 -m pip install checkov" "checkov --version"

echo ""

# Install Node.js security tools
echo "📦 Installing Node.js security tools..."

# Global npm tools
install_tool "ESLint" "npm install -g eslint" "eslint --version"
install_tool "Prettier" "npm install -g prettier" "prettier --version"
install_tool "TypeScript" "npm install -g typescript" "tsc --version"

# Security tools
install_tool "Snyk" "npm install -g snyk" "snyk --version"

echo ""

# Install system security tools
echo "🔧 Installing system security tools..."

if [ "$PACKAGE_MANAGER" = "brew" ]; then
    install_tool "hadolint" "brew install hadolint" "hadolint --version"
    install_tool "trivy" "brew install trivy" "trivy --version"
    install_tool "git-secrets" "brew install git-secrets" "git-secrets --version"
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    install_tool "hadolint" "sudo apt-get install -y hadolint" "hadolint --version"
    install_tool "trivy" "wget -qO- https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - && echo 'deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main' | sudo tee -a /etc/apt/sources.list.d/trivy.list && sudo apt-get update && sudo apt-get install -y trivy" "trivy --version"
    install_tool "git-secrets" "sudo apt-get install -y git-secrets" "git-secrets --version"
elif [ "$PACKAGE_MANAGER" = "yum" ] || [ "$PACKAGE_MANAGER" = "dnf" ]; then
    install_tool "hadolint" "sudo $PACKAGE_MANAGER install -y hadolint" "hadolint --version"
    install_tool "trivy" "sudo $PACKAGE_MANAGER install -y trivy" "trivy --version"
    install_tool "git-secrets" "sudo $PACKAGE_MANAGER install -y git-secrets" "git-secrets --version"
fi

echo ""

# Install OWASP tools
echo "🛡️  Installing OWASP security tools..."

# OWASP Dependency Check
if [ "$PACKAGE_MANAGER" = "brew" ]; then
    install_tool "OWASP Dependency Check" "brew install dependency-check" "dependency-check --version"
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    install_tool "OWASP Dependency Check" "wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip && unzip dependency-check-8.4.0-release.zip && sudo mv dependency-check /opt/ && sudo ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check" "dependency-check --version"
fi

# OWASP ZAP
install_tool "OWASP ZAP" "python3 -m pip install zapcli" "zap-baseline.py --help"

echo ""

# Install Docker security tools
echo "🐳 Installing Docker security tools..."

# Docker Bench Security
echo "📦 Pulling Docker Bench Security image..."
docker pull docker/docker-bench-security || echo "⚠️  Failed to pull Docker Bench Security image"

# OWASP ZAP Docker image
echo "📦 Pulling OWASP ZAP Docker image..."
docker pull ghcr.io/zaproxy/zaproxy:stable || echo "⚠️  Failed to pull OWASP ZAP Docker image"

echo ""

# Set up git hooks
echo "🔧 Setting up git hooks..."

# Initialize git-secrets
if command_exists git-secrets; then
    git secrets --install
    git secrets --register-aws
    echo "✅ git-secrets configured"
else
    echo "⚠️  git-secrets not available"
fi

# Initialize detect-secrets baseline
if command_exists detect-secrets; then
    detect-secrets scan --baseline .secrets.baseline
    echo "✅ detect-secrets baseline created"
else
    echo "⚠️  detect-secrets not available"
fi

echo ""

# Install pre-commit hooks
echo "🪝 Installing pre-commit hooks..."
if command_exists pre-commit; then
    pre-commit install
    echo "✅ pre-commit hooks installed"
else
    echo "⚠️  pre-commit not available"
fi

echo ""

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
if [ -f "package.json" ]; then
    npm install
    echo "✅ Frontend dependencies installed"
else
    echo "⚠️  No package.json found in frontend directory"
fi
cd ..

echo ""

# Install backend dependencies
echo "🐍 Installing backend dependencies..."
cd backend
if [ -f "requirements.txt" ]; then
    python3 -m pip install -r requirements.txt
    echo "✅ Backend dependencies installed"
else
    echo "⚠️  No requirements.txt found in backend directory"
fi
cd ..

echo ""

# Final verification
echo "🔍 Verifying installations..."
echo "============================="

# List of critical tools to verify
CRITICAL_TOOLS=(
    "pre-commit"
    "black"
    "flake8"
    "bandit"
    "safety"
    "eslint"
    "prettier"
    "hadolint"
    "checkov"
    "trivy"
)

MISSING_TOOLS=0

for tool in "${CRITICAL_TOOLS[@]}"; do
    if command_exists "$tool"; then
        echo "✅ $tool"
    else
        echo "❌ $tool (MISSING)"
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    fi
done

echo ""

# Summary
echo "📊 Installation Summary"
echo "======================="
echo "Critical tools missing: $MISSING_TOOLS"

if [ $MISSING_TOOLS -eq 0 ]; then
    echo "✅ All critical tools installed successfully!"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Run: ./devsecops/scripts/run-all-scans.sh"
    echo "2. Review the generated reports"
    echo "3. Fix any security issues found"
    echo "4. Integrate into your CI/CD pipeline"
else
    echo "❌ Some critical tools are missing. Please install them manually."
    echo ""
    echo "🔧 Manual installation commands:"
    echo "pip install pre-commit black flake8 bandit safety"
    echo "npm install -g eslint prettier"
    echo "brew install hadolint checkov trivy"
fi

echo ""
echo "📚 Documentation available in: devsecops/docs/"
echo "🔧 Scripts available in: devsecops/scripts/"
echo "📊 Reports will be saved to: devsecops/reports/"
