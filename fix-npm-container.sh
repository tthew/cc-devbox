#!/bin/bash

# Fix npm installation issues in container
set -e

echo "🔧 Fixing npm installation issues in container..."

# Fix 1: Clear npm cache and node_modules completely
echo "🧹 Cleaning npm cache and node_modules..."
rm -rf /workspace/node_modules
rm -rf /workspace/.npm-cache
rm -rf ~/.npm/_logs
npm cache clean --force

# Fix 2: Set proper permissions for npm directories
echo "🔐 Setting proper npm permissions..."
mkdir -p /workspace/.npm-cache
chown -R dev:dev /workspace/.npm-cache
chmod -R 755 /workspace/.npm-cache

# Fix 3: Configure npm to avoid permission issues
echo "📝 Configuring npm settings..."
npm config set cache /workspace/.npm-cache
npm config set unsafe-perm true
npm config set user 0
npm config set audit false
npm config set fund false

# Fix 4: Install dependencies with specific flags to avoid issues
echo "📦 Installing dependencies with optimized settings..."
npm install --no-audit --no-fund --unsafe-perm --cache /workspace/.npm-cache

echo "✅ npm installation fix complete!"