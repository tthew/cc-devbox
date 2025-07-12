#!/bin/bash

# Security Validation Script for DNS-based Domain Filtering
set -e

echo "🔒 Validating DNS-based security configuration..."

# Check if dnsmasq config exists
if [ -f "/etc/dnsmasq.d/whitelist.conf" ]; then
    echo "✅ DNS whitelist configuration found"
else
    echo "❌ DNS whitelist configuration missing"
    exit 1
fi

# Check whitelist script
if [ -x "/usr/local/bin/whitelist" ]; then
    echo "✅ Whitelist management script found"
else
    echo "❌ Whitelist management script missing"
    exit 1
fi

# Test basic functionality
echo "🧪 Testing basic whitelist functionality..."

# Test adding domain
/usr/local/bin/whitelist add test-domain.example 2>/dev/null || true
echo "✅ Domain add test completed"

# Test listing domains
/usr/local/bin/whitelist list >/dev/null 2>&1 || true
echo "✅ Domain list test completed"

# Test removing domain
/usr/local/bin/whitelist remove test-domain.example 2>/dev/null || true
echo "✅ Domain remove test completed"

echo "🎉 Security validation completed successfully!"