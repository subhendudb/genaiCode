#!/bin/bash

# Environment File Security Check Script
# This script checks for security issues in .env files

set -e

ENV_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/devsecops/reports"

# Create reports directory if it doesn't exist
mkdir -p "$REPORTS_DIR"

echo "🔍 Running environment file security checks on: $ENV_FILE"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Environment file not found at $ENV_FILE"
    exit 1
fi

# Initialize counters
SECURITY_ISSUES=0
WARNINGS=0

echo "📋 Checking for security issues..."

# Check for hardcoded secrets
echo "🔐 Checking for hardcoded secrets..."

# Common secret patterns
SECRET_PATTERNS=(
    "password"
    "secret"
    "key"
    "token"
    "api_key"
    "private_key"
    "access_token"
    "refresh_token"
    "jwt_secret"
    "encryption_key"
    "database_password"
    "db_password"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -i "$pattern" "$ENV_FILE" | grep -v "^#" | grep -v "^$"; then
        echo "⚠️  Warning: Potential secret pattern '$pattern' found"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Check for empty values
echo "🔍 Checking for empty values..."
if grep -E "^[A-Z_]+=$" "$ENV_FILE"; then
    echo "⚠️  Warning: Empty environment variables found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for commented secrets
echo "🔍 Checking for commented secrets..."
if grep -E "^#.*(password|secret|key|token)" "$ENV_FILE"; then
    echo "⚠️  Warning: Commented secrets found (remove these)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for weak passwords
echo "🔍 Checking for weak passwords..."
if grep -E "password.*=.*(123|password|admin|root|test)" "$ENV_FILE" -i; then
    echo "❌ Error: Weak passwords detected"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for default values
echo "🔍 Checking for default values..."
DEFAULT_PATTERNS=(
    "admin"
    "root"
    "password"
    "123456"
    "changeme"
    "default"
    "test"
)

for pattern in "${DEFAULT_PATTERNS[@]}"; do
    if grep -i "$pattern" "$ENV_FILE" | grep -v "^#"; then
        echo "⚠️  Warning: Default value '$pattern' found"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Check for file permissions (if file exists)
if [ -f "$ENV_FILE" ]; then
    PERMS=$(stat -f "%OLp" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null || echo "unknown")
    if [ "$PERMS" != "600" ] && [ "$PERMS" != "unknown" ]; then
        echo "⚠️  Warning: .env file should have 600 permissions (current: $PERMS)"
        echo "   Fix with: chmod 600 $ENV_FILE"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check for .env in gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if ! grep -q "\.env" "$PROJECT_ROOT/.gitignore"; then
        echo "⚠️  Warning: .env files should be in .gitignore"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  Warning: No .gitignore file found"
    WARNINGS=$((WARNINGS + 1))
fi

# Generate report
REPORT_FILE="$REPORTS_DIR/env-security-report.txt"
{
    echo "Environment File Security Report"
    echo "================================"
    echo "File: $ENV_FILE"
    echo "Date: $(date)"
    echo ""
    echo "Security Issues: $SECURITY_ISSUES"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Recommendations:"
    echo "1. Use strong, unique passwords"
    echo "2. Store secrets in a secure secret management system"
    echo "3. Set file permissions to 600"
    echo "4. Add .env to .gitignore"
    echo "5. Use environment-specific .env files"
    echo "6. Consider using .env.example for documentation"
} > "$REPORT_FILE"

# Summary
echo ""
echo "📊 Environment File Security Summary:"
echo "====================================="
echo "Security Issues: $SECURITY_ISSUES"
echo "Warnings: $WARNINGS"
echo "Report saved to: $REPORT_FILE"

# Exit with error if critical issues found
if [ $SECURITY_ISSUES -gt 0 ]; then
    echo ""
    echo "❌ Environment file security check failed. Please fix the critical issues above."
    exit 1
else
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  Environment file security check completed with warnings. Please review the recommendations."
    else
        echo "✅ Environment file security check completed successfully"
    fi
    exit 0
fi
