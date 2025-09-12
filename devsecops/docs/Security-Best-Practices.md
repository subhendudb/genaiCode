# Security Best Practices

This document outlines security best practices for the Apartment Accounting Application and the DevSecOps pipeline implementation.

## 🎯 Security Principles

### 1. Defense in Depth
- **Multiple layers** of security controls
- **Fail-safe defaults** - secure by default
- **Least privilege** - minimum necessary access
- **Separation of concerns** - isolate components

### 2. Shift-Left Security
- **Early detection** - catch issues in development
- **Prevention over detection** - stop issues at the source
- **Developer education** - security awareness training
- **Automated security** - consistent security checks

### 3. Continuous Security
- **Regular scanning** - ongoing security assessment
- **Threat modeling** - understand attack vectors
- **Incident response** - prepared for security events
- **Security monitoring** - real-time threat detection

## 🔒 Application Security

### 1. Authentication & Authorization

#### Strong Authentication
```python
# Use strong password hashing
import bcrypt

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt)

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
```

#### JWT Security
```python
# Secure JWT implementation
import jwt
from datetime import datetime, timedelta

def create_token(user_id: str) -> str:
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=1),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception('Token expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')
```

#### Session Management
```python
# Secure session configuration
app.config.update(
    SESSION_COOKIE_SECURE=True,  # HTTPS only
    SESSION_COOKIE_HTTPONLY=True,  # No JavaScript access
    SESSION_COOKIE_SAMESITE='Lax',  # CSRF protection
    PERMANENT_SESSION_LIFETIME=timedelta(hours=1)
)
```

### 2. Input Validation & Sanitization

#### Python Input Validation
```python
from pydantic import BaseModel, validator
import re

class UserInput(BaseModel):
    username: str
    email: str
    password: str
    
    @validator('username')
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_]{3,20}$', v):
            raise ValueError('Invalid username format')
        return v
    
    @validator('email')
    def validate_email(cls, v):
        if not re.match(r'^[^@]+@[^@]+\.[^@]+$', v):
            raise ValueError('Invalid email format')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password too short')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain digit')
        return v
```

#### JavaScript Input Validation
```javascript
// Client-side validation
function validateInput(input) {
    // Sanitize HTML
    const sanitized = input.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    
    // Validate length
    if (sanitized.length > 1000) {
        throw new Error('Input too long');
    }
    
    // Check for SQL injection patterns
    const sqlPattern = /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER)\b)/i;
    if (sqlPattern.test(sanitized)) {
        throw new Error('Invalid input detected');
    }
    
    return sanitized;
}
```

### 3. Database Security

#### SQL Injection Prevention
```python
# Use parameterized queries
def get_user_by_id(user_id: int):
    query = "SELECT * FROM users WHERE id = %s"
    return db.execute(query, (user_id,))

# Use ORM methods
def get_user_by_id(user_id: int):
    return User.query.filter_by(id=user_id).first()
```

#### Database Connection Security
```python
# Secure database configuration
DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'port': int(os.getenv('DB_PORT', 5432)),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'sslmode': 'require',  # Force SSL
    'connect_timeout': 10,
    'application_name': 'apartment-accounting'
}
```

### 4. API Security

#### Rate Limiting
```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    # Login logic
    pass
```

#### CORS Configuration
```python
from flask_cors import CORS

CORS(app, resources={
    r"/api/*": {
        "origins": ["https://yourdomain.com"],
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

#### API Input Validation
```python
from marshmallow import Schema, fields, validate

class TransactionSchema(Schema):
    amount = fields.Decimal(required=True, validate=validate.Range(min=0.01))
    description = fields.Str(required=True, validate=validate.Length(max=255))
    category = fields.Str(required=True, validate=validate.OneOf(['income', 'expense']))
    date = fields.Date(required=True)
```

## 🐳 Container Security

### 1. Dockerfile Security

#### Use Official Images
```dockerfile
# Use specific versions, not latest
FROM python:3.11-slim

# Use non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

#### Minimize Attack Surface
```dockerfile
# Remove unnecessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Don't install development tools in production
# Use multi-stage builds
```

#### Security Scanning
```dockerfile
# Add security labels
LABEL security.scan="true"
LABEL security.level="high"

# Use health checks
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
```

### 2. Container Runtime Security

#### Resource Limits
```yaml
# docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

#### Security Context
```yaml
# Kubernetes security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### 3. Image Security

#### Regular Updates
```bash
# Update base images regularly
docker pull python:3.11-slim
docker pull node:18-alpine

# Scan images for vulnerabilities
trivy image apartment-accounting-backend:latest
```

#### Image Signing
```bash
# Sign images with Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push apartment-accounting-backend:latest
```

## 🔐 Infrastructure Security

### 1. Network Security

#### Firewall Rules
```bash
# UFW firewall configuration
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

#### Network Segmentation
```yaml
# Docker network isolation
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
  database:
    driver: bridge
```

### 2. Secrets Management

#### Environment Variables
```bash
# Use .env files for development
# Never commit .env files
echo ".env" >> .gitignore

# Use secret management in production
# AWS Secrets Manager, HashiCorp Vault, etc.
```

#### Docker Secrets
```yaml
# docker-compose.yml
services:
  backend:
    secrets:
      - db_password
      - jwt_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### 3. Monitoring & Logging

#### Security Logging
```python
import logging
from pythonjsonlogger import jsonlogger

# Configure security logging
security_logger = logging.getLogger('security')
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
handler.setFormatter(formatter)
security_logger.addHandler(handler)
security_logger.setLevel(logging.INFO)

# Log security events
def log_security_event(event_type, user_id, details):
    security_logger.info({
        'event_type': event_type,
        'user_id': user_id,
        'timestamp': datetime.utcnow().isoformat(),
        'details': details
    })
```

#### Audit Trail
```python
# Database audit logging
class AuditLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    action = db.Column(db.String(100), nullable=False)
    resource = db.Column(db.String(100), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.String(500))
```

## 🛡️ DevSecOps Pipeline Security

### 1. Pipeline Security

#### Secure Pipeline Configuration
```yaml
# Use encrypted secrets
env:
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}

# Restrict pipeline access
permissions:
  contents: read
  security-events: write
```

#### Pipeline Validation
```bash
# Validate pipeline configuration
yamllint .github/workflows/
checkov -f .github/workflows/security-pipeline.yml
```

### 2. Tool Security

#### Tool Verification
```bash
# Verify tool checksums
wget -O trivy https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.45.0_Linux-64bit.tar.gz
echo "expected_checksum  trivy" | sha256sum -c
```

#### Tool Updates
```bash
# Regular tool updates
pip install --upgrade bandit safety checkov
npm update -g eslint prettier
```

### 3. Report Security

#### Secure Report Storage
```yaml
# Encrypt sensitive reports
- name: Encrypt Security Reports
  run: |
    gpg --symmetric --cipher-algo AES256 security-report.json
    rm security-report.json
```

#### Access Control
```yaml
# Restrict report access
permissions:
  contents: read
  security-events: write
  actions: read
```

## 🚨 Incident Response

### 1. Security Incident Plan

#### Incident Classification
- **Critical**: Data breach, system compromise
- **High**: Vulnerability exploitation, unauthorized access
- **Medium**: Security misconfiguration, policy violation
- **Low**: Security warning, minor issue

#### Response Procedures
1. **Detection**: Automated monitoring and alerting
2. **Assessment**: Determine scope and impact
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat and vulnerabilities
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Document and improve

### 2. Communication Plan

#### Internal Communication
- **Security Team**: Immediate notification
- **Development Team**: Technical details and fixes
- **Management**: Business impact and timeline
- **Legal/Compliance**: Regulatory requirements

#### External Communication
- **Customers**: If data affected
- **Regulators**: If required by law
- **Partners**: If systems shared
- **Public**: If necessary for transparency

## 📚 Security Training

### 1. Developer Training

#### Security Awareness
- **OWASP Top 10**: Common vulnerabilities
- **Secure Coding**: Best practices
- **Threat Modeling**: Risk assessment
- **Incident Response**: What to do when issues occur

#### Hands-on Training
- **Security Tools**: How to use scanning tools
- **Code Review**: Security-focused reviews
- **Testing**: Security testing techniques
- **Documentation**: Security documentation

### 2. Regular Updates

#### Monthly Security Briefings
- **New Threats**: Emerging security threats
- **Tool Updates**: New security tools and features
- **Policy Changes**: Updated security policies
- **Lessons Learned**: Recent security incidents

#### Quarterly Security Reviews
- **Security Metrics**: Track security KPIs
- **Tool Effectiveness**: Evaluate security tools
- **Process Improvement**: Enhance security processes
- **Training Needs**: Identify additional training

## 🔍 Security Monitoring

### 1. Continuous Monitoring

#### Automated Monitoring
- **Vulnerability Scanning**: Regular vulnerability assessments
- **Dependency Scanning**: Monitor for vulnerable dependencies
- **Container Scanning**: Scan container images
- **Code Scanning**: Static and dynamic analysis

#### Manual Monitoring
- **Security Reviews**: Regular security code reviews
- **Penetration Testing**: Annual penetration tests
- **Compliance Audits**: Regular compliance assessments
- **Threat Intelligence**: Monitor threat landscape

### 2. Metrics and KPIs

#### Security Metrics
- **Vulnerability Count**: Track vulnerability trends
- **Scan Success Rate**: Monitor scan reliability
- **Fix Time**: Time to fix security issues
- **Training Completion**: Security training progress

#### Business Metrics
- **Security Incidents**: Number and severity
- **Downtime**: Security-related outages
- **Compliance**: Regulatory compliance status
- **Cost**: Security tool and incident costs

## 🎯 Implementation Checklist

### Immediate Actions (Week 1)
- [ ] Install security tools
- [ ] Configure pre-commit hooks
- [ ] Set up basic scanning
- [ ] Review current security posture

### Short-term Goals (Month 1)
- [ ] Implement comprehensive scanning
- [ ] Set up CI/CD integration
- [ ] Establish security policies
- [ ] Train development team

### Medium-term Goals (Quarter 1)
- [ ] Advanced security monitoring
- [ ] Incident response procedures
- [ ] Regular security reviews
- [ ] Compliance framework

### Long-term Goals (Year 1)
- [ ] Security maturity model
- [ ] Advanced threat protection
- [ ] Security automation
- [ ] Continuous improvement

## 📞 Support and Resources

### Internal Resources
- **Security Team**: security@company.com
- **DevOps Team**: devops@company.com
- **Documentation**: Internal security wiki
- **Training**: Security training portal

### External Resources
- **OWASP**: https://owasp.org/
- **NIST**: https://www.nist.gov/cyberframework
- **CIS**: https://www.cisecurity.org/
- **SANS**: https://www.sans.org/

### Emergency Contacts
- **Security Hotline**: +1-XXX-XXX-XXXX
- **Incident Response**: incident@company.com
- **Legal Team**: legal@company.com
- **External Security**: security-vendor@company.com
