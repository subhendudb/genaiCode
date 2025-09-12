# DevSecOps Tool Matrix for Apartment Accounting Application

## Overview
This document outlines the recommended security tools for implementing a "Shift-Left" security strategy for the Docker-based apartment accounting application.

## Tool Categories and Recommendations

| Category | Tool | Type | Purpose | Priority | Installation | Notes |
|----------|------|------|---------|----------|--------------|-------|
| **Pre-commit Hooks** | pre-commit | Open Source | Framework for managing git hooks | Mandatory | `pip install pre-commit` | Core framework |
| **Pre-commit Hooks** | git-secrets | Open Source | Prevents secrets from being committed | Mandatory | `brew install git-secrets` | AWS secrets detection |
| **Pre-commit Hooks** | detect-secrets | Open Source | Detects secrets in code | High | `pip install detect-secrets` | Multi-provider secret detection |
| **Code Quality - Python** | black | Open Source | Code formatter | Mandatory | `pip install black` | PEP 8 compliance |
| **Code Quality - Python** | flake8 | Open Source | Linter | Mandatory | `pip install flake8` | Style guide enforcement |
| **Code Quality - Python** | isort | Open Source | Import sorter | High | `pip install isort` | Import organization |
| **Code Quality - Python** | mypy | Open Source | Type checker | High | `pip install mypy` | Static type checking |
| **Code Quality - Python** | pylint | Open Source | Linter | Medium | `pip install pylint` | Advanced linting |
| **Code Quality - JavaScript** | ESLint | Open Source | Linter | Mandatory | `npm install -g eslint` | JavaScript linting |
| **Code Quality - JavaScript** | Prettier | Open Source | Formatter | Mandatory | `npm install -g prettier` | Code formatting |
| **Code Quality - JavaScript** | TypeScript | Open Source | Type checker | High | `npm install -g typescript` | Type safety |
| **Code Quality - Docker** | hadolint | Open Source | Dockerfile linter | Mandatory | `brew install hadolint` | Docker best practices |
| **SAST - Python** | bandit | Open Source | Security linter | Mandatory | `pip install bandit` | Python security issues |
| **SAST - Python** | safety | Open Source | Dependency checker | Mandatory | `pip install safety` | Known vulnerabilities |
| **SAST - Python** | semgrep | Open Source | SAST scanner | High | `pip install semgrep` | Multi-language SAST |
| **SAST - JavaScript** | ESLint Security | Open Source | Security rules | Mandatory | `npm install eslint-plugin-security` | JS security patterns |
| **SAST - JavaScript** | semgrep | Open Source | SAST scanner | High | `npm install -g @semgrep/semgrep` | Multi-language SAST |
| **SAST - JavaScript** | Snyk Code | Commercial | Advanced SAST | High | `npm install -g snyk` | Commercial SAST |
| **SCA - Python** | safety | Open Source | Dependency scanner | Mandatory | `pip install safety` | Python dependencies |
| **SCA - Python** | pip-audit | Open Source | Dependency scanner | High | `pip install pip-audit` | Alternative to safety |
| **SCA - JavaScript** | npm audit | Open Source | Built-in scanner | Mandatory | Built-in | Node.js dependencies |
| **SCA - JavaScript** | Snyk | Commercial | Advanced SCA | High | `npm install -g snyk` | Commercial SCA |
| **SCA - JavaScript** | OWASP Dependency Check | Open Source | SCA scanner | Medium | `brew install dependency-check` | OWASP tool |
| **IaC Scanning** | checkov | Open Source | IaC scanner | Mandatory | `pip install checkov` | Multi-cloud IaC |
| **IaC Scanning** | trivy | Open Source | Security scanner | Mandatory | `brew install trivy` | Container & IaC |
| **IaC Scanning** | tfsec | Open Source | Terraform scanner | Medium | `brew install tfsec` | Terraform specific |
| **Container Scanning** | trivy | Open Source | Container scanner | Mandatory | `brew install trivy` | Multi-purpose scanner |
| **Container Scanning** | docker-bench-security | Open Source | CIS benchmark | High | `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker/docker-bench-security` | Docker security |
| **Container Scanning** | Snyk Container | Commercial | Container scanner | High | `npm install -g snyk` | Commercial container scanning |
| **DAST** | OWASP ZAP | Open Source | Web app scanner | Mandatory | `docker run -t owasp/zap2docker-stable` | Automated security testing |
| **DAST** | Burp Suite | Commercial | Web app scanner | High | Commercial license | Professional DAST |
| **DAST** | Nikto | Open Source | Web scanner | Medium | `brew install nikto` | Web server scanner |

## Priority Levels

### Mandatory Tools (Must Have)
- pre-commit (framework)
- black, flake8 (Python formatting/linting)
- ESLint, Prettier (JavaScript formatting/linting)
- hadolint (Dockerfile linting)
- bandit, safety (Python security)
- ESLint Security (JavaScript security)
- npm audit (JavaScript dependencies)
- checkov, trivy (IaC scanning)
- trivy (Container scanning)
- OWASP ZAP (DAST)

### High Priority Tools (Should Have)
- detect-secrets (secret detection)
- isort, mypy (Python quality)
- TypeScript (JavaScript types)
- semgrep (Multi-language SAST)
- pip-audit (Python SCA)
- docker-bench-security (Container security)

### Medium Priority Tools (Nice to Have)
- pylint (Advanced Python linting)
- OWASP Dependency Check (JavaScript SCA)
- tfsec (Terraform specific)
- Nikto (Additional web scanning)

## Commercial Alternatives

### Snyk (Comprehensive Platform)
- **Snyk Code**: Advanced SAST for multiple languages
- **Snyk Open Source**: Enhanced SCA with better vulnerability intelligence
- **Snyk Container**: Container image scanning with runtime analysis
- **Snyk IaC**: Infrastructure as Code scanning

### SonarQube (Code Quality & Security)
- **SonarQube Community**: Open source code quality
- **SonarQube Developer**: Commercial SAST and code quality
- **SonarQube Enterprise**: Full security suite

### Checkmarx (Enterprise SAST)
- **Checkmarx SAST**: Enterprise-grade static analysis
- **Checkmarx SCA**: Software composition analysis
- **Checkmarx IaC**: Infrastructure scanning

### Veracode (Application Security Platform)
- **Veracode SAST**: Static application security testing
- **Veracode SCA**: Software composition analysis
- **Veracode DAST**: Dynamic application security testing

## Integration Strategy

1. **Local Development**: Pre-commit hooks with mandatory tools
2. **CI/CD Pipeline**: All mandatory + high priority tools
3. **Staging Environment**: DAST scanning with OWASP ZAP
4. **Production**: Container scanning before deployment

## Cost Considerations

### Open Source Stack (Free)
- Complete coverage with community tools
- Requires more configuration and maintenance
- Good for small to medium projects

### Commercial Stack (Paid)
- Better vulnerability intelligence
- Easier integration and maintenance
- Recommended for enterprise environments
- Typical cost: $50-200 per developer per month

## Next Steps

1. Install mandatory tools locally
2. Configure pre-commit hooks
3. Set up CI/CD pipeline
4. Implement DAST in staging
5. Monitor and iterate
