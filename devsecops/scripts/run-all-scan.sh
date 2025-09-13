#!/bin/bash

# run-scan-all.sh - Comprehensive security scanning script
# Includes pre-commit hooks, SAST, SCA, IaC, container, and DAST scanning

set -euo pipefail

# Script version
VERSION="1.0.0"

# Color detection and setup function
setup_colors() {
    if [[ "${NO_COLOR:-false}" == "true" ]] || [[ -n "${NO_COLOR:-}" ]] || [[ -n "${TERM:-}" && "$TERM" == "dumb" ]]; then
        # Colors explicitly disabled or dumb terminal
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        PURPLE=''
        CYAN=''
        NC=''
    elif command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
        # Terminal supports colors (check tput instead of isatty for better compatibility)
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color
    else
        # No color support
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        PURPLE=''
        CYAN=''
        NC=''
    fi
}

# Initialize colors
setup_colors

# Global variables for CLI
SCAN_TYPE="all"
SCAN_DIR=""
OUTPUT_DIR=""
PRE_COMMIT_CONFIG=""
VERBOSE=false
DRY_RUN=false
NO_COLOR=false

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Initialize configuration with defaults
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SCAN_DIR="${PROJECT_ROOT}"
OUTPUT_DIR="${PROJECT_ROOT}/devsecops/reports/${TIMESTAMP}"
PRE_COMMIT_CONFIG="${PROJECT_ROOT}/.pre-commit-config.yaml"
LOG_FILE=""

log_message() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

show_help() {
    cat << EOF
${CYAN}Security Scan Tool v${VERSION}${NC}

${YELLOW}DESCRIPTION:${NC}
    Comprehensive security scanning script that includes pre-commit hooks, 
    SAST, SCA, IaC, container, and DAST scanning capabilities.

${YELLOW}USAGE:${NC}
    $0 [OPTIONS] [SCAN_TYPE] [SCAN_DIR] [OUTPUT_DIR]

${YELLOW}SCAN TYPES:${NC}
    ${GREEN}all${NC}                    Run all available security scans (default)
    ${GREEN}pre-commit${NC}             Run pre-commit hooks and checks
    ${GREEN}sast${NC}                   Run Static Application Security Testing (Semgrep)
    ${GREEN}sca${NC}                    Run Software Composition Analysis (OWASP, pip-audit, npm audit)
    ${GREEN}iac${NC}                    Run Infrastructure as Code scanning (Trivy Config)
    ${GREEN}container${NC}              Run container security scanning (Trivy Container)
    ${GREEN}dast${NC}                   Run Dynamic Application Security Testing (OWASP ZAP)
    ${GREEN}python${NC}                 Run Python-specific security scans (bandit, pip-audit)
    ${GREEN}javascript${NC}             Run JavaScript/Node.js security scans (npm audit, ESLint)
    ${GREEN}docker${NC}                 Run Docker security scans (hadolint, checkov, trivy)

${YELLOW}OPTIONS:${NC}
    ${GREEN}-h, --help${NC}             Show this help message
    ${GREEN}-v, --verbose${NC}          Enable verbose output
    ${GREEN}-d, --dry-run${NC}          Show what would be executed without running
    ${GREEN}-c, --config FILE${NC}      Specify pre-commit config file (default: .pre-commit-config.yaml)
    ${GREEN}-o, --output DIR${NC}       Specify output directory (default: devsecops/reports/TIMESTAMP)
    ${GREEN}--no-color${NC}             Disable colored output
    ${GREEN}--version${NC}              Show version information

${YELLOW}ARGUMENTS:${NC}
    ${GREEN}SCAN_TYPE${NC}              Type of scan to run (see SCAN TYPES above)
    ${GREEN}SCAN_DIR${NC}               Directory to scan (default: project root)
    ${GREEN}OUTPUT_DIR${NC}             Output directory for results (default: devsecops/reports/TIMESTAMP)

${YELLOW}EXAMPLES:${NC}
    ${CYAN}# Run all scans${NC}
    $0

    ${CYAN}# Run only SAST scan${NC}
    $0 sast

    ${CYAN}# Run container scan on specific directory${NC}
    $0 container /path/to/scan /path/to/output

    ${CYAN}# Run Python scans with verbose output${NC}
    $0 -v python

    ${CYAN}# Dry run to see what would be executed${NC}
    $0 -d all

    ${CYAN}# Use custom pre-commit config${NC}
    $0 -c /path/to/config.yaml pre-commit

${YELLOW}AVAILABLE SCANS:${NC}
    ${GREEN}Pre-commit:${NC}            Code quality, formatting, security checks
    ${GREEN}SAST:${NC}                  Static code analysis with Semgrep
    ${GREEN}SCA:${NC}                   Dependency vulnerability scanning
    ${GREEN}IaC:${NC}                   Infrastructure configuration scanning (Trivy Config)
    ${GREEN}Container:${NC}             Docker image and Dockerfile scanning
    ${GREEN}DAST:${NC}                  Dynamic application security testing
    ${GREEN}Python:${NC}                Python-specific security and quality checks
    ${GREEN}JavaScript:${NC}            Node.js/JavaScript security and quality checks
    ${GREEN}Docker:${NC}                Docker-specific security and best practices

${YELLOW}REQUIREMENTS:${NC}
    - pre-commit (required for all scans)
    - semgrep (for SAST scans)
    - trivy (for IaC and container scans)
    - dependency-check or docker (for SCA scans)
    - zap-baseline or docker (for DAST scans)
    - pip-audit (for Python dependency scans)
    - npm (for JavaScript dependency scans)

${YELLOW}OUTPUT:${NC}
    All scan results are saved to the specified output directory with timestamps.
    A comprehensive summary report is generated in Markdown format.

EOF
}

show_version() {
    echo "Security Scan Tool v${VERSION}"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--config)
                PRE_COMMIT_CONFIG="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --no-color)
                NO_COLOR=true
                setup_colors  # Re-setup colors with no-color flag
                shift
                ;;
            --version)
                show_version
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information."
                exit 1
                ;;
            *)
                if [[ -z "$SCAN_TYPE" || "$SCAN_TYPE" == "all" ]]; then
                    SCAN_TYPE="$1"
                elif [[ -z "$SCAN_DIR" || "$SCAN_DIR" == "$PROJECT_ROOT" ]]; then
                    SCAN_DIR="$1"
                elif [[ -z "$OUTPUT_DIR" || "$OUTPUT_DIR" == *"TIMESTAMP"* ]]; then
                    OUTPUT_DIR="$1"
                else
                    log_error "Too many arguments: $1"
                    echo "Use -h or --help for usage information."
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it to continue."
        exit 1
    fi
}

run_pre_commit_scans() {
    log_message "Running pre-commit scans from ${PRE_COMMIT_CONFIG}"
    
    if [ -f "${PRE_COMMIT_CONFIG}" ]; then
        pre-commit run --all-files --verbose | tee -a "${OUTPUT_DIR}/pre-commit-results.txt"
        log_success "Pre-commit scans completed"
    else
        log_warning "Pre-commit config file not found: ${PRE_COMMIT_CONFIG}"
    fi
}

run_semgrep_sast() {
    log_message "Running Semgrep SAST scan"
    
    # Check if semgrep is available
    if command -v semgrep &> /dev/null; then
        # Use specific configs instead of auto to work with metrics off
        semgrep scan \
            --config p/python \
            --config p/javascript \
            --config p/docker \
            --error \
            --json \
            --output "${OUTPUT_DIR}/semgrep-results.json" \
            --metrics off \
            --verbose \
            "${SCAN_DIR}"
        
        # Also generate text output
        semgrep scan --config p/python --config p/javascript --config p/docker --text "${SCAN_DIR}" | tee -a "${OUTPUT_DIR}/semgrep-results.txt"
        
        log_success "Semgrep SAST scan completed"
    else
        log_warning "Semgrep not installed. Skipping SAST scan."
    fi
}

run_owasp_dependency_check() {
    log_message "Running OWASP Dependency Check SCA scan"
    
    # Check if dependency-check is available
    if command -v dependency-check &> /dev/null; then
        dependency-check \
            --project "Security Scan" \
            --scan "${SCAN_DIR}" \
            --out "${OUTPUT_DIR}" \
            --format HTML \
            --format JSON \
            --enableExperimental \
            --log "${OUTPUT_DIR}/dependency-check.log"
        
        log_success "OWASP Dependency Check completed"
    elif command -v docker &> /dev/null; then
        log_message "Running OWASP Dependency Check via Docker"
        docker run --rm \
            -v "${SCAN_DIR}:/src" \
            -v "${OUTPUT_DIR}:/report" \
            owasp/dependency-check:latest \
            --project "Security Scan" \
            --scan /src \
            --out /report \
            --format HTML \
            --format JSON \
            --enableExperimental
        log_success "OWASP Dependency Check (Docker) completed"
    else
        log_warning "OWASP Dependency Check not available. Skipping SCA scan."
    fi
}

run_trivy_iac() {
    log_message "Running Trivy IaC scan"
    
    # Check if trivy is available
    if command -v trivy &> /dev/null; then
        trivy config \
            --format table \
            -o "${OUTPUT_DIR}/trivy-iac-results.txt" \
            "${SCAN_DIR}"
        
        # Also generate JSON output
        trivy config --format json -o "${OUTPUT_DIR}/trivy-iac-results.json" "${SCAN_DIR}"
        
        log_success "Trivy IaC scan completed"
    else
        log_warning "Trivy not installed. Skipping IaC scan."
    fi
}

run_trivy_container() {
    log_message "Running Trivy container scan"
    
    if command -v trivy &> /dev/null; then
        local found_dockerfile=false
        
        # Check for Dockerfiles in various locations
        for dockerfile_path in "${SCAN_DIR}/Dockerfile" "${SCAN_DIR}/backend/Dockerfile" "${SCAN_DIR}/frontend/Dockerfile"; do
            if [ -f "${dockerfile_path}" ]; then
                log_message "Scanning Dockerfile: ${dockerfile_path}"
                
                # Generate filename based on location
                local base_name=$(basename "$(dirname "${dockerfile_path}")")
                local output_prefix="${OUTPUT_DIR}/trivy-container-${base_name}"
                
                trivy config \
                    --format table \
                    -o "${output_prefix}-results.txt" \
                    "${dockerfile_path}"
                
                trivy config --format json -o "${output_prefix}-results.json" "${dockerfile_path}"
                
                found_dockerfile=true
            fi
        done
        
        if [ "$found_dockerfile" = true ]; then
            log_success "Trivy container scan completed"
        else
            log_warning "No Dockerfiles found. Skipping container scan."
        fi
    else
        log_warning "Trivy not installed. Skipping container scan."
    fi
}

run_owasp_zap_dast() {
    log_message "Running OWASP ZAP DAST scan"
    
    # This is a basic example - you'll need to customize for your target
    local target_url="${TARGET_URL:-http://localhost:8000}"
    
    # Check if target is accessible before scanning
    log_message "Checking if target ${target_url} is accessible..."
    if ! curl -s --connect-timeout 10 --max-time 30 "${target_url}" > /dev/null 2>&1; then
        log_error "Target ${target_url} is not accessible. Please ensure the application is running."
        log_message "To start the application, run: docker-compose up -d"
        return 1
    fi
    log_success "Target ${target_url} is accessible"
    
    if command -v zap-baseline &> /dev/null; then
        log_message "Running OWASP ZAP DAST scan with local installation"
        zap-baseline.py \
            -t "${target_url}" \
            -r "${OUTPUT_DIR}/zap-report.html" \
            -w "${OUTPUT_DIR}/zap-report.txt" \
            -J "${OUTPUT_DIR}/zap-report.json" \
            -d \
            -T 10 \
            -m 5
        
        log_success "OWASP ZAP DAST scan completed"
    elif command -v docker &> /dev/null; then
        log_message "Running OWASP ZAP via Docker"
        # Create a temporary directory for ZAP reports
        local temp_dir=$(mktemp -d)
        
        log_message "Starting ZAP scan with timeout of 10 minutes..."
        docker run --rm \
            --network host \
            -v "${temp_dir}:/zap/wrk" \
            ghcr.io/zaproxy/zaproxy:stable \
            zap-baseline.py \
            -t "${target_url}" \
            -r /zap/wrk/zap-report.html \
            -w /zap/wrk/zap-report.txt \
            -J /zap/wrk/zap-report.json \
            -d \
            -T 10 \
            -m 5 \
            --autooff || log_warning "ZAP scan completed with warnings or errors"
        
        # Debug: List all files in temp directory
        log_message "Files in temp directory ${temp_dir}:"
        ls -la "${temp_dir}" || log_warning "Could not list temp directory contents"
        
        # Also check for any subdirectories
        find "${temp_dir}" -type f -name "*zap*" -o -name "*report*" | head -10
        
        # Copy reports to output directory (handle nested structure)
        local reports_copied=0
        
        # Find and copy all report files
        for report_file in $(find "${temp_dir}" -name "*zap-report*" -type f 2>/dev/null); do
            local filename=$(basename "${report_file}")
            cp "${report_file}" "${OUTPUT_DIR}/"
            log_message "Copied ${filename} to ${OUTPUT_DIR}/${filename}"
            reports_copied=$((reports_copied + 1))
        done
        
        # Also try the specific expected locations
        for report_type in html txt json; do
            if [ -f "${temp_dir}/zap-report.${report_type}" ]; then
                cp "${temp_dir}/zap-report.${report_type}" "${OUTPUT_DIR}/"
                log_message "Copied ${report_type} report to ${OUTPUT_DIR}/zap-report.${report_type}"
                reports_copied=$((reports_copied + 1))
            fi
        done
        
        # Clean up temporary directory
        rm -rf "${temp_dir}"
        
        if [ $reports_copied -gt 0 ]; then
            log_success "OWASP ZAP DAST (Docker) completed - ${reports_copied} report(s) generated"
        else
            log_warning "OWASP ZAP DAST (Docker) completed but no reports were found"
        fi
    else
        log_warning "OWASP ZAP not available. Skipping DAST scan."
    fi
}

run_pip_audit() {
    log_message "Running pip-audit for Python dependencies"
    
    if command -v pip-audit &> /dev/null; then
        # Check for Python dependency files in backend directory
        local backend_dir="${SCAN_DIR}/backend"
        local found_deps=false
        
        if [ -f "${backend_dir}/requirements.txt" ] || [ -f "${backend_dir}/pyproject.toml" ] || [ -f "${backend_dir}/setup.py" ]; then
            cd "${backend_dir}"
            pip-audit \
                --format json \
                --output "${OUTPUT_DIR}/pip-audit-results.json" \
                --desc
            
            pip-audit --desc 2>&1 | tee -a "${OUTPUT_DIR}/pip-audit-results.txt"
            cd - > /dev/null
            found_deps=true
        elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
            pip-audit \
                --format json \
                --output "${OUTPUT_DIR}/pip-audit-results.json" \
                --desc
            
            pip-audit --desc 2>&1 | tee -a "${OUTPUT_DIR}/pip-audit-results.txt"
            found_deps=true
        fi
        
        if [ "$found_deps" = true ]; then
            log_success "pip-audit completed"
        else
            log_warning "No Python dependency files found in ${SCAN_DIR} or ${backend_dir}. Skipping pip-audit."
        fi
    else
        log_warning "pip-audit not installed. Skipping Python dependency audit."
    fi
}

run_npm_audit() {
    log_message "Running npm audit for JavaScript dependencies"
    
    if command -v npm &> /dev/null; then
        # Check for package.json in frontend directory
        local frontend_dir="${SCAN_DIR}/frontend"
        if [ -f "${frontend_dir}/package.json" ]; then
            cd "${frontend_dir}"
            npm audit --json > "${OUTPUT_DIR}/npm-audit-results.json"
            npm audit 2>&1 | tee -a "${OUTPUT_DIR}/npm-audit-results.txt"
            cd - > /dev/null
            
            log_success "npm audit completed"
        elif [ -f "${SCAN_DIR}/package.json" ]; then
            cd "${SCAN_DIR}"
            npm audit --json > "${OUTPUT_DIR}/npm-audit-results.json"
            npm audit 2>&1 | tee -a "${OUTPUT_DIR}/npm-audit-results.txt"
            cd - > /dev/null
            
            log_success "npm audit completed"
        else
            log_warning "No package.json found in ${SCAN_DIR} or ${frontend_dir}. Skipping npm audit."
        fi
    else
        log_warning "npm not installed. Skipping JavaScript dependency audit."
    fi
}

# Individual scan functions for CLI
run_pre_commit_scan() {
    log_message "Running pre-commit scan"
    run_pre_commit_scans
}

run_sast_scan() {
    log_message "Running SAST scan"
    run_semgrep_sast
}

run_sca_scan() {
    log_message "Running SCA scan"
    run_owasp_dependency_check
    run_pip_audit
    run_npm_audit
}

run_iac_scan() {
    log_message "Running IaC scan"
    run_trivy_iac
}

run_container_scan() {
    log_message "Running container scan"
    run_trivy_container
}

run_dast_scan() {
    log_message "Running DAST scan"
    run_owasp_zap_dast
}

run_python_scan() {
    log_message "Running Python security scan"
    run_pip_audit
    # Add bandit scan if available
    if command -v bandit &> /dev/null; then
        log_message "Running Bandit Python security scan"
        bandit -r "${SCAN_DIR}" -f json -o "${OUTPUT_DIR}/bandit-results.json" || true
        bandit -r "${SCAN_DIR}" -f txt -o "${OUTPUT_DIR}/bandit-results.txt" || true
        log_success "Bandit scan completed"
    else
        log_warning "Bandit not installed. Skipping Python security scan."
    fi
}

run_javascript_scan() {
    log_message "Running JavaScript security scan"
    run_npm_audit
    # Add ESLint security scan if available
    if command -v eslint &> /dev/null; then
        log_message "Running ESLint security scan"
        local frontend_dir="${SCAN_DIR}/frontend"
        if [ -f "${frontend_dir}/package.json" ]; then
            cd "${frontend_dir}"
            npx eslint . --format json --output-file "${OUTPUT_DIR}/eslint-security-results.json" --config .eslintrc.js || true
            npx eslint . --format stylish --output-file "${OUTPUT_DIR}/eslint-security-results.txt" --config .eslintrc.js || true
            cd - > /dev/null
            log_success "ESLint security scan completed"
        else
            log_warning "No frontend package.json found. Skipping ESLint scan."
        fi
    else
        log_warning "ESLint not available. Skipping JavaScript security scan."
    fi
}

run_docker_scan() {
    log_message "Running Docker security scan"
    run_trivy_container
    # Add hadolint scan if available
    if command -v hadolint &> /dev/null; then
        log_message "Running Hadolint Dockerfile scan"
        for dockerfile_path in "${SCAN_DIR}/Dockerfile" "${SCAN_DIR}/backend/Dockerfile" "${SCAN_DIR}/frontend/Dockerfile"; do
            if [ -f "${dockerfile_path}" ]; then
                local base_name=$(basename "$(dirname "${dockerfile_path}")")
                hadolint "${dockerfile_path}" > "${OUTPUT_DIR}/hadolint-${base_name}-results.txt" 2>&1 || true
                log_message "Hadolint scan completed for ${dockerfile_path}"
            fi
        done
    else
        log_warning "Hadolint not installed. Skipping Dockerfile linting."
    fi
}

show_dry_run() {
    log_message "DRY RUN - The following scans would be executed:"
    echo ""
    
    case "$SCAN_TYPE" in
        "all")
            echo -e "${CYAN}All Security Scans:${NC}"
            echo "  - Pre-commit hooks and checks"
            echo "  - SAST (Semgrep)"
            echo "  - SCA (OWASP Dependency Check, pip-audit, npm audit)"
            echo "  - IaC (Trivy IaC)"
            echo "  - Container (Trivy Container)"
            echo "  - DAST (OWASP ZAP)"
            ;;
        "pre-commit")
            echo -e "${CYAN}Pre-commit Scan:${NC}"
            echo "  - Code quality checks"
            echo "  - Security hooks"
            echo "  - Formatting checks"
            ;;
        "sast")
            echo -e "${CYAN}SAST Scan:${NC}"
            echo "  - Semgrep static analysis"
            ;;
        "sca")
            echo -e "${CYAN}SCA Scan:${NC}"
            echo "  - OWASP Dependency Check"
            echo "  - pip-audit (Python dependencies)"
            echo "  - npm audit (JavaScript dependencies)"
            ;;
        "iac")
            echo -e "${CYAN}IaC Scan:${NC}"
            echo "  - Trivy Config (Infrastructure as Code)"
            ;;
        "container")
            echo -e "${CYAN}Container Scan:${NC}"
            echo "  - Trivy Container scanning"
            ;;
        "dast")
            echo -e "${CYAN}DAST Scan:${NC}"
            echo "  - OWASP ZAP dynamic testing"
            ;;
        "python")
            echo -e "${CYAN}Python Scan:${NC}"
            echo "  - pip-audit (dependency vulnerabilities)"
            echo "  - Bandit (security issues)"
            ;;
        "javascript")
            echo -e "${CYAN}JavaScript Scan:${NC}"
            echo "  - npm audit (dependency vulnerabilities)"
            echo "  - ESLint security rules"
            ;;
        "docker")
            echo -e "${CYAN}Docker Scan:${NC}"
            echo "  - Trivy Container scanning"
            echo "  - Hadolint Dockerfile linting"
            ;;
        *)
            log_error "Unknown scan type: $SCAN_TYPE"
            echo "Use -h or --help for available scan types."
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Scan Directory: ${SCAN_DIR}"
    echo "  Output Directory: ${OUTPUT_DIR}"
    echo "  Pre-commit Config: ${PRE_COMMIT_CONFIG}"
    echo "  Verbose: ${VERBOSE}"
    echo ""
    echo "To run the actual scan, remove the -d or --dry-run flag."
}

generate_summary() {
    log_message "Generating scan summary"
    
    local summary_file="${OUTPUT_DIR}/scan-summary.md"
    
    cat > "${summary_file}" << EOF
# Security Scan Summary
Generated: $(date)
Scan Type: ${SCAN_TYPE}
Scan Directory: ${SCAN_DIR}
Output Directory: ${OUTPUT_DIR}

## Scans Performed

### Pre-commit Scans
- **Status**: $(if [ -f "${OUTPUT_DIR}/pre-commit-results.txt" ]; then echo "Completed"; else echo "Skipped"; fi)

### SAST Scans
- **Semgrep**: $(if [ -f "${OUTPUT_DIR}/semgrep-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)

### SCA Scans
- **OWASP Dependency Check**: $(if [ -f "${OUTPUT_DIR}/dependency-check-report.json" ]; then echo "Completed"; else echo "Skipped"; fi)
- **pip-audit**: $(if [ -f "${OUTPUT_DIR}/pip-audit-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)
- **npm audit**: $(if [ -f "${OUTPUT_DIR}/npm-audit-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)

### IaC Scans
- **Trivy Config**: $(if [ -f "${OUTPUT_DIR}/trivy-iac-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)

### Container Scans
- **Trivy Container**: $(if ls "${OUTPUT_DIR}"/trivy-container-*-results.json 1> /dev/null 2>&1; then echo "Completed"; else echo "Skipped"; fi)

### DAST Scans
- **OWASP ZAP**: $(if [ -f "${OUTPUT_DIR}/zap-report.html" ]; then echo "Completed"; else echo "Skipped"; fi)

### Python Scans
- **Bandit**: $(if [ -f "${OUTPUT_DIR}/bandit-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)

### JavaScript Scans
- **ESLint Security**: $(if [ -f "${OUTPUT_DIR}/eslint-security-results.json" ]; then echo "Completed"; else echo "Skipped"; fi)

### Docker Scans
- **Hadolint**: $(if ls "${OUTPUT_DIR}"/hadolint-*-results.txt 1> /dev/null 2>&1; then echo "Completed"; else echo "Skipped"; fi)

## Next Steps
1. Review all scan reports in ${OUTPUT_DIR}
2. Address critical and high severity vulnerabilities first
3. Consider implementing these scans in your CI/CD pipeline
4. Regularly update dependencies and scanning tools

EOF
    
    log_success "Summary generated: ${summary_file}"
}

main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Set up logging
    LOG_FILE="${OUTPUT_DIR}/scan-all.log"
    
    # Create output directory
    mkdir -p "${OUTPUT_DIR}"
    
    # Handle dry run
    if [ "$DRY_RUN" = true ]; then
        show_dry_run
        exit 0
    fi
    
    # Validate scan directory
    if [ ! -d "${SCAN_DIR}" ]; then
        log_error "Scan directory does not exist: ${SCAN_DIR}"
        exit 1
    fi
    
    # Validate pre-commit config
    if [ ! -f "${PRE_COMMIT_CONFIG}" ]; then
        log_warning "Pre-commit config file not found: ${PRE_COMMIT_CONFIG}"
    fi
    
    log_message "Starting ${SCAN_TYPE} security scan on directory: ${SCAN_DIR}"
    log_message "Output directory: ${OUTPUT_DIR}"
    
    # Check dependencies based on scan type
    case "$SCAN_TYPE" in
        "all")
            check_dependency "pre-commit"
            ;;
        "pre-commit")
            check_dependency "pre-commit"
            ;;
        "sast")
            if ! command -v semgrep &> /dev/null; then
                log_warning "Semgrep not installed. Some SAST scans may be skipped."
            fi
            ;;
        "sca")
            if ! command -v dependency-check &> /dev/null && ! command -v docker &> /dev/null; then
                log_warning "OWASP Dependency Check not available. Some SCA scans may be skipped."
            fi
            ;;
        "iac"|"container")
            if ! command -v trivy &> /dev/null; then
                log_warning "Trivy not installed. Some IaC/Container scans may be skipped."
            fi
            ;;
        "dast")
            if ! command -v zap-baseline &> /dev/null && ! command -v docker &> /dev/null; then
                log_warning "OWASP ZAP not available. DAST scans may be skipped."
            fi
            ;;
        "python")
            if ! command -v pip-audit &> /dev/null; then
                log_warning "pip-audit not installed. Some Python scans may be skipped."
            fi
            ;;
        "javascript")
            if ! command -v npm &> /dev/null; then
                log_warning "npm not installed. JavaScript scans may be skipped."
            fi
            ;;
        "docker")
            if ! command -v trivy &> /dev/null; then
                log_warning "Trivy not installed. Some Docker scans may be skipped."
            fi
            ;;
        *)
            log_error "Unknown scan type: $SCAN_TYPE"
            echo "Use -h or --help for available scan types."
            exit 1
            ;;
    esac
    
    # Run the appropriate scan(s)
    case "$SCAN_TYPE" in
        "all")
            run_pre_commit_scans
            run_semgrep_sast
            run_owasp_dependency_check
            run_trivy_iac
            run_trivy_container
            run_owasp_zap_dast
            run_pip_audit
            run_npm_audit
            ;;
        "pre-commit")
            run_pre_commit_scan
            ;;
        "sast")
            run_sast_scan
            ;;
        "sca")
            run_sca_scan
            ;;
        "iac")
            run_iac_scan
            ;;
        "container")
            run_container_scan
            ;;
        "dast")
            run_dast_scan
            ;;
        "python")
            run_python_scan
            ;;
        "javascript")
            run_javascript_scan
            ;;
        "docker")
            run_docker_scan
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    log_success "${SCAN_TYPE} security scan completed successfully!"
    log_message "Results available in: ${OUTPUT_DIR}"
}

# Handle script interruption
trap 'log_error "Scan interrupted by user"; exit 1' INT

main "$@"