#!/bin/bash

# Container Performance Monitor for M4 Pro
# Optimized for development environment monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="life-in-hand-claude-dev"
LOG_FILE="/workspace/logs/performance.log"
ALERT_CPU_THRESHOLD=400  # 400% CPU (4 cores)
ALERT_MEMORY_THRESHOLD=10 # 10GB

# Function to log with timestamp
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to get container stats
get_container_stats() {
    if ! docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" "$CONTAINER_NAME" 2>/dev/null; then
        echo "❌ Container $CONTAINER_NAME not found or not running"
        return 1
    fi
}

# Function to get detailed performance metrics
get_detailed_metrics() {
    local container_id=$(docker ps -q --filter "name=$CONTAINER_NAME")
    
    if [ -z "$container_id" ]; then
        echo "❌ Container not running"
        return 1
    fi
    
    echo -e "${BLUE}📊 Detailed Performance Metrics${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # CPU and Memory from docker stats
    local stats=$(docker stats --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" "$container_id")
    local cpu_percent=$(echo "$stats" | awk '{print $1}' | sed 's/%//')
    local mem_usage=$(echo "$stats" | awk '{print $2}')
    local net_io=$(echo "$stats" | awk '{print $3}')
    local block_io=$(echo "$stats" | awk '{print $4}')
    local pids=$(echo "$stats" | awk '{print $5}')
    
    # Host system info
    local host_cpu=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    local host_memory=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
    
    echo -e "${GREEN}🖥️  Host System (M4 Pro)${NC}"
    echo "   CPU Usage: ${host_cpu}%"
    echo "   Memory Free: ${host_memory}%"
    echo ""
    
    echo -e "${CYAN}🐳 Container Performance${NC}"
    echo "   CPU Usage: ${cpu_percent}% (Threshold: ${ALERT_CPU_THRESHOLD}%)"
    echo "   Memory: ${mem_usage}"
    echo "   Network I/O: ${net_io}"
    echo "   Block I/O: ${block_io}"
    echo "   Processes: ${pids}"
    echo ""
    
    # Container internal metrics
    echo -e "${PURPLE}📈 Internal Metrics${NC}"
    docker exec "$container_id" bash -c "
        echo '   Load Average: '$(cat /proc/loadavg | awk '{print $1, $2, $3}')
        echo '   Memory Info:'
        free -h | grep Mem | awk '{print \"     Total: \" \$2 \", Used: \" \$3 \", Free: \" \$4}'
        echo '   Disk Usage:'
        df -h /workspace | tail -1 | awk '{print \"     Workspace: \" \$3 \"/\" \$2 \" (\" \$5 \" used)\"}'
        echo '   Active Processes:'
        ps aux | wc -l | awk '{print \"     Count: \" \$1}'
    " 2>/dev/null || echo "   Unable to retrieve internal metrics"
    
    # Performance alerts
    if (( $(echo "$cpu_percent > $ALERT_CPU_THRESHOLD" | bc -l) )); then
        echo -e "${RED}🚨 HIGH CPU USAGE ALERT: ${cpu_percent}%${NC}"
        log_msg "ALERT: High CPU usage - ${cpu_percent}%"
    fi
    
    # Extract numeric memory value for comparison
    local mem_gb=$(echo "$mem_usage" | grep -o '[0-9.]*GiB' | sed 's/GiB//')
    if [ -n "$mem_gb" ] && (( $(echo "$mem_gb > $ALERT_MEMORY_THRESHOLD" | bc -l) )); then
        echo -e "${RED}🚨 HIGH MEMORY USAGE ALERT: ${mem_gb}GB${NC}"
        log_msg "ALERT: High memory usage - ${mem_gb}GB"
    fi
}

# Function to show optimization recommendations
show_recommendations() {
    echo -e "${YELLOW}💡 Performance Optimization Tips${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. 🔧 Ensure Docker Desktop allocates 16GB+ RAM"
    echo "2. ⚡ Use 'pnpm' instead of 'npm' for faster installs"
    echo "3. 🗂️  Enable Docker Desktop VirtioFS for better I/O"
    echo "4. 🧹 Run 'docker system prune' to clean up space"
    echo "5. 🔥 Use 'npm run dev' with --turbo for faster builds"
    echo "6. 📊 Monitor with: watch -n 2 './performance-monitor.sh status'"
    echo ""
}

# Function to run continuous monitoring
monitor_continuous() {
    echo -e "${GREEN}🔄 Starting continuous monitoring (Ctrl+C to stop)${NC}"
    echo "Logging to: $LOG_FILE"
    echo ""
    
    # Create log file if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    while true; do
        clear
        echo -e "${BLUE}🍎 M4 Pro Docker Performance Monitor${NC}"
        echo "Time: $(date)"
        echo ""
        get_detailed_metrics
        echo ""
        echo "Press Ctrl+C to stop monitoring..."
        sleep 5
    done
}

# Function to show quick status
show_status() {
    echo -e "${BLUE}📊 Quick Container Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    get_container_stats
}

# Function to show usage
show_usage() {
    echo "M4 Pro Docker Performance Monitor"
    echo ""
    echo "Usage: $0 {status|detailed|monitor|recommendations|help}"
    echo ""
    echo "Commands:"
    echo "  status          - Quick container status"
    echo "  detailed        - Detailed performance metrics"
    echo "  monitor         - Continuous monitoring (Ctrl+C to stop)"
    echo "  recommendations - Show performance optimization tips"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 detailed"
    echo "  $0 monitor"
    echo "  watch -n 2 '$0 status'  # Auto-refresh every 2 seconds"
}

# Main command handling
case "${1:-help}" in
    "status")
        show_status
        ;;
    "detailed")
        get_detailed_metrics
        ;;
    "monitor")
        monitor_continuous
        ;;
    "recommendations")
        show_recommendations
        ;;
    "help"|*)
        show_usage
        ;;
esac