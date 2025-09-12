#!/bin/bash

# =============================================
# Comprehensive Test Suite for Apartment Accounting System
# =============================================

echo "=================================================="
echo "Apartment Accounting System - Complete Test Suite"
echo "=================================================="
echo "Test Date: $(date)"
echo "Test Environment: Docker Containerized"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_type="$3"
    
    echo -e "${BLUE}Running $test_type: $test_name${NC}"
    echo "Command: $test_command"
    echo "----------------------------------------"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name - PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $test_name - FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# Check if Docker containers are running
echo -e "${YELLOW}Checking Docker containers...${NC}"
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}Error: Docker containers are not running. Starting containers...${NC}"
    docker-compose up -d
    echo "Waiting for containers to start..."
    sleep 30
fi

echo -e "${GREEN}Docker containers are running.${NC}"
echo ""

# =============================================
# 1. Database Tests
# =============================================
echo -e "${YELLOW}=== DATABASE TESTS ===${NC}"

# Copy database test file to container
echo "Copying database test file to container..."
docker cp testing/database_tests.sql apartment_accounting_db:/tmp/database_tests.sql

# Run database tests
run_test "Database Schema Validation" \
    "docker exec apartment_accounting_db psql -U postgres -d apartment_accounting -f /tmp/database_tests.sql" \
    "Database Test"

# =============================================
# 2. API Tests
# =============================================
echo -e "${YELLOW}=== API TESTS ===${NC}"

# Run API tests
run_test "Backend API Validation" \
    "python3 testing/test_backend.py" \
    "API Test"

# =============================================
# 3. Health Checks
# =============================================
echo -e "${YELLOW}=== HEALTH CHECKS ===${NC}"

# Backend health check
run_test "Backend Health Check" \
    "curl -f http://localhost:8000/health" \
    "Health Check"

# Database health check
run_test "Database Health Check" \
    "docker exec apartment_accounting_db pg_isready -U postgres -d apartment_accounting" \
    "Health Check"

# =============================================
# 4. Performance Tests
# =============================================
echo -e "${YELLOW}=== PERFORMANCE TESTS ===${NC}"

# API response time test
run_test "API Response Time Test" \
    "curl -w '@-' -o /dev/null -s http://localhost:8000/health <<< 'time_namelookup:  %{time_namelookup}\ntime_connect:     %{time_connect}\ntime_appconnect:  %{time_appconnect}\ntime_pretransfer: %{time_pretransfer}\ntime_redirect:    %{time_redirect}\ntime_starttransfer: %{time_starttransfer}\ntime_total:       %{time_total}\n'" \
    "Performance Test"

# =============================================
# 5. Security Tests
# =============================================
echo -e "${YELLOW}=== SECURITY TESTS ===${NC}"

# Test unauthorized access
run_test "Unauthorized Access Test" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/api/accounts | grep -q '401\|403'" \
    "Security Test"

# Test invalid credentials
run_test "Invalid Credentials Test" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{\"username\":\"invalid\",\"password\":\"invalid\"}' http://localhost:8000/api/login | grep -q '403'" \
    "Security Test"

# =============================================
# Test Summary
# =============================================
echo "=================================================="
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo "=================================================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}Success Rate: 100%${NC}"
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}Success Rate: $success_rate%${NC}"
    echo -e "${RED}⚠️  Some tests failed. Please review the output above.${NC}"
    exit 1
fi
