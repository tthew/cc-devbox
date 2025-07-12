#!/bin/bash

# Comprehensive Firewall/Whitelist Functionality Test Suite
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WHITELIST_CMD="/usr/local/bin/whitelist"
TEST_DOMAIN="example.com"
BLOCKED_DOMAIN="malicious-site.evil"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${BLUE}Test $TOTAL_TESTS: $test_name${NC}"
    
    if eval "$test_command" >/dev/null 2>&1; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL (expected to fail but passed)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}✅ PASS (correctly failed)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}❌ FAIL${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

main() {
    echo -e "${BLUE}Comprehensive Firewall/Whitelist Test Suite${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    # Prerequisites
    echo -e "\n${YELLOW}=== PREREQUISITES ===${NC}"
    run_test "dnsmasq running" "pgrep dnsmasq" "pass"
    run_test "whitelist command exists" "[ -x '$WHITELIST_CMD' ]" "pass"
    
    # Whitelist management
    echo -e "\n${YELLOW}=== WHITELIST MANAGEMENT ===${NC}"
    run_test "Add domain" "$WHITELIST_CMD add $TEST_DOMAIN" "pass"
    run_test "List domains" "$WHITELIST_CMD list | grep -q '$TEST_DOMAIN'" "pass"
    run_test "Remove domain" "$WHITELIST_CMD remove $TEST_DOMAIN" "pass"
    
    # DNS resolution
    echo -e "\n${YELLOW}=== DNS RESOLUTION ===${NC}"
    $WHITELIST_CMD add github.com >/dev/null 2>&1 || true
    sleep 1
    run_test "Whitelisted domain resolves" "nslookup github.com 127.0.0.1" "pass"
    run_test "Blocked domain fails" "timeout 3 nslookup $BLOCKED_DOMAIN 127.0.0.1" "fail"
    
    # Network connectivity
    echo -e "\n${YELLOW}=== NETWORK CONNECTIVITY ===${NC}"
    run_test "HTTPS to whitelisted domain" "timeout 5 curl -s https://github.com" "pass"
    run_test "HTTP to blocked domain fails" "timeout 3 curl -s http://$BLOCKED_DOMAIN" "fail"
    
    # Playwright compatibility
    echo -e "\n${YELLOW}=== PLAYWRIGHT COMPATIBILITY ===${NC}"
    $WHITELIST_CMD add playwright.dev >/dev/null 2>&1 || true
    sleep 1
    run_test "Playwright domain resolves" "nslookup playwright.dev 127.0.0.1" "pass"
    
    # Results
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "${BLUE}Total Tests:  $TOTAL_TESTS${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ $TESTS_FAILED tests failed${NC}"
        return 1
    fi
}

main "$@"