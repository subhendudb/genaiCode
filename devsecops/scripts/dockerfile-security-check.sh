#!/bin/bash

# Dockerfile Security Check Script
# This script performs security checks on Dockerfiles

set -e

DOCKERFILE_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/devsecops/reports"

# Create reports directory if it doesn't exist
mkdir -p "$REPORTS_DIR"

echo "🔍 Running Dockerfile security checks on: $DOCKERFILE_PATH"

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ Error: Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

# Run hadolint for Dockerfile best practices
echo "📋 Running hadolint..."
if command -v hadolint &> /dev/null; then
    hadolint "$DOCKERFILE_PATH" > "$REPORTS_DIR/hadolint-report.txt" 2>&1 || true
    echo "✅ hadolint completed. Report saved to $REPORTS_DIR/hadolint-report.txt"
else
    echo "⚠️  Warning: hadolint not installed. Install with: brew install hadolint"
fi

# Run checkov for security misconfigurations
echo "🔒 Running checkov..."
if command -v checkov &> /dev/null; then
    checkov -f "$DOCKERFILE_PATH" --framework dockerfile \
        --output json --output-file-path "$REPORTS_DIR/checkov-dockerfile-report.json" || true
    checkov -f "$DOCKERFILE_PATH" --framework dockerfile \
        --output cli > "$REPORTS_DIR/checkov-dockerfile-report.txt" 2>&1 || true
    echo "✅ checkov completed. Report saved to $REPORTS_DIR/checkov-dockerfile-report.*"
else
    echo "⚠️  Warning: checkov not installed. Install with: pip install checkov"
fi

# Run trivy for vulnerability scanning
echo "🛡️  Running trivy..."
if command -v trivy &> /dev/null; then
    trivy config "$DOCKERFILE_PATH" --format json --output "$REPORTS_DIR/trivy-dockerfile-report.json" || true
    trivy config "$DOCKERFILE_PATH" --format table > "$REPORTS_DIR/trivy-dockerfile-report.txt" 2>&1 || true
    echo "✅ trivy completed. Report saved to $REPORTS_DIR/trivy-dockerfile-report.*"
else
    echo "⚠️  Warning: trivy not installed. Install with: brew install trivy"
fi

# Custom security checks
echo "🔍 Running custom security checks..."

# Check for common security issues
SECURITY_ISSUES=0

# Check for running as root
if grep -q "USER root" "$DOCKERFILE_PATH"; then
    echo "⚠️  Warning: Dockerfile runs as root user"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for hardcoded secrets
if grep -E "(password|secret|key|token)" "$DOCKERFILE_PATH" | grep -v "#"; then
    echo "⚠️  Warning: Potential hardcoded secrets found"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for latest tag usage
if grep -q ":latest" "$DOCKERFILE_PATH"; then
    echo "⚠️  Warning: Using 'latest' tag is not recommended for production"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for apt-get update without cleanup
if grep -q "apt-get update" "$DOCKERFILE_PATH" && ! grep -q "rm -rf /var/lib/apt/lists/\*" "$DOCKERFILE_PATH"; then
    echo "⚠️  Warning: apt-get update without cleanup increases image size"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for EXPOSE without specific port
if grep -q "EXPOSE" "$DOCKERFILE_PATH" && ! grep -q "EXPOSE [0-9]" "$DOCKERFILE_PATH"; then
    echo "⚠️  Warning: EXPOSE directive should specify port numbers"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Summary
echo ""
echo "📊 Security Check Summary:"
echo "=========================="
if [ $SECURITY_ISSUES -eq 0 ]; then
    echo "✅ No critical security issues found in custom checks"
else
    echo "⚠️  Found $SECURITY_ISSUES potential security issues"
fi

echo ""
echo "📁 Reports generated in: $REPORTS_DIR"
echo "   - hadolint-report.txt"
echo "   - checkov-dockerfile-report.json"
echo "   - checkov-dockerfile-report.txt"
echo "   - trivy-dockerfile-report.json"
echo "   - trivy-dockerfile-report.txt"

# Exit with error if critical issues found
if [ $SECURITY_ISSUES -gt 0 ]; then
    echo ""
    echo "❌ Security check failed. Please review and fix the issues above."
    exit 1
else
    echo ""
    echo "✅ Dockerfile security check completed successfully"
    exit 0
fi
