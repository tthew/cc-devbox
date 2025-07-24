#!/bin/bash

# Monitor Blocked Requests Script
# Shows blocked and allowed DNS requests in real-time

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/workspace/logs/dnsmasq.log"

echo -e "${BLUE}🔍 DNS Request Monitor${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ ALLOWED${NC} - Shows real IP addresses"
echo -e "${RED}❌ BLOCKED${NC} - Shows 'config domain is 127.0.0.1'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to show blocked requests
show_blocked() {
    echo -e "${RED}🚫 Recently Blocked Requests:${NC}"
    if [ -f "$LOG_FILE" ]; then
        grep "config.*is 127.0.0.1" "$LOG_FILE" | tail -10 | while read line; do
            domain=$(echo "$line" | sed 's/.*config \([^ ]*\) is 127.0.0.1.*/\1/')
            timestamp=$(echo "$line" | awk '{print $1, $2}')
            echo -e "  ${RED}❌${NC} $timestamp - $domain"
        done
    else
        echo "  No log file found"
    fi
    echo ""
}

# Function to show allowed requests
show_allowed() {
    echo -e "${GREEN}✅ Recently Allowed Requests:${NC}"
    if [ -f "$LOG_FILE" ]; then
        grep -E "(reply.*is [0-9]|cached.*is [0-9])" "$LOG_FILE" | tail -10 | while read line; do
            if echo "$line" | grep -q "cached"; then
                domain=$(echo "$line" | sed 's/.*cached \([^ ]*\) is.*/\1/')
                ip=$(echo "$line" | sed 's/.*is \([0-9a-f.:][^ ]*\).*/\1/')
            else
                domain=$(echo "$line" | sed 's/.*reply \([^ ]*\) is.*/\1/')
                ip=$(echo "$line" | sed 's/.*is \([0-9a-f.:][^ ]*\).*/\1/')
            fi
            timestamp=$(echo "$line" | awk '{print $1, $2}')
            echo -e "  ${GREEN}✅${NC} $timestamp - $domain → $ip"
        done
    else
        echo "  No log file found"
    fi
    echo ""
}

# Function to show real-time monitoring
monitor_realtime() {
    echo -e "${YELLOW}📡 Real-time DNS Monitoring (Ctrl+C to stop):${NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" | while read line; do
            if echo "$line" | grep -q "config.*is 127.0.0.1"; then
                domain=$(echo "$line" | sed 's/.*config \([^ ]*\) is 127.0.0.1.*/\1/')
                timestamp=$(echo "$line" | awk '{print $1, $2}')
                echo -e "${RED}❌ BLOCKED${NC} $timestamp - $domain"
            elif echo "$line" | grep -qE "(reply.*is [0-9]|cached.*is [0-9])"; then
                if echo "$line" | grep -q "cached"; then
                    domain=$(echo "$line" | sed 's/.*cached \([^ ]*\) is.*/\1/')
                    ip=$(echo "$line" | sed 's/.*is \([0-9a-f.:][^ ]*\).*/\1/')
                else
                    domain=$(echo "$line" | sed 's/.*reply \([^ ]*\) is.*/\1/')
                    ip=$(echo "$line" | sed 's/.*is \([0-9a-f.:][^ ]*\).*/\1/')
                fi
                timestamp=$(echo "$line" | awk '{print $1, $2}')
                echo -e "${GREEN}✅ ALLOWED${NC} $timestamp - $domain → $ip"
            fi
        done
    else
        echo "Log file not found: $LOG_FILE"
    fi
}

# Function to show summary statistics
show_stats() {
    echo -e "${BLUE}📊 DNS Request Statistics:${NC}"
    if [ -f "$LOG_FILE" ]; then
        local total_queries=$(grep "query\[A\]" "$LOG_FILE" | wc -l)
        local blocked_count=$(grep "config.*is 127.0.0.1" "$LOG_FILE" | wc -l)
        local allowed_count=$(grep -E "(reply.*is [0-9]|cached.*is [0-9])" "$LOG_FILE" | wc -l)
        
        echo "  Total DNS queries: $total_queries"
        echo -e "  ${RED}Blocked requests: $blocked_count${NC}"
        echo -e "  ${GREEN}Allowed requests: $allowed_count${NC}"
        
        if [ $total_queries -gt 0 ]; then
            local block_percent=$((blocked_count * 100 / total_queries))
            echo "  Block rate: ${block_percent}%"
        fi
    else
        echo "  No log file found"
    fi
    echo ""
}

# Main menu
case "${1:-summary}" in
    "blocked")
        show_blocked
        ;;
    "allowed") 
        show_allowed
        ;;
    "monitor"|"watch")
        monitor_realtime
        ;;
    "stats")
        show_stats
        ;;
    "summary"|"")
        show_stats
        show_blocked
        show_allowed
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  blocked  - Show recently blocked requests"
        echo "  allowed  - Show recently allowed requests" 
        echo "  monitor  - Real-time monitoring (Ctrl+C to stop)"
        echo "  stats    - Show summary statistics"
        echo "  summary  - Show stats + recent blocked/allowed (default)"
        echo "  help     - Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac