#!/bin/bash

# Secrets Scan Script
# This script scans for secrets and sensitive information in code files

set -e

FILE_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/devsecops/reports"

# Create reports directory if it doesn't exist
mkdir -p "$REPORTS_DIR"

echo "🔍 Running secrets scan on: $FILE_PATH"

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Error: File not found at $FILE_PATH"
    exit 1
fi

# Initialize counters
SECRETS_FOUND=0
WARNINGS=0

echo "📋 Scanning for secrets and sensitive information..."

# Common secret patterns
SECRET_PATTERNS=(
    # API Keys
    "api[_-]?key"
    "apikey"
    "access[_-]?key"
    "secret[_-]?key"
    
    # Passwords
    "password"
    "passwd"
    "pwd"
    
    # Tokens
    "token"
    "access[_-]?token"
    "refresh[_-]?token"
    "bearer[_-]?token"
    "jwt[_-]?token"
    
    # Database credentials
    "database[_-]?password"
    "db[_-]?password"
    "mysql[_-]?password"
    "postgres[_-]?password"
    "mongo[_-]?password"
    
    # AWS credentials
    "aws[_-]?access[_-]?key"
    "aws[_-]?secret[_-]?key"
    "aws[_-]?session[_-]?token"
    
    # Private keys
    "private[_-]?key"
    "rsa[_-]?key"
    "ssh[_-]?key"
    
    # OAuth
    "client[_-]?secret"
    "oauth[_-]?secret"
    
    # Encryption
    "encryption[_-]?key"
    "cipher[_-]?key"
    "crypto[_-]?key"
)

# High-risk patterns (should never be in code)
HIGH_RISK_PATTERNS=(
    "BEGIN.*PRIVATE.*KEY"
    "BEGIN.*RSA.*PRIVATE.*KEY"
    "BEGIN.*DSA.*PRIVATE.*KEY"
    "BEGIN.*EC.*PRIVATE.*KEY"
    "-----BEGIN"
    "-----END"
    "sk_live_"
    "pk_live_"
    "sk_test_"
    "pk_test_"
    "AIza[0-9A-Za-z_-]{35}"
    "AKIA[0-9A-Z]{16}"
    "ya29\.[0-9A-Za-z_-]+"
)

# Check for high-risk patterns
echo "🚨 Checking for high-risk patterns..."
for pattern in "${HIGH_RISK_PATTERNS[@]}"; do
    if grep -E "$pattern" "$FILE_PATH" 2>/dev/null; then
        echo "❌ CRITICAL: High-risk pattern '$pattern' found"
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    fi
done

# Check for secret patterns
echo "🔍 Checking for secret patterns..."
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -iE "$pattern" "$FILE_PATH" 2>/dev/null | grep -v "^#" | grep -v "^//" | grep -v "^/\*" | grep -v "^\*"; then
        echo "⚠️  Warning: Potential secret pattern '$pattern' found"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Check for hardcoded URLs with credentials
echo "🔍 Checking for hardcoded URLs with credentials..."
if grep -E "https?://[^:]+:[^@]+@" "$FILE_PATH" 2>/dev/null; then
    echo "❌ CRITICAL: Hardcoded credentials in URL found"
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# Check for base64 encoded secrets (common pattern)
echo "🔍 Checking for base64 encoded secrets..."
if grep -E "[A-Za-z0-9+/]{40,}={0,2}" "$FILE_PATH" 2>/dev/null | grep -v "^#" | grep -v "^//" | grep -v "^/\*"; then
    echo "⚠️  Warning: Potential base64 encoded secret found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for JWT tokens (common pattern)
echo "🔍 Checking for JWT tokens..."
if grep -E "eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*" "$FILE_PATH" 2>/dev/null; then
    echo "⚠️  Warning: Potential JWT token found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for credit card patterns
echo "🔍 Checking for credit card patterns..."
if grep -E "[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}" "$FILE_PATH" 2>/dev/null; then
    echo "❌ CRITICAL: Potential credit card number found"
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# Check for SSN patterns (US)
echo "🔍 Checking for SSN patterns..."
if grep -E "[0-9]{3}-[0-9]{2}-[0-9]{4}" "$FILE_PATH" 2>/dev/null; then
    echo "❌ CRITICAL: Potential SSN found"
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# Check for email addresses (might contain sensitive info)
echo "🔍 Checking for email addresses..."
if grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$FILE_PATH" 2>/dev/null | grep -v "^#" | grep -v "^//" | grep -v "^/\*"; then
    echo "⚠️  Warning: Email addresses found (review for sensitivity)"
    WARNINGS=$((WARNINGS + 1))
fi

# Generate detailed report
REPORT_FILE="$REPORTS_DIR/secrets-scan-report.txt"
{
    echo "Secrets Scan Report"
    echo "==================="
    echo "File: $FILE_PATH"
    echo "Date: $(date)"
    echo ""
    echo "Critical Issues: $SECRETS_FOUND"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Recommendations:"
    echo "1. Never commit secrets to version control"
    echo "2. Use environment variables for sensitive data"
    echo "3. Use a secret management system (e.g., HashiCorp Vault, AWS Secrets Manager)"
    echo "4. Implement pre-commit hooks to prevent secret commits"
    echo "5. Use .gitignore to exclude sensitive files"
    echo "6. Regular security training for developers"
    echo ""
    echo "If secrets were found:"
    echo "1. Immediately rotate/revoke the exposed secrets"
    echo "2. Remove the secrets from git history"
    echo "3. Audit access logs for the exposed secrets"
    echo "4. Update security policies and training"
} > "$REPORT_FILE"

# Summary
echo ""
echo "📊 Secrets Scan Summary:"
echo "========================"
echo "Critical Issues: $SECRETS_FOUND"
echo "Warnings: $WARNINGS"
echo "Report saved to: $REPORT_FILE"

# Exit with error if critical issues found
if [ $SECRETS_FOUND -gt 0 ]; then
    echo ""
    echo "❌ Secrets scan failed. Critical security issues found!"
    echo "   Please remove secrets from the code and rotate any exposed credentials."
    exit 1
else
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  Secrets scan completed with warnings. Please review the findings."
    else
        echo "✅ Secrets scan completed successfully - no issues found"
    fi
    exit 0
fi
