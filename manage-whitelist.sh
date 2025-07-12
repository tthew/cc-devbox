#!/bin/bash

# Domain whitelist management script
set -e

# Configuration  
WHITELIST_FILE="/etc/whitelist-domains.conf"
DNSMASQ_CONF="/etc/dnsmasq.conf"
IPSET_NAME="whitelist_ips"
DNS_SERVER="8.8.8.8"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to log with timestamp
log_msg() {
    printf "[$(date '+%Y-%m-%d %H:%M:%S')] $1\n"
}

# Function to resolve domain and add IPs to ipset
resolve_and_add_domain() {
    local domain="$1"
    log_msg "${BLUE}Resolving and adding IPs for: $domain${NC}"
    
    # Get all IPs for the domain
    nslookup "$domain" "$DNS_SERVER" 2>/dev/null | grep "Address:" | grep -v "#53" | awk '{print $2}' | while read ip; do
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # Add IP to ipset with timeout
            if ipset add "$IPSET_NAME" "$ip" timeout 3600 2>/dev/null; then
                log_msg "${GREEN}  Added IP: $ip${NC}"
            else
                log_msg "${YELLOW}  IP already exists or failed: $ip${NC}"
            fi
        fi
    done
}

# Function to add domain to whitelist
add_domain() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_msg "${RED}Error: Domain name required${NC}"
        return 1
    fi
    
    # Check if domain already exists
    if grep -q "server=/$domain/" "$WHITELIST_FILE" 2>/dev/null; then
        log_msg "${YELLOW}Domain $domain already in whitelist${NC}"
    else
        # Add domain to whitelist file
        echo "server=/$domain/$DNS_SERVER" >> "$WHITELIST_FILE"
        log_msg "${GREEN}Added $domain to whitelist file${NC}"
        
        # Reload dnsmasq configuration
        if pkill -HUP dnsmasq 2>/dev/null; then
            log_msg "${GREEN}Reloaded dnsmasq configuration${NC}"
        else
            log_msg "${YELLOW}Warning: Could not reload dnsmasq${NC}"
        fi
    fi
    
    # Resolve and add IPs to ipset immediately
    resolve_and_add_domain "$domain"
}

# Function to remove domain from whitelist
remove_domain() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_msg "${RED}Error: Domain name required${NC}"
        return 1
    fi
    
    # Remove from whitelist file
    if grep -q "server=/$domain/" "$WHITELIST_FILE" 2>/dev/null; then
        sed -i "/server=\/$domain\//d" "$WHITELIST_FILE"
        log_msg "${GREEN}Removed $domain from whitelist file${NC}"
        
        # Reload dnsmasq configuration
        if pkill -HUP dnsmasq 2>/dev/null; then
            log_msg "${GREEN}Reloaded dnsmasq configuration${NC}"
        else
            log_msg "${YELLOW}Warning: Could not reload dnsmasq${NC}"
        fi
    else
        log_msg "${YELLOW}Domain $domain not found in whitelist${NC}"
    fi
}

# Function to test domain connectivity
test_domain() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_msg "${RED}Error: Domain name required${NC}"
        return 1
    fi
    
    log_msg "${BLUE}Testing connectivity to: $domain${NC}"
    
    # Test DNS resolution
    if nslookup "$domain" 127.0.0.1 >/dev/null 2>&1; then
        log_msg "${GREEN}✓ DNS resolution successful${NC}"
        
        # Get resolved IP
        local ip=$(nslookup "$domain" 127.0.0.1 2>/dev/null | grep "Address:" | grep -v "#53" | head -1 | awk '{print $2}')
        log_msg "${BLUE}  Resolved to: $ip${NC}"
        
        # Test HTTP connectivity
        if curl -s --connect-timeout 5 --max-time 10 "https://$domain" >/dev/null 2>&1; then
            log_msg "${GREEN}✓ HTTPS connectivity successful${NC}"
        elif curl -s --connect-timeout 5 --max-time 10 "http://$domain" >/dev/null 2>&1; then
            log_msg "${GREEN}✓ HTTP connectivity successful${NC}"
        else
            log_msg "${RED}✗ HTTP/HTTPS connectivity failed${NC}"
            
            # Check if IP is in ipset
            if [ -n "$ip" ] && ipset test "$IPSET_NAME" "$ip" 2>/dev/null; then
                log_msg "${YELLOW}  IP $ip is in whitelist, but connection failed${NC}"
            else
                log_msg "${RED}  IP $ip is NOT in ipset whitelist${NC}"
                log_msg "${BLUE}  Adding IP to whitelist...${NC}"
                resolve_and_add_domain "$domain"
            fi
        fi
    else
        log_msg "${RED}✗ DNS resolution failed${NC}"
    fi
}

# Function to list whitelisted domains (ZSH/BASH compatible)
list_domains() {
    log_msg "${BLUE}Current whitelisted domains:${NC}"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        log_msg "${YELLOW}No whitelist file found${NC}"
        return 1
    fi
    
    # Simple portable approach
    grep "^server=" "$WHITELIST_FILE" | sed 's|server=/||g' | sed 's|/.*||g' | sort -u | while read domain; do
        if [ -n "$domain" ]; then
            echo "  - $domain"
        fi
    done
    
    local count=$(grep "^server=" "$WHITELIST_FILE" | wc -l)
    log_msg "${GREEN}Total domains: $count${NC}"
    
    # Show ipset info
    if ipset list "$IPSET_NAME" >/dev/null 2>&1; then
        local ip_count=$(ipset list "$IPSET_NAME" | grep "Number of entries:" | awk '{print $4}')
        log_msg "${GREEN}IPs in firewall whitelist: $ip_count${NC}"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 {list|add|remove|test} [domain]"
    echo ""
    echo "Commands:"
    echo "  list              - List all whitelisted domains"
    echo "  add <domain>      - Add domain to whitelist"
    echo "  remove <domain>   - Remove domain from whitelist"
    echo "  test <domain>     - Test domain connectivity and resolve issues"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 add api.github.com"
    echo "  $0 remove unwanted.com"
    echo "  $0 test api.github.com"
}

# Main command handling
case "${1:-help}" in
    "list")
        list_domains
        ;;
    "add")
        add_domain "$2"
        ;;
    "remove")
        remove_domain "$2"
        ;;
    "test")
        test_domain "$2"
        ;;
    "help"|*)
        show_usage
        exit 1
        ;;
esac
