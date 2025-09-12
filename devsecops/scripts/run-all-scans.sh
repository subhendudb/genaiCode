#!/bin/bash

# Comprehensive Security Scanning Script
# This script runs all security scans for the apartment accounting application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/devsecops/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create reports directory with timestamp
mkdir -p "$REPORTS_DIR/$TIMESTAMP"

echo "🚀 Starting comprehensive security scan for Apartment Accounting Application"
echo "=========================================================================="
echo "Timestamp: $TIMESTAMP"
echo "Reports will be saved to: $REPORTS_DIR/$TIMESTAMP"
echo ""

# Initialize counters
TOTAL_SCANS=0
FAILED_SCANS=0
WARNING_SCANS=0

# Function to run a scan and track results
run_scan() {
    local scan_name="$1"
    local scan_command="$2"
    local scan_type="$3"  # "mandatory", "optional", "warning"
    
    echo "🔍 Running $scan_name..."
    TOTAL_SCANS=$((TOTAL_SCANS + 1))
    
    if eval "$scan_command"; then
        echo "✅ $scan_name completed successfully"
    else
        echo "❌ $scan_name failed"
        if [ "$scan_type" = "mandatory" ]; then
            FAILED_SCANS=$((FAILED_SCANS + 1))
        else
            WARNING_SCANS=$((WARNING_SCANS + 1))
        fi
    fi
    echo ""
}

# Change to project root
cd "$PROJECT_ROOT"

echo "📋 1. CODE QUALITY AND LINTING"
echo "==============================="

# Python code quality
run_scan "Python Black Formatting" "black --check backend/ --diff" "mandatory"
run_scan "Python Flake8 Linting" "flake8 backend/ --count --statistics" "mandatory"
run_scan "Python Import Sorting" "isort backend/ --check-only --diff" "mandatory"
run_scan "Python Type Checking" "mypy backend/ --ignore-missing-imports" "optional"

# JavaScript code quality
run_scan "JavaScript ESLint" "cd frontend && npm run lint 2>/dev/null || eslint src/ --ext .js,.jsx,.ts,.tsx" "mandatory"
run_scan "JavaScript Prettier" "cd frontend && npx prettier --check src/" "mandatory"

# Docker quality
run_scan "Dockerfile Linting" "hadolint backend/Dockerfile frontend/Dockerfile" "mandatory"

echo "🔒 2. STATIC APPLICATION SECURITY TESTING (SAST)"
echo "================================================="

# Python security
run_scan "Python Bandit Security" "bandit -r backend/ -f json -o $REPORTS_DIR/$TIMESTAMP/bandit-report.json" "mandatory"
run_scan "Python Safety Check" "safety check --json --output $REPORTS_DIR/$TIMESTAMP/safety-report.json" "mandatory"

# JavaScript security
run_scan "JavaScript Security ESLint" "cd frontend && npx eslint src/ --ext .js,.jsx,.ts,.tsx --config .eslintrc.js" "mandatory"

# Multi-language SAST with semgrep
if command -v semgrep &> /dev/null; then
    run_scan "Semgrep SAST" "semgrep --config=auto --json --output=$REPORTS_DIR/$TIMESTAMP/semgrep-report.json ." "optional"
else
    echo "⚠️  Semgrep not installed. Install with: pip install semgrep"
fi

echo "📦 3. SOFTWARE COMPOSITION ANALYSIS (SCA)"
echo "=========================================="

# Python dependencies
run_scan "Python Safety SCA" "safety check --json --output $REPORTS_DIR/$TIMESTAMP/safety-sca-report.json" "mandatory"
run_scan "Python pip-audit" "pip-audit --format=json --output=$REPORTS_DIR/$TIMESTAMP/pip-audit-report.json" "optional"

# JavaScript dependencies
run_scan "JavaScript npm audit" "cd frontend && npm audit --json > $REPORTS_DIR/$TIMESTAMP/npm-audit-report.json" "mandatory"

# OWASP Dependency Check
if command -v dependency-check &> /dev/null; then
    run_scan "OWASP Dependency Check" "dependency-check --project apartment-accounting --scan . --format JSON --out $REPORTS_DIR/$TIMESTAMP/owasp-dependency-check-report.json" "optional"
else
    echo "⚠️  OWASP Dependency Check not installed. Install with: brew install dependency-check"
fi

echo "🏗️  4. INFRASTRUCTURE AS CODE (IaC) SCANNING"
echo "============================================="

# Docker and Docker Compose scanning
run_scan "Checkov IaC Scan" "checkov -f docker-compose.yml --framework docker_compose --output json --output-file-path $REPORTS_DIR/$TIMESTAMP/checkov-docker-compose-report.json" "mandatory"
run_scan "Checkov Dockerfile Scan" "checkov -f backend/Dockerfile frontend/Dockerfile --framework dockerfile --output json --output-file-path $REPORTS_DIR/$TIMESTAMP/checkov-dockerfile-report.json" "mandatory"

# Trivy IaC scanning
if command -v trivy &> /dev/null; then
    run_scan "Trivy IaC Scan" "trivy config . --format json --output $REPORTS_DIR/$TIMESTAMP/trivy-iac-report.json" "mandatory"
else
    echo "⚠️  Trivy not installed. Install with: brew install trivy"
fi

echo "🐳 5. CONTAINER SCANNING"
echo "========================"

# Build images for scanning (if not already built)
echo "🔨 Building Docker images for scanning..."
docker build -t apartment-accounting-backend:scan backend/ || echo "⚠️  Failed to build backend image"
docker build -t apartment-accounting-frontend:scan frontend/ || echo "⚠️  Failed to build frontend image"

# Trivy container scanning
if command -v trivy &> /dev/null; then
    run_scan "Trivy Backend Container Scan" "trivy image --format json --output $REPORTS_DIR/$TIMESTAMP/trivy-backend-container-report.json apartment-accounting-backend:scan" "mandatory"
    run_scan "Trivy Frontend Container Scan" "trivy image --format json --output $REPORTS_DIR/$TIMESTAMP/trivy-frontend-container-report.json apartment-accounting-frontend:scan" "mandatory"
else
    echo "⚠️  Trivy not installed. Install with: brew install trivy"
fi

# Docker Bench Security
if docker images | grep -q "docker/docker-bench-security"; then
    run_scan "Docker Bench Security" "docker run --rm --net host --pid host --userns host --cap-add audit_control -v /etc:/etc:ro -v /usr/lib/:/usr/lib:ro -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro -v /usr/share/docker-bench-security:/usr/share/docker-bench-security:ro --label docker_bench_security docker/docker-bench-security > $REPORTS_DIR/$TIMESTAMP/docker-bench-security-report.txt" "optional"
else
    echo "⚠️  Docker Bench Security not available. Pull with: docker pull docker/docker-bench-security"
fi

echo "🌐 6. DYNAMIC APPLICATION SECURITY TESTING (DAST)"
echo "================================================="

# Start the application for DAST testing
echo "🚀 Starting application for DAST testing..."
docker-compose up -d postgres
sleep 10
docker-compose up -d backend frontend
sleep 15

# OWASP ZAP DAST
if command -v zap-baseline.py &> /dev/null || docker images | grep -q "owasp/zap2docker-stable"; then
    echo "🔍 Running OWASP ZAP DAST scan..."
    if command -v zap-baseline.py &> /dev/null; then
        run_scan "OWASP ZAP DAST" "zap-baseline.py -t http://localhost:8000 -J $REPORTS_DIR/$TIMESTAMP/zap-dast-report.json" "mandatory"
    else
        run_scan "OWASP ZAP DAST (Docker)" "docker run -t owasp/zap2docker-stable zap-baseline.py -t http://host.docker.internal:8000 -J /zap/wrk/zap-dast-report.json && docker cp \$(docker ps -lq):/zap/wrk/zap-dast-report.json $REPORTS_DIR/$TIMESTAMP/" "mandatory"
    fi
else
    echo "⚠️  OWASP ZAP not available. Install with: pip install zapcli or use Docker"
fi

# Stop the application
echo "🛑 Stopping application..."
docker-compose down

echo "📊 7. GENERATING COMPREHENSIVE REPORT"
echo "====================================="

# Generate summary report
SUMMARY_REPORT="$REPORTS_DIR/$TIMESTAMP/security-scan-summary.md"
{
    echo "# Security Scan Summary Report"
    echo "Generated: $(date)"
    echo "Project: Apartment Accounting Application"
    echo ""
    echo "## Scan Results"
    echo "- Total Scans: $TOTAL_SCANS"
    echo "- Failed Scans: $FAILED_SCANS"
    echo "- Warning Scans: $WARNING_SCANS"
    echo "- Success Rate: $(( (TOTAL_SCANS - FAILED_SCANS) * 100 / TOTAL_SCANS ))%"
    echo ""
    echo "## Scan Categories"
    echo "1. ✅ Code Quality and Linting"
    echo "2. 🔒 Static Application Security Testing (SAST)"
    echo "3. 📦 Software Composition Analysis (SCA)"
    echo "4. 🏗️ Infrastructure as Code (IaC) Scanning"
    echo "5. 🐳 Container Scanning"
    echo "6. 🌐 Dynamic Application Security Testing (DAST)"
    echo ""
    echo "## Reports Generated"
    echo "All detailed reports are available in: $REPORTS_DIR/$TIMESTAMP/"
    echo ""
    echo "## Recommendations"
    if [ $FAILED_SCANS -gt 0 ]; then
        echo "❌ **CRITICAL**: $FAILED_SCANS mandatory scans failed. Please fix these issues immediately."
    fi
    if [ $WARNING_SCANS -gt 0 ]; then
        echo "⚠️  **WARNING**: $WARNING_SCANS optional scans failed. Consider addressing these issues."
    fi
    if [ $FAILED_SCANS -eq 0 ] && [ $WARNING_SCANS -eq 0 ]; then
        echo "✅ **SUCCESS**: All scans completed successfully!"
    fi
    echo ""
    echo "## Next Steps"
    echo "1. Review all generated reports"
    echo "2. Fix critical security issues"
    echo "3. Address warnings and recommendations"
    echo "4. Integrate these scans into CI/CD pipeline"
    echo "5. Schedule regular security scans"
} > "$SUMMARY_REPORT"

echo "📋 Final Summary"
echo "================"
echo "Total Scans: $TOTAL_SCANS"
echo "Failed Scans: $FAILED_SCANS"
echo "Warning Scans: $WARNING_SCANS"
echo "Success Rate: $(( (TOTAL_SCANS - FAILED_SCANS) * 100 / TOTAL_SCANS ))%"
echo ""
echo "📁 All reports saved to: $REPORTS_DIR/$TIMESTAMP/"
echo "📄 Summary report: $SUMMARY_REPORT"

# Exit with error if mandatory scans failed
if [ $FAILED_SCANS -gt 0 ]; then
    echo ""
    echo "❌ Security scan failed. $FAILED_SCANS mandatory scans failed."
    echo "   Please review the reports and fix the critical issues."
    exit 1
else
    echo ""
    echo "✅ Security scan completed successfully!"
    if [ $WARNING_SCANS -gt 0 ]; then
        echo "   ⚠️  $WARNING_SCANS optional scans had warnings. Consider addressing these."
    fi
    exit 0
fi
