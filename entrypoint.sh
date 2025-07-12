#!/bin/bash

# Claude Code Development Environment Entrypoint Script
set -e

echo "🚀 Starting Claude Code Development Environment..."

# Initialize DNS-based domain filtering
echo "🌐 Starting DNS domain filtering..."

# Create directories and files
mkdir -p /workspace/logs
mkdir -p /workspace/.claude
touch /etc/whitelist-domains.conf
chown -R dev:dev /workspace/logs
chown -R dev:dev /workspace/.claude
chown -R dev:dev /etc/dnsmasq.d/
chown dev:dev /etc/whitelist-domains.conf

# Configure DNS-based domain filtering with dnsmasq
echo "🔧 Configuring DNS-based domain filtering..."

# Backup original resolv.conf
if [ ! -f /etc/resolv.conf.backup ]; then
    cp /etc/resolv.conf /etc/resolv.conf.backup
fi

# Configure container to use local dnsmasq for DNS resolution
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Start dnsmasq with whitelist configuration
echo "🌐 Starting dnsmasq DNS filtering service..."
dnsmasq --conf-file=/etc/dnsmasq.d/whitelist.conf --log-queries --log-facility=/workspace/logs/dnsmasq.log

# Verify dnsmasq is running
if pgrep dnsmasq > /dev/null; then
    echo "✅ DNS filtering service started successfully"
    echo "📝 DNS queries logged to /workspace/logs/dnsmasq.log"
else
    echo "❌ Failed to start DNS filtering service"
    # Fallback to backup resolv.conf
    cp /etc/resolv.conf.backup /etc/resolv.conf
fi

# Start SSH service
service ssh start
echo "✅ SSH service started (available on port 2222)"

# Fix workspace ownership for git operations
echo "🔧 Fixing workspace ownership for git..."
chown dev:dev /workspace
chown -R dev:dev /workspace/.git 2>/dev/null || true
chown -R dev:dev /workspace/.env* 2>/dev/null || true
chown dev:dev /workspace/package.json 2>/dev/null || true
chown dev:dev /workspace/package-lock.json 2>/dev/null || true

# Fix node_modules volume permissions and npm cache issues
echo "🔧 Fixing node_modules permissions and npm setup..."
mkdir -p /workspace/.npm-cache
chown -R dev:dev /workspace/.npm-cache
chmod -R 755 /workspace/.npm-cache

# Fix node_modules permissions
chown -R dev:dev /workspace/node_modules 2>/dev/null || true
chmod -R u+w /workspace/node_modules 2>/dev/null || true

# Configure npm for the dev user
su - dev << 'NPM_CONFIG'
cd /workspace
npm config set cache /workspace/.npm-cache
npm config set unsafe-perm true
npm config set audit false
npm config set fund false
NPM_CONFIG

# Setup dev user home directory
echo "🔧 Setting up dev user home directory..."
su - dev << 'HOME_SETUP'
cd ~

# Create essential directories
mkdir -p ~/.local/bin ~/.local/share ~/.config ~/.npm-global
chmod 755 ~/.local ~/.local/bin ~/.local/share ~/.config ~/.npm-global

# Disable Ubuntu welcome messages
touch ~/.hushlogin

# Configure npm global directory if not already set
if ! grep -q "npm-global" ~/.bashrc 2>/dev/null; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
fi
if ! grep -q "npm-global" ~/.zshrc 2>/dev/null; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
fi

# Set npm global prefix if not already set
npm config set prefix ~/.npm-global 2>/dev/null || true

# Install Claude Code if not already installed
if ! command -v claude >/dev/null 2>&1; then
    echo "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code --no-audit --no-fund
fi

# Install uv if not already installed
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv Python package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Ensure PATH includes ~/.local/bin for uv/uvx
if ! grep -q ".local/bin" ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
if ! grep -q ".local/bin" ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

# Configure git if not already configured
if [ ! -f ~/.gitconfig ]; then
    git config --global user.name "Matt Richards"
    git config --global user.email "m@tthew.berlin"
    git config --global init.defaultBranch main
    git config --global push.default simple
    git config --global pull.rebase false
    git config --global safe.directory /workspace
    git config --global safe.directory '*'
fi

# Configure shell history persistence if not already set
if ! grep -q "HISTFILE=.*local/share" ~/.zshrc 2>/dev/null; then
    echo 'export HISTFILE=~/.local/share/zsh/history' >> ~/.zshrc
    echo 'export HISTSIZE=10000' >> ~/.zshrc
    echo 'export SAVEHIST=10000' >> ~/.zshrc
fi

# Create history directories
mkdir -p ~/.local/share/zsh ~/.local/share/bash
HOME_SETUP

# Fix npm global binaries permissions for dev user
echo "🔧 Fixing npm global binaries permissions..."
chown -R dev:dev /home/dev/.npm-global 2>/dev/null || true
chmod -R u+x /home/dev/.npm-global/bin 2>/dev/null || true

echo "✅ Workspace ownership fixed"

# Fix git safe directory configuration
echo "🔧 Configuring git safe directories..."
su - dev << 'GITEOF'
git config --global --add safe.directory /workspace
git config --global --add safe.directory '*'

cd /workspace
echo "Testing git status:"
git status --porcelain > /dev/null 2>&1 && echo "✅ Git is working correctly" || echo "⚠️ Git may have issues"
GITEOF

# Check if .env.local exists and set proper ownership
echo "🔧 Checking .env.local file ownership..."
if [ -f "/workspace/.env.local" ]; then
    chown dev:dev /workspace/.env.local
    chmod 644 /workspace/.env.local
    echo "✅ .env.local file ownership set correctly"
else
    echo "⚠️ No .env.local file found in workspace"
fi

echo "✅ Complete setup finished!"
echo "🔄 Container is ready!"
echo "🔌 SSH access: ssh dev@localhost -p 2222"
echo "🔑 Password: dev"
echo "🤖 Once inside, run 'claude' to start Claude Code"

# Keep the container running
tail -f /dev/null