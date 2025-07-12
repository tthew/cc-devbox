#!/bin/bash

# Security Hardening Script for Squid Proxy Firewall
set -e

echo "🔒 Implementing security hardening for proxy firewall..."

apply_security_rules() {
    echo "🛡️ Applying iptables security enforcement..."
    
    # Check if iptables is available
    if ! command -v iptables >/dev/null 2>&1; then
        echo "⚠️ iptables not available - skipping network enforcement"
        return 0
    fi
    
    # Flush existing rules and set secure defaults
    iptables -F OUTPUT 2>/dev/null || true
    iptables -P OUTPUT DROP 2>/dev/null || true     # Block all outbound by default
    
    # Allow loopback and local traffic
    iptables -A OUTPUT -o lo -j ACCEPT 2>/dev/null || true
    iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT 2>/dev/null || true
    
    # Allow Squid proxy ports ONLY
    iptables -A OUTPUT -p tcp --dport 3128 -j ACCEPT 2>/dev/null || true  # Transparent proxy
    iptables -A OUTPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true  # Explicit proxy
    
    # Allow DNS queries (required for domain filtering)
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
    
    # Allow Squid to make outbound HTTP/HTTPS connections
    iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true   # HTTP
    iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true  # HTTPS
    
    # Allow established connections
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    
    # Log and drop everything else
    iptables -A OUTPUT -j LOG --log-prefix "FIREWALL-BLOCKED: " 2>/dev/null || true
    iptables -A OUTPUT -j DROP
    
    echo "✅ Security enforcement rules applied"
}

force_proxy_environment() {
    echo "🔧 Configuring mandatory proxy environment..."
    
    # Force proxy environment variables
    cat > /etc/environment << 'EOF'
http_proxy=http://127.0.0.1:3128
https_proxy=http://127.0.0.1:3128
HTTP_PROXY=http://127.0.0.1:3128
HTTPS_PROXY=http://127.0.0.1:3128
no_proxy=localhost,127.0.0.1
EOF
    
    echo "✅ Proxy environment configured"
}

main() {
    echo "🚀 Starting security hardening..."
    sleep 3  # Wait for Squid
    apply_security_rules
    force_proxy_environment
    echo "🎉 Security hardening completed!"
}

main "$@"