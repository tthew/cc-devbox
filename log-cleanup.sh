#!/bin/bash

# Emergency log cleanup script
# Monitors disk usage and cleans logs when space is low
# Based on Claude Code best practices for resource management

set -e

# Configuration
DISK_USAGE_THRESHOLD=80
EMERGENCY_THRESHOLD=90
CRITICAL_THRESHOLD=95
LOG_DIRS=("/var/log/squid" "/workspace/logs")
BACKUP_DIR="/tmp/log-backup"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to get disk usage percentage
get_disk_usage() {
    df / | tail -1 | awk '{print $5}' | sed 's/%//'
}

# Function to get directory size in MB
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sm "$dir" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Function to log with timestamp
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to clean old logs
clean_old_logs() {
    local dir="$1"
    local retention_days="$2"
    
    if [ -d "$dir" ]; then
        log_msg "Cleaning logs in $dir older than $retention_days days"
        find "$dir" -name "*.log*" -type f -mtime +$retention_days -delete 2>/dev/null || true
        find "$dir" -name "*.gz" -type f -mtime +$retention_days -delete 2>/dev/null || true
    fi
}

# Function to compress large log files
compress_large_logs() {
    local dir="$1"
    local size_threshold="$2"  # in MB
    
    if [ -d "$dir" ]; then
        log_msg "Compressing logs larger than ${size_threshold}MB in $dir"
        find "$dir" -name "*.log" -type f -size +${size_threshold}M -exec gzip {} \; 2>/dev/null || true
    fi
}

# Function to emergency cleanup (most aggressive)
emergency_cleanup() {
    log_msg "${RED}EMERGENCY CLEANUP ACTIVATED${NC}"
    
    # Clean system logs aggressively
    journalctl --vacuum-time=1d 2>/dev/null || true
    
    # Clean all log directories with very short retention
    for dir in "${LOG_DIRS[@]}"; do
        clean_old_logs "$dir" 1
        compress_large_logs "$dir" 1
    done
    
    # Clean temporary files
    find /tmp -name "*.log*" -type f -mtime +0 -delete 2>/dev/null || true
    
    # Clear kernel logs if they're too large
    if [ -f /var/log/kern.log ] && [ $(stat -f%z /var/log/kern.log 2>/dev/null || stat -c%s /var/log/kern.log) -gt 10485760 ]; then
        log_msg "Truncating large kernel log"
        echo "" > /var/log/kern.log
    fi
    
    # Clear messages log if too large
    if [ -f /var/log/messages ] && [ $(stat -f%z /var/log/messages 2>/dev/null || stat -c%s /var/log/messages) -gt 10485760 ]; then
        log_msg "Truncating large messages log"
        echo "" > /var/log/messages
    fi
}

# Function to standard cleanup
standard_cleanup() {
    log_msg "${YELLOW}Standard cleanup activated${NC}"
    
    # Clean with normal retention periods
    clean_old_logs "/var/log/squid" 7
    clean_old_logs "/workspace/logs" 5
    
    # Compress logs larger than 10MB
    for dir in "${LOG_DIRS[@]}"; do
        compress_large_logs "$dir" 10
    done
    
    # Force logrotate to run
    logrotate -f /etc/logrotate.d/squid 2>/dev/null || true
}

# Function to show disk usage report
show_disk_report() {
    local usage=$(get_disk_usage)
    
    echo "📊 Disk Usage Report:"
    echo "   Total Usage: ${usage}%"
    
    for dir in "${LOG_DIRS[@]}"; do
        local size=$(get_dir_size "$dir")
        echo "   $dir: ${size}MB"
    done
    
    # Show largest log files
    echo "📁 Largest log files:"
    find "${LOG_DIRS[@]}" -name "*.log*" -type f 2>/dev/null | xargs ls -lah 2>/dev/null | sort -k5 -hr | head -5 || true
}

# Main execution
main() {
    local current_usage=$(get_disk_usage)
    
    log_msg "🔍 Checking disk usage: ${current_usage}%"
    
    # Always show report if requested
    if [ "$1" = "--report" ] || [ "$1" = "-r" ]; then
        show_disk_report
        exit 0
    fi
    
    # Manual cleanup if requested
    if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
        log_msg "🧹 Manual cleanup requested"
        standard_cleanup
        show_disk_report
        exit 0
    fi
    
    # Emergency cleanup if requested
    if [ "$1" = "--emergency" ] || [ "$1" = "-e" ]; then
        log_msg "🚨 Emergency cleanup requested"
        emergency_cleanup
        show_disk_report
        exit 0
    fi
    
    # Automatic cleanup based on thresholds
    if [ $current_usage -ge $CRITICAL_THRESHOLD ]; then
        log_msg "${RED}CRITICAL: Disk usage at ${current_usage}%! Disabling logging and emergency cleanup${NC}"
        emergency_cleanup
        
        # Reduce Squid logging temporarily
        sed -i 's/debug_options ALL,1/debug_options ALL,0/' /etc/squid/squid.conf 2>/dev/null || true
        squid -k reconfigure 2>/dev/null || true
        
        log_msg "Squid debug logging temporarily reduced due to critical disk usage"
        
    elif [ $current_usage -ge $EMERGENCY_THRESHOLD ]; then
        log_msg "${YELLOW}WARNING: Disk usage at ${current_usage}%! Starting emergency cleanup${NC}"
        emergency_cleanup
        
    elif [ $current_usage -ge $DISK_USAGE_THRESHOLD ]; then
        log_msg "${YELLOW}Disk usage at ${current_usage}%! Starting standard cleanup${NC}"
        standard_cleanup
        
    else
        log_msg "${GREEN}Disk usage OK: ${current_usage}%${NC}"
    fi
    
    # Final report
    local final_usage=$(get_disk_usage)
    if [ $final_usage -lt $current_usage ]; then
        log_msg "${GREEN}Cleanup successful: ${current_usage}% → ${final_usage}%${NC}"
    fi
}

# Help function
show_help() {
    echo "Log Cleanup Script for Claude Code Development Environment"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -r, --report      Show disk usage report without cleanup"
    echo "  -f, --force       Force standard cleanup regardless of disk usage"
    echo "  -e, --emergency   Force emergency cleanup (most aggressive)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Automatic thresholds:"
    echo "  ${DISK_USAGE_THRESHOLD}%+: Standard cleanup"
    echo "  ${EMERGENCY_THRESHOLD}%+: Emergency cleanup"
    echo "  ${CRITICAL_THRESHOLD}%+: Disable logging + emergency cleanup"
}

# Handle help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"