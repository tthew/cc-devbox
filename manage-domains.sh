#!/bin/bash

# Squid Domain Management Tool
# Comprehensive domain management system for Life in Hand Development Environment
# Replaces the complex DNS+iptables+ipset firewall with Squid proxy management
# =============================================================================

set -e

# Configuration
SQUID_CONF="/etc/squid/squid.conf"
DOMAINS_CONF="/etc/squid/domains-squid.conf"
BACKUP_DIR="/var/backups/squid"
LOG_FILE="/var/log/squid/domain-management.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "DEBUG")
            echo -e "${PURPLE}🔧 $message${NC}"
            ;;
        *)
            echo -e "${CYAN}📝 $message${NC}"
            ;;
    esac
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root or with sudo"
        exit 1
    fi
}

# Create necessary directories
setup_directories() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chown proxy:proxy "$LOG_FILE" 2>/dev/null || true
}

# Backup current configuration
backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/domains-backup-$timestamp.conf"
    
    if [[ -f "$DOMAINS_CONF" ]]; then
        cp "$DOMAINS_CONF" "$backup_file"
        log "INFO" "Configuration backed up to $backup_file"
    fi
}

# Validate domain format
validate_domain() {
    local domain="$1"
    
    # Basic domain validation regex
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    
    # Check for minimum length
    if [[ ${#domain} -lt 3 ]]; then
        return 1
    fi
    
    # Check for maximum length
    if [[ ${#domain} -gt 253 ]]; then
        return 1
    fi
    
    return 0
}

# Add domain to whitelist
add_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        log "ERROR" "Domain name is required"
        return 1
    fi
    
    # Remove protocol if present
    domain=$(echo "$domain" | sed -e 's|^https\?://||' -e 's|/.*$||')
    
    # Validate domain
    if ! validate_domain "$domain"; then
        log "ERROR" "Invalid domain format: $domain"
        return 1
    fi
    
    # Check if domain already exists
    if grep -q "dstdomain .*$domain" "$DOMAINS_CONF" 2>/dev/null; then
        log "WARNING" "Domain $domain is already whitelisted"
        return 0
    fi
    
    # Backup current configuration
    backup_config
    
    # Add domain to both HTTP and HTTPS ACLs
    echo "acl whitelisted_domains dstdomain .$domain" >> "$DOMAINS_CONF"
    echo "acl whitelisted_ssl_domains ssl::server_name .$domain" >> "$DOMAINS_CONF"
    
    log "SUCCESS" "Added domain: $domain"
    
    # Reload Squid configuration
    reload_squid
    
    return 0
}

# Remove domain from whitelist
remove_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        log "ERROR" "Domain name is required"
        return 1
    fi
    
    # Remove protocol if present
    domain=$(echo "$domain" | sed -e 's|^https\?://||' -e 's|/.*$||')
    
    # Check if domain exists
    if ! grep -q "dstdomain .*$domain" "$DOMAINS_CONF" 2>/dev/null; then
        log "WARNING" "Domain $domain is not in the whitelist"
        return 0
    fi
    
    # Backup current configuration
    backup_config
    
    # Remove domain from configuration
    sed -i "/dstdomain .*$domain/d" "$DOMAINS_CONF"
    sed -i "/ssl::server_name .*$domain/d" "$DOMAINS_CONF"
    
    log "SUCCESS" "Removed domain: $domain"
    
    # Reload Squid configuration
    reload_squid
    
    return 0
}

# List all whitelisted domains
list_domains() {
    local show_categories="${1:-false}"
    
    if [[ ! -f "$DOMAINS_CONF" ]]; then
        log "WARNING" "Domains configuration file not found"
        return 1
    fi
    
    log "INFO" "Currently whitelisted domains:"
    echo
    
    if [[ "$show_categories" == "true" ]]; then
        # Show domains organized by category
        local current_category=""
        local category_count=0
        local total_count=0
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^#[[:space:]]*(.+) ]]; then
                # Category header
                if [[ $category_count -gt 0 ]]; then
                    echo -e "${CYAN}  ($category_count domains)${NC}"
                    echo
                fi
                current_category="${BASH_REMATCH[1]}"
                echo -e "${YELLOW}📁 $current_category${NC}"
                category_count=0
            elif [[ "$line" =~ ^acl[[:space:]]+whitelisted_domains[[:space:]]+dstdomain[[:space:]]+\.(.+)$ ]]; then
                # Domain entry
                local domain="${BASH_REMATCH[1]}"
                echo -e "${GREEN}  ✓ $domain${NC}"
                ((category_count++))
                ((total_count++))
            fi
        done < "$DOMAINS_CONF"
        
        if [[ $category_count -gt 0 ]]; then
            echo -e "${CYAN}  ($category_count domains)${NC}"
        fi
        
        echo
        echo -e "${BLUE}📊 Total: $total_count domains${NC}"
    else
        # Simple list
        grep "^acl whitelisted_domains dstdomain" "$DOMAINS_CONF" | \
        sed 's/^acl whitelisted_domains dstdomain \.//' | \
        sort | \
        while read -r domain; do
            echo -e "${GREEN}✓ $domain${NC}"
        done
        
        local count=$(grep -c "^acl whitelisted_domains dstdomain" "$DOMAINS_CONF" 2>/dev/null || echo "0")
        echo
        echo -e "${BLUE}📊 Total: $count domains${NC}"
    fi
}

# Test domain access
test_domain() {
    local domain="$1"
    local timeout="${2:-10}"
    
    if [[ -z "$domain" ]]; then
        log "ERROR" "Domain name is required for testing"
        return 1
    fi
    
    # Remove protocol if present
    domain=$(echo "$domain" | sed -e 's|^https\?://||' -e 's|/.*$||')
    
    log "INFO" "Testing access to $domain..."
    
    # Test HTTP access through proxy
    echo -e "${CYAN}🔍 Testing HTTP access...${NC}"
    if curl -s --connect-timeout "$timeout" --proxy "127.0.0.1:3128" "http://$domain" > /dev/null 2>&1; then
        log "SUCCESS" "HTTP access to $domain: ALLOWED"
    else
        log "ERROR" "HTTP access to $domain: BLOCKED"
    fi
    
    # Test HTTPS access through proxy
    echo -e "${CYAN}🔍 Testing HTTPS access...${NC}"
    if curl -s --connect-timeout "$timeout" --proxy "127.0.0.1:3128" "https://$domain" > /dev/null 2>&1; then
        log "SUCCESS" "HTTPS access to $domain: ALLOWED"
    else
        log "ERROR" "HTTPS access to $domain: BLOCKED"
    fi
    
    # Check if domain is in whitelist
    if grep -q "dstdomain .*$domain" "$DOMAINS_CONF" 2>/dev/null; then
        log "INFO" "Domain $domain is in the whitelist"
    else
        log "WARNING" "Domain $domain is NOT in the whitelist"
    fi
}

# Reload Squid configuration
reload_squid() {
    log "INFO" "Reloading Squid configuration..."
    
    # Test configuration syntax first
    if squid -k parse > /dev/null 2>&1; then
        # Configuration is valid, reload
        if squid -k reconfigure > /dev/null 2>&1; then
            log "SUCCESS" "Squid configuration reloaded successfully"
            sleep 2 # Give Squid time to fully reload
        else
            log "ERROR" "Failed to reload Squid configuration"
            return 1
        fi
    else
        log "ERROR" "Squid configuration syntax error - not reloading"
        return 1
    fi
}

# Check Squid status
check_status() {
    log "INFO" "Checking Squid proxy status..."
    echo
    
    # Check if Squid is running
    if pgrep -x squid > /dev/null; then
        log "SUCCESS" "Squid is running"
        
        # Get process information
        local squid_pid=$(pgrep -x squid)
        local squid_uptime=$(ps -o etime= -p "$squid_pid" | tr -d ' ')
        log "INFO" "PID: $squid_pid, Uptime: $squid_uptime"
        
        # Check port status
        if netstat -tln | grep -q ":3128"; then
            log "SUCCESS" "Proxy port 3128 is listening"
        else
            log "ERROR" "Proxy port 3128 is not listening"
        fi
        
        if netstat -tln | grep -q ":8080"; then
            log "SUCCESS" "Proxy port 8080 is listening"
        else
            log "WARNING" "Proxy port 8080 is not listening"
        fi
        
        # Check cache directory
        if [[ -d "/var/cache/squid" ]]; then
            local cache_size=$(du -sh /var/cache/squid 2>/dev/null | cut -f1)
            log "INFO" "Cache directory size: $cache_size"
        fi
        
        # Check recent log entries
        if [[ -f "/var/log/squid/access.log" ]]; then
            local recent_requests=$(tail -n 100 /var/log/squid/access.log 2>/dev/null | wc -l)
            log "INFO" "Recent requests (last 100 lines): $recent_requests"
        fi
        
    else
        log "ERROR" "Squid is not running"
        return 1
    fi
}

# Backup and restore functions
backup_all() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_archive="$BACKUP_DIR/squid-config-$timestamp.tar.gz"
    
    log "INFO" "Creating full configuration backup..."
    
    tar -czf "$backup_archive" \
        -C /etc/squid squid.conf domains-squid.conf \
        -C /var/log/squid . \
        2>/dev/null || true
    
    if [[ -f "$backup_archive" ]]; then
        log "SUCCESS" "Full backup created: $backup_archive"
        
        # Keep only last 10 backups
        find "$BACKUP_DIR" -name "squid-config-*.tar.gz" -type f | \
        sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true
        
        return 0
    else
        log "ERROR" "Failed to create backup"
        return 1
    fi
}

restore_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log "ERROR" "Backup file path is required"
        echo "Available backups:"
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    log "WARNING" "This will replace current configuration. Continue? (y/N)"
    read -r confirmation
    
    if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
        log "INFO" "Restore cancelled"
        return 0
    fi
    
    # Create current backup before restore
    backup_config
    
    # Extract backup
    if tar -xzf "$backup_file" -C /etc/squid 2>/dev/null; then
        log "SUCCESS" "Configuration restored from $backup_file"
        reload_squid
    else
        log "ERROR" "Failed to restore configuration"
        return 1
    fi
}

# Performance monitoring
monitor_performance() {
    local duration="${1:-60}"
    
    log "INFO" "Monitoring Squid performance for $duration seconds..."
    echo
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        local current_time=$(date '+%H:%M:%S')
        
        # Get current stats
        local memory_usage=$(ps -p "$(pgrep squid)" -o %mem --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        local cpu_usage=$(ps -p "$(pgrep squid)" -o %cpu --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        
        # Count active connections
        local connections=$(netstat -tn | grep -c ":3128" 2>/dev/null || echo "0")
        
        echo -e "${BLUE}[$current_time]${NC} CPU: ${YELLOW}${cpu_usage}%${NC} | Memory: ${YELLOW}${memory_usage}%${NC} | Connections: ${YELLOW}${connections}${NC}"
        
        sleep 5
    done
    
    log "SUCCESS" "Performance monitoring completed"
}

# Print usage information
show_usage() {
    echo -e "${CYAN}🚀 Squid Domain Management Tool${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo -e "${YELLOW}USAGE:${NC}"
    echo "  domains <command> [arguments]"
    echo
    echo -e "${YELLOW}COMMANDS:${NC}"
    echo -e "  ${GREEN}list${NC}               List all whitelisted domains"
    echo -e "  ${GREEN}list -c${NC}            List domains organized by category"
    echo -e "  ${GREEN}add <domain>${NC}       Add domain to whitelist"
    echo -e "  ${GREEN}remove <domain>${NC}    Remove domain from whitelist"
    echo -e "  ${GREEN}test <domain>${NC}      Test access to a domain"
    echo -e "  ${GREEN}status${NC}             Show Squid proxy status"
    echo -e "  ${GREEN}reload${NC}             Reload Squid configuration"
    echo -e "  ${GREEN}backup${NC}             Create full configuration backup"
    echo -e "  ${GREEN}restore <file>${NC}     Restore from backup file"
    echo -e "  ${GREEN}monitor [time]${NC}     Monitor performance (default: 60s)"
    echo -e "  ${GREEN}validate${NC}           Run comprehensive security validation"
    echo -e "  ${GREEN}harden${NC}             Apply environment hardening measures"
    echo -e "  ${GREEN}security [action]${NC}  Security management (status/validate/harden)"
    echo -e "  ${GREEN}help${NC}               Show this help message"
    echo
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo "  domains list"
    echo "  domains add example.com"
    echo "  domains remove example.com"
    echo "  domains test github.com"
    echo "  domains status"
    echo "  domains monitor 120"
    echo "  domains validate"
    echo "  domains security status"
    echo
    echo -e "${YELLOW}FILES:${NC}"
    echo "  Configuration: $DOMAINS_CONF"
    echo "  Log file: $LOG_FILE"
    echo "  Backup directory: $BACKUP_DIR"
    echo
    echo -e "${CYAN}🔒 This tool replaces the previous DNS+iptables+ipset firewall system${NC}"
    echo -e "${CYAN}   with a robust, maintainable Squid proxy solution.${NC}"
}

# Main script logic
main() {
    # Set up environment
    setup_directories
    
    # Check permissions for operations that need root
    case "${1:-}" in
        "list"|"test"|"status"|"help"|"monitor")
            # These commands don't need root permissions
            ;;
        *)
            check_permissions
            ;;
    esac
    
    # Parse command
    case "${1:-}" in
        "list")
            if [[ "${2:-}" == "-c" ]]; then
                list_domains true
            else
                list_domains false
            fi
            ;;
        "add")
            add_domain "$2"
            ;;
        "remove")
            remove_domain "$2"
            ;;
        "test")
            test_domain "$2" "${3:-10}"
            ;;
        "status")
            check_status
            ;;
        "reload")
            reload_squid
            ;;
        "backup")
            backup_all
            ;;
        "restore")
            restore_config "$2"
            ;;
        "monitor")
            monitor_performance "${2:-60}"
            ;;
        "validate")
            echo "🔍 Running security validation..."
            /usr/local/bin/validate-security.sh
            ;;
        "harden")
            echo "🔒 Running environment hardening..."
            /usr/local/bin/harden-environment.sh
            ;;
        "security")
            case "${2:-status}" in
                "validate")
                    /usr/local/bin/validate-security.sh
                    ;;
                "harden")
                    /usr/local/bin/harden-environment.sh
                    ;;
                "status"|*)
                    echo "🛡️ Security Status Check"
                    echo "======================="
                    check_status
                    echo ""
                    echo "🔍 Running quick security validation..."
                    /usr/local/bin/validate-security.sh 2>/dev/null | head -20
                    ;;
            esac
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            log "ERROR" "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"