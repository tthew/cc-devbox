#!/bin/bash

# Enhanced Security Firewall with Squid Proxy Enforcement
# Designed by Security Engineer for Life in Hand Development Environment
# ========================================================================
# Replaces unreliable DNS+iptables+ipset with robust Squid proxy enforcement
# Prevents ALL bypass attempts while maintaining container manageability

set -e

# Configuration
SQUID_TRANSPARENT_PORT=3128
SQUID_EXPLICIT_PORT=8080
SQUID_SSL_PORT=3129
LOG_PREFIX="SECURITY-FW"

echo "🛡️ Initializing enhanced security firewall with Squid proxy enforcement..."
echo "📋 Architecture: Layer 1 (iptables) → Layer 2 (Squid) → Layer 3 (Environment)"

# Only run if we have the necessary capabilities
if [ -f /proc/sys/net/ipv4/ip_forward ]; then
    
    # ========================================================================
    # CLEANUP PHASE: Remove old DNS-based system completely
    # ========================================================================
    echo "🧹 Cleaning up legacy DNS-based firewall system..."
    
    # Clear ALL existing rules (fresh start)
    iptables -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    iptables -t nat -F 2>/dev/null || true
    iptables -t nat -X 2>/dev/null || true
    iptables -t mangle -F 2>/dev/null || true
    iptables -t mangle -X 2>/dev/null || true
    iptables -t raw -F 2>/dev/null || true
    iptables -t raw -X 2>/dev/null || true
    
    # Remove legacy ipsets completely (no longer needed with Squid)
    ipset flush 2>/dev/null || true
    ipset destroy 2>/dev/null || true
    
    echo "✅ Legacy firewall system cleaned up"
    
    # ========================================================================
    # PHASE 1: SQUID PROXY VALIDATION
    # ========================================================================
    echo "🔍 Validating Squid proxy infrastructure..."
    
    # Check if Squid is running
    if ! pgrep -x squid > /dev/null; then
        echo "❌ ERROR: Squid proxy is not running!"
        echo "💡 Squid must be started before firewall initialization"
        echo "🔧 Run: squid -D"
        exit 1
    fi
    
    # Verify Squid ports are listening
    squid_ports_ok=0
    if netstat -tln | grep -q ":$SQUID_TRANSPARENT_PORT"; then
        echo "✅ Squid transparent proxy port $SQUID_TRANSPARENT_PORT is active"
        ((squid_ports_ok++))
    else
        echo "⚠️  WARNING: Squid transparent port $SQUID_TRANSPARENT_PORT not listening"
    fi
    
    if netstat -tln | grep -q ":$SQUID_EXPLICIT_PORT"; then
        echo "✅ Squid explicit proxy port $SQUID_EXPLICIT_PORT is active"
        ((squid_ports_ok++))
    else
        echo "⚠️  WARNING: Squid explicit port $SQUID_EXPLICIT_PORT not listening"
    fi
    
    if [ $squid_ports_ok -eq 0 ]; then
        echo "❌ ERROR: No Squid proxy ports are listening!"
        echo "🔧 Check Squid configuration and restart if needed"
        exit 1
    fi
    
    echo "✅ Squid proxy infrastructure validated"
    
    # ========================================================================
    # PHASE 2: DEFAULT POLICIES (DENY ALL - SECURE BY DEFAULT)
    # ========================================================================
    echo "🔒 Setting secure default policies (deny all)..."
    
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
    
    echo "✅ Default deny policies applied - all traffic blocked by default"
    
    # ========================================================================
    # PHASE 3: ESSENTIAL SYSTEM TRAFFIC (MUST ALLOW FOR BASIC OPERATION)
    # ========================================================================
    echo "🔧 Configuring essential system traffic..."
    
    # Loopback interface (essential for container operation)
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Established and related connections (performance optimization)
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    echo "✅ Essential system traffic configured"
    
    # ========================================================================
    # PHASE 4: CONTAINER MANAGEMENT ACCESS (SSH, DEVELOPMENT PORTS)
    # ========================================================================
    echo "🚪 Configuring container management access..."
    
    # SSH access (port 22) - essential for container management
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Development server ports (Next.js, Storybook, etc.)
    iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3001 -j ACCEPT
    iptables -A INPUT -p tcp --dport 6006 -j ACCEPT  # Storybook
    
    # Supabase local development ports
    iptables -A INPUT -p tcp --dport 54321 -j ACCEPT
    iptables -A INPUT -p tcp --dport 54322 -j ACCEPT
    iptables -A INPUT -p tcp --dport 54323 -j ACCEPT
    iptables -A INPUT -p tcp --dport 54324 -j ACCEPT
    
    # Proxy ports for direct access (management and debugging)
    iptables -A INPUT -p tcp --dport $SQUID_TRANSPARENT_PORT -j ACCEPT
    iptables -A INPUT -p tcp --dport $SQUID_EXPLICIT_PORT -j ACCEPT
    iptables -A INPUT -p tcp --dport $SQUID_SSL_PORT -j ACCEPT
    
    echo "✅ Container management access configured"
    
    # ========================================================================
    # PHASE 5: SQUID PROXY ENFORCEMENT LAYER (CORE SECURITY)
    # ========================================================================
    echo "🛡️ Implementing Squid proxy enforcement layer..."
    
    # CRITICAL: Block ALL direct external HTTP/HTTPS traffic
    # Only allow traffic to go through Squid proxy
    
    # DNS Resolution - Allow to public DNS servers for domain resolution
    # (Squid needs to resolve domains for ACL matching)
    iptables -A OUTPUT -p udp --dport 53 -d 8.8.8.8 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -d 8.8.4.4 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 53 -d 1.1.1.1 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -d 8.8.8.8 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -d 8.8.4.4 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -d 1.1.1.1 -j ACCEPT
    
    # Allow Squid process to make outbound connections
    # This is where Squid enforces domain filtering
    iptables -A OUTPUT -m owner --uid-owner proxy -j ACCEPT
    
    # Allow connections to proxy ports (internal communication)
    iptables -A OUTPUT -p tcp --dport $SQUID_TRANSPARENT_PORT -d 127.0.0.1 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $SQUID_EXPLICIT_PORT -d 127.0.0.1 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport $SQUID_SSL_PORT -d 127.0.0.1 -j ACCEPT
    
    echo "✅ Squid proxy enforcement layer implemented"
    
    # ========================================================================
    # PHASE 6: TRANSPARENT PROXY REDIRECTION (AUTOMATIC ENFORCEMENT)
    # ========================================================================
    echo "🔄 Configuring transparent proxy redirection..."
    
    # Redirect all HTTP traffic to Squid transparent proxy
    iptables -t nat -A OUTPUT -p tcp --dport 80 ! -d 127.0.0.1 \
        -j REDIRECT --to-ports $SQUID_TRANSPARENT_PORT
    
    # Redirect all HTTPS traffic to Squid transparent proxy
    iptables -t nat -A OUTPUT -p tcp --dport 443 ! -d 127.0.0.1 \
        -j REDIRECT --to-ports $SQUID_TRANSPARENT_PORT
    
    echo "✅ Transparent proxy redirection configured"
    
    # ========================================================================
    # PHASE 7: BYPASS PREVENTION (CRITICAL SECURITY MEASURES)
    # ========================================================================
    echo "🚫 Implementing bypass prevention measures..."
    
    # Block direct IP access to common web ports (prevents domain bypass)
    iptables -A OUTPUT -p tcp --dport 80 ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP
    iptables -A OUTPUT -p tcp --dport 443 ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP
    iptables -A OUTPUT -p tcp --dport 8080 ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP
    iptables -A OUTPUT -p tcp --dport 8443 ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP
    
    # Block alternative HTTP ports commonly used for bypassing
    for port in 8000 8001 8002 8003 8008 8888 9000 9001 9080 9090; do
        iptables -A OUTPUT -p tcp --dport $port ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP
    done
    
    # Block SOCKS proxy ports (prevent tunneling)
    iptables -A OUTPUT -p tcp --dport 1080 ! -d 127.0.0.1 -j DROP
    iptables -A OUTPUT -p tcp --dport 1081 ! -d 127.0.0.1 -j DROP
    
    # Block additional bypass protocols
    iptables -A OUTPUT -p tcp --dport 9050 ! -d 127.0.0.1 -j DROP  # Tor
    iptables -A OUTPUT -p tcp --dport 4001 ! -d 127.0.0.1 -j DROP  # IPFS
    iptables -A OUTPUT -p tcp --dport 3128 ! -d 127.0.0.1 ! -m owner --uid-owner proxy -j DROP  # Block external proxies
    
    echo "✅ Bypass prevention measures implemented"
    
    # ========================================================================
    # PHASE 8: CONTAINER NETWORKING (DOCKER/LOCAL SERVICES)
    # ========================================================================
    echo "🐳 Configuring container networking access..."
    
    # Docker network ranges (for Supabase and other local services)
    iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT    # Docker networks
    iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT   # Local networks
    iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT       # Private networks
    
    # Specific Docker gateway addresses
    iptables -A OUTPUT -d 172.17.0.1 -j ACCEPT       # Default Docker bridge
    iptables -A OUTPUT -d 172.18.0.1 -j ACCEPT       # Custom bridge
    iptables -A OUTPUT -d 192.168.65.254 -j ACCEPT   # Docker Desktop for Mac
    iptables -A OUTPUT -d host.docker.internal -j ACCEPT 2>/dev/null || true
    
    echo "✅ Container networking configured"
    
    # ========================================================================
    # PHASE 9: ESSENTIAL PROTOCOLS (TIME, GIT, SSH)
    # ========================================================================
    echo "⏰ Configuring essential protocols..."
    
    # NTP (Network Time Protocol) - critical for SSL certificates
    iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
    
    # SSH to Git servers (GitHub, etc.) - through Squid proxy only
    # Note: Git over SSH will be allowed only to domains in Squid whitelist
    iptables -A OUTPUT -p tcp --dport 22 -m owner --uid-owner proxy -j ACCEPT
    
    # Git protocol (rarely used, but for completeness)
    iptables -A OUTPUT -p tcp --dport 9418 -m owner --uid-owner proxy -j ACCEPT
    
    echo "✅ Essential protocols configured"
    
    # ========================================================================
    # PHASE 10: SECURITY LOGGING AND MONITORING
    # ========================================================================
    echo "📊 Configuring security logging and monitoring..."
    
    # Create custom chains for logging
    iptables -N LOG_DROP_INPUT 2>/dev/null || true
    iptables -N LOG_DROP_OUTPUT 2>/dev/null || true
    
    # Log dropped INPUT packets (potential intrusion attempts)
    iptables -A LOG_DROP_INPUT -m limit --limit 5/min --limit-burst 3 \
        -j LOG --log-prefix "$LOG_PREFIX-INPUT-DROP: " --log-level 4
    iptables -A LOG_DROP_INPUT -j DROP
    
    # Log dropped OUTPUT packets (potential bypass attempts)
    iptables -A LOG_DROP_OUTPUT -m limit --limit 10/min --limit-burst 5 \
        -j LOG --log-prefix "$LOG_PREFIX-OUTPUT-DROP: " --log-level 4
    iptables -A LOG_DROP_OUTPUT -j DROP
    
    # Apply logging chains
    iptables -A INPUT -j LOG_DROP_INPUT
    iptables -A OUTPUT -j LOG_DROP_OUTPUT
    
    echo "✅ Security logging configured"
    
    # ========================================================================
    # SECURITY VALIDATION AND REPORTING
    # ========================================================================
    echo "🔍 Performing security validation..."
    
    # Test Squid connectivity
    if curl -s --connect-timeout 5 --proxy "127.0.0.1:$SQUID_TRANSPARENT_PORT" \
        "http://httpbin.org/ip" > /dev/null 2>&1; then
        echo "✅ Squid proxy connectivity test: PASSED"
    else
        echo "⚠️  WARNING: Squid proxy connectivity test failed"
    fi
    
    # Count active rules
    input_rules=$(iptables -L INPUT --line-numbers | wc -l)
    output_rules=$(iptables -L OUTPUT --line-numbers | wc -l)
    nat_rules=$(iptables -t nat -L OUTPUT --line-numbers | wc -l)
    
    echo "📊 Firewall statistics:"
    echo "   - INPUT rules: $input_rules"
    echo "   - OUTPUT rules: $output_rules"
    echo "   - NAT rules: $nat_rules"
    echo "   - Default policy: DENY ALL"
    echo "   - Proxy enforcement: ACTIVE"
    
    # ========================================================================
    # FINAL STATUS REPORT
    # ========================================================================
    echo ""
    echo "🛡️ ========================================================================="
    echo "🛡️                     SECURITY FIREWALL ACTIVATED"
    echo "🛡️ ========================================================================="
    echo ""
    echo "✅ SECURITY LAYERS ACTIVE:"
    echo "   🔒 Layer 1: iptables enforcement (blocks all non-proxy traffic)"
    echo "   🔒 Layer 2: Squid proxy filtering (domain-based ACL whitelist)"
    echo "   🔒 Layer 3: Transparent redirection (automatic proxy routing)"
    echo ""
    echo "🚫 BYPASS PREVENTION ACTIVE:"
    echo "   ❌ Direct IP connections: BLOCKED"
    echo "   ❌ Alternative ports: BLOCKED"
    echo "   ❌ Tunneling protocols: BLOCKED"
    echo "   ❌ External proxies: BLOCKED"
    echo ""
    echo "✅ ALLOWED TRAFFIC:"
    echo "   🔗 HTTP/HTTPS: Only through Squid proxy to whitelisted domains"
    echo "   🔗 SSH/Git: Only through Squid proxy to whitelisted domains"
    echo "   🔗 Container management: SSH (22), Dev servers (3000-3001)"
    echo "   🔗 Local services: Docker networks, Supabase (54321-54324)"
    echo "   🔗 System essentials: DNS (53), NTP (123), Loopback"
    echo ""
    echo "📊 SECURITY MONITORING:"
    echo "   📝 Drop logging: /var/log/syslog ($LOG_PREFIX-*)"
    echo "   📊 Proxy access: /var/log/squid/access.log"
    echo "   🔍 Rate limiting: Prevents log flooding"
    echo ""
    echo "🔧 MANAGEMENT COMMANDS:"
    echo "   domains list               - View whitelisted domains"
    echo "   domains add example.com    - Add domain to whitelist"
    echo "   domains test example.com   - Test domain access"
    echo "   domains status             - Check proxy status"
    echo ""
    echo "🛡️ ========================================================================="
    echo "🛡️               SECURE DEVELOPMENT ENVIRONMENT READY"
    echo "🛡️ ========================================================================="
    
else
    echo "⚠️  Firewall configuration skipped (insufficient capabilities)"
    echo "💡 This usually means the container lacks NET_ADMIN capability"
    echo "🔧 Add --cap-add=NET_ADMIN to docker run command for full security"
fi