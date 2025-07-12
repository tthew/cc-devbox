#!/bin/bash

# Claude Code Development Environment Entrypoint Script
set -e

echo "🚀 Starting Claude Code Development Environment..."

# Function to validate required environment variables
validate_environment() {
    echo "🔍 Validating environment variables..."
    
    # Required environment variables
    local required_vars=(
        "NEXT_PUBLIC_SUPABASE_URL"
        "NEXT_PUBLIC_SUPABASE_ANON_KEY"
        "SUPABASE_SERVICE_ROLE_KEY"
        "DATABASE_URL"
        "DIRECT_URL"
        "JWT_SECRET"
        "NEXTAUTH_SECRET"
        "NEXTAUTH_URL"
    )
    
    local missing_vars=()
    
    # Check each required variable
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # Report missing variables
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "❌ Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""
        echo "Please ensure you have:"
        echo "1. Created .env.host file (copy from .env.host.example)"
        echo "2. Set all required environment variables"
        echo "3. Sourced the environment: source .env.host"
        echo ""
        echo "See .env.template for all required variables"
        exit 1
    fi
    
    # Validate JWT_SECRET length
    if [ ${#JWT_SECRET} -lt 32 ]; then
        echo "❌ JWT_SECRET must be at least 32 characters long"
        echo "Generate a secure secret with: openssl rand -hex 32"
        exit 1
    fi
    
    echo "✅ All required environment variables are set"
}

# Start dnsmasq for domain whitelist
echo "🔍 Starting dnsmasq with domain whitelist..."
dnsmasq --conf-file=/etc/dnsmasq.conf --pid-file=/var/run/dnsmasq.pid
echo "✅ dnsmasq started with domain whitelist"

# Initialize firewall with DNS-based filtering
/usr/local/bin/init-firewall.sh

# Set container DNS to use local dnsmasq
echo "🔧 Configuring container DNS to use local dnsmasq..."
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "✅ DNS configured to use local dnsmasq"

# Setup log management
echo "📝 Setting up log management..."
# Start cron for log rotation
service cron start

# Setup log cleanup cron job (run every hour)
echo "0 * * * * /usr/local/bin/log-cleanup.sh" | crontab -

# Initial log directory setup
mkdir -p /var/log/firewall /var/log/dnsmasq /workspace/logs
chown dev:dev /workspace/logs

echo "✅ Log management configured"

# Skip initial domain resolution to speed up startup
# Domains will be resolved on-demand when accessed
echo "✅ Domain whitelist configured (resolution on-demand)"

# Start SSH service
service ssh start
echo "✅ SSH service started (available on port 2222)"

# Fix workspace ownership for git operations
echo "🔧 Fixing workspace ownership for git..."
chown dev:dev /workspace
echo "✅ Workspace ownership fixed"

# Git is already configured in Dockerfile
echo "✅ Git configuration already set up"

# Switch to dev user for the rest of the setup
su - dev << 'EOF'
cd /workspace

# Check if we're in a valid project directory
if [ ! -f "package.json" ]; then
    echo "❌ No package.json found in /workspace"
    echo "Make sure you've mounted the project directory correctly"
    exit 1
fi

echo "📦 Installing/updating npm dependencies..."
npm install

echo "🔧 Setting up development environment..."

# Git is fully configured in Dockerfile
echo "✅ Git configuration loaded from Dockerfile"

# Performance optimizations (Claude Code inspired)
echo "⚡ Applying performance optimizations..."
# Disable git status in prompt for performance
echo 'export GIT_PS1_SHOWDIRTYSTATE=' >> ~/.bashrc
echo 'export GIT_PS1_SHOWDIRTYSTATE=' >> ~/.zshrc
echo "✅ Performance optimizations applied"

EOF

# Validate environment variables before generating .env.local
validate_environment

# Generate .env.local dynamically from environment variables
echo "📝 Creating .env.local from environment variables..."
su - dev << 'ENVEOF'
cd /workspace

# Generate .env.local with environment variable substitution
cat > .env.local << ENVFILE
# Supabase Configuration (Host Services)
# Generated dynamically from environment variables
NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}

# Database URLs (Host Services)
DATABASE_URL=${DATABASE_URL}
DIRECT_URL=${DIRECT_URL}

# JWT Configuration
JWT_SECRET=${JWT_SECRET}

# Storage Configuration (Host Services)
S3_ACCESS_KEY=${S3_ACCESS_KEY:-}
S3_SECRET_KEY=${S3_SECRET_KEY:-}
S3_REGION=${S3_REGION:-local}

# Development URLs (Host Services)
SUPABASE_STUDIO_URL=${SUPABASE_STUDIO_URL:-http://host.docker.internal:54323}
INBUCKET_URL=${INBUCKET_URL:-http://host.docker.internal:54324}

# Next.js Configuration
NEXTAUTH_URL=${NEXTAUTH_URL}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Development Environment
NODE_ENV=${NODE_ENV:-development}
NEXT_TELEMETRY_DISABLED=${NEXT_TELEMETRY_DISABLED:-1}
ENVFILE

# Verify the file was created correctly
if [ -f ".env.local" ]; then
    echo "✅ .env.local file created successfully"
    echo "📋 Key configurations:"
    echo "  SUPABASE_URL: ${NEXT_PUBLIC_SUPABASE_URL}"
    echo "  DATABASE_URL: ${DATABASE_URL}"
    echo "  STUDIO_URL: ${SUPABASE_STUDIO_URL:-http://host.docker.internal:54323}"
    echo "  NODE_ENV: ${NODE_ENV:-development}"
else
    echo "❌ Failed to create .env.local file"
    exit 1
fi

# Set up Claude Code aliases for both bash and zsh
echo "🤖 Setting up Claude Code aliases..."

# Create aliases for bash
cat >> ~/.bashrc << 'ALIASEOF'

# Claude Code aliases
alias claude='claude --dangerously-skip-permissions'
alias claude-dev='claude --dangerously-skip-permissions --project-dir /workspace'
alias dev-start='npm run dev'
alias dev-test='npm test'
alias dev-build='npm run build'
alias dev-lint='npm run lint'
alias dev-typecheck='npm run typecheck'

# Project shortcuts
alias goto-workspace='cd /workspace'
alias ll='ls -la'
alias la='ls -la'
alias l='ls -CF'

# Development helpers (Claude Code inspired)
alias logs='tail -f /workspace/debug.log'
alias serve='npm run dev'
alias check='npm run lint && npm run typecheck'
alias tree='tree -I node_modules'

# CLI tool aliases
alias python='python3'
alias pip='python3 -m pip'
alias uvx='uv tool run'

# Git aliases using delta
alias gd='git diff'
alias gs='git status'
alias gl='git log --oneline'

# Firewall and whitelist management aliases
alias whitelist='/usr/local/bin/manage-whitelist.sh'
alias firewall-status='iptables -L -n'
alias log-cleanup='log-cleanup.sh'
alias disk-usage='log-cleanup.sh --report'

# Help command to show welcome message
help() { source ~/.welcome.sh; }
welcome() { source ~/.welcome.sh; }
alias aliases='alias | grep -E "^(claude|dev-|goto|help|welcome)" | sort'
alias show-aliases='alias | sort'
ALIASEOF

# Create welcome script
cat > ~/.welcome.sh << 'WELCOMESCRIPT'
#!/bin/bash

# Only show welcome message if this is an interactive shell
if [[ $- == *i* ]] && [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || "$TERM_PROGRAM" == "SSH" ]]; then
    # Beautiful welcome header with colors
    echo ""
    print -P "%F{39}╭─────────────────────────────────────────────────────────────────────╮%f"
    print -P "%F{39}│%f  %F{114}⚡%f %F{39}Life In Hand Claude Development Environment%f  %F{114}⚡%f  %F{39}│%f"
    print -P "%F{39}╰─────────────────────────────────────────────────────────────────────╯%f"
    echo ""
    print -P "%F{220}📁%f %F{green}Project directory:%f %F{cyan}/workspace%f"
    echo ""
    print -P "%F{114}🔧 Available commands:%f"
    print -P "  %F{cyan}claude%f         : Launch Claude Code with permissions bypass"
    print -P "  %F{cyan}claude-dev%f     : Launch Claude Code in project directory"
    print -P "  %F{green}dev-start%f      : Start development server (npm run dev)"
    print -P "  %F{green}dev-test%f       : Run tests (npm test)"
    print -P "  %F{green}dev-build%f      : Build project (npm run build)"
    print -P "  %F{green}dev-lint%f       : Run linting (npm run lint)"
    print -P "  %F{green}dev-typecheck%f  : Run type checking (npm run typecheck)"
    print -P "  %F{yellow}goto-workspace%f : Navigate to project directory"
    print -P "  %F{yellow}check%f          : Run lint and typecheck"
    echo ""
    print -P "%F{red}🔒 Security & Whitelist Management:%f"
    print -P "  %F{magenta}whitelist%f      : Manage domain whitelist (add/remove/list/test)"
    print -P "  %F{magenta}firewall-status%f: Show current firewall rules"
    print -P "  %F{magenta}log-cleanup%f    : Manage log files and disk usage"
    print -P "  %F{magenta}disk-usage%f     : Show disk usage report"
    echo ""
    print -P "%F{blue}🛠️  CLI Tools available:%f"
    print -P "  %F{white}gh%f             : GitHub CLI"
    print -P "  %F{white}aws%f            : AWS CLI"
    print -P "  %F{white}uv%f             : Python package manager"
    print -P "  %F{white}uvx%f            : Python tool runner (uv tool run)"
    print -P "  %F{white}python%f         : Python 3"
    print -P "  %F{white}delta%f          : Enhanced git diffs"
    print -P "  %F{white}tree%f           : Directory tree view"
    print -P "  %F{white}fzf%f            : Fuzzy finder"
    echo ""
    print -P "%F{214}🐚 Shell Features:%f"
    print -P "  %F{green}Default shell%f  : ZSH with completion"
    print -P "  %F{green}History%f        : Persistent with 10k entries"
    print -P "  %F{green}Git aliases%f    : gd (diff), gs (status), gl (log)"
    echo ""
    print -P "%F{202}🔍 DNS & Security:%f"
    print -P "  %F{cyan}DNS Server%f     : Local dnsmasq with domain whitelist"
    print -P "  %F{cyan}Firewall%f       : iptables with domain-based filtering"
    print -P "  %F{cyan}Log Management%f : Automatic rotation and cleanup"
    echo ""
    print -P "%F{199}📚 Documentation:%f %F{underline}/workspace/.claude/README.md%f"
    print -P "%F{46}🌐 Development server:%f %F{underline}http://localhost:3000%f"
    print -P "%F{51}🗄️  Host Supabase services:%f"
    print -P "  %F{blue}API:%f %F{underline}${NEXT_PUBLIC_SUPABASE_URL:-http://host.docker.internal:54321}%f"
    print -P "  %F{blue}Studio:%f %F{underline}${SUPABASE_STUDIO_URL:-http://host.docker.internal:54323}%f"
    print -P "  %F{blue}Email:%f %F{underline}${INBUCKET_URL:-http://host.docker.internal:54324}%f"
    echo ""
    print -P "%F{226}💡 Pro Tips:%f"
    print -P "  %F{bright-green}claude%f         → Start Claude Code"
    print -P "  %F{bright-green}dev-start%f      → Start development server"
    print -P "  %F{bright-blue}help%f           → Show this message again"
    print -P "  %F{bright-blue}aliases%f        → Show main command shortcuts"
    print -P "  %F{bright-blue}show-aliases%f   → Show all available aliases"
    print -P "  %F{bright-yellow}ll%f             → List files with details"
    print -P "  %F{bright-magenta}src%f            → Just type directory name to navigate"
    echo ""
    print -P "%F{39}╭─ Happy coding! 🚀 ────────────────────────────────────────────────╮%f"
    print -P "%F{39}│%f   %F{220}Claude Code Development Environment is ready for action!%f   %F{39}│%f"
    print -P "%F{39}╰────────────────────────────────────────────────────────────────────╯%f"
    echo ""
fi
WELCOMESCRIPT

chmod +x ~/.welcome.sh

# Create enhanced ZSH configuration
cat >> ~/.zshrc << 'ZSHEOF'

# Enhanced ZSH Configuration for Claude Code Development Environment
# =================================================================

# Load colors
autoload -U colors && colors

# Enhanced completion system with beautiful colors
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''

# Better history
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Better directory navigation
setopt AUTO_CD              # Type directory name to cd
setopt AUTO_PUSHD           # Make cd push old directory onto directory stack
setopt PUSHD_IGNORE_DUPS    # Don't push duplicate directories
setopt PUSHD_SILENT         # Don't print directory stack after pushd/popd

# Enhanced prompt with git info and beautiful styling
autoload -Uz vcs_info
precmd() { 
    vcs_info
    # Add a subtle separator line for visual clarity
    print -P "%F{240}%{$(printf '─%.0s' {1..$(tput cols)})%}%f"
}

# Configure git info display
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{magenta}⎇ %b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}⎇ %b%f %F{red}| %a%f'
setopt PROMPT_SUBST

# Beautiful multi-line prompt with icons and colors
PROMPT='
%F{39}╭─%f %F{114}⚡%f %F{39}claude-dev%f %F{240}│%f %F{220}📁 %~%f${vcs_info_msg_0_}
%F{39}╰─%f %F{46}❯%f '

# Right-side prompt with time and status
RPROMPT='%F{240}%D{%H:%M:%S}%f'

# Claude Code aliases with beautiful feedback and --model sonnet
alias claude='echo "🤖 Launching Claude Code..." && claude --dangerously-skip-permissions --model sonnet'
alias claude-dev='echo "🤖 Launching Claude Code in project..." && claude --dangerously-skip-permissions --model sonnet --project-dir /workspace'
alias dev-start='echo "🚀 Starting development server..." && npm run dev'
alias dev-test='echo "🧪 Running tests..." && npm test'
alias dev-build='echo "🏗️ Building project..." && npm run build'
alias dev-lint='echo "🔍 Linting code..." && npm run lint'
alias dev-typecheck='echo "📝 Type checking..." && npm run typecheck'

# Project shortcuts with visual feedback
alias goto-workspace='echo "🏠 Navigating to workspace..." && cd /workspace'

# Development helpers (Claude Code inspired) with emojis
alias logs='echo "📋 Viewing development logs..." && tail -f /workspace/debug.log'
alias serve='echo "🚀 Starting development server..." && npm run dev'
alias check='echo "✅ Running lint and typecheck..." && npm run lint && npm run typecheck'
alias tree='tree -I node_modules --dirsfirst -C'

# CLI tool aliases
alias python='python3'
alias pip='python3 -m pip'
alias uvx='uv tool run'

# Git aliases using delta
alias gd='git diff'
alias gs='git status'
alias gl='git log --oneline'

# Firewall and whitelist management aliases
alias whitelist='/usr/local/bin/manage-whitelist.sh'
alias firewall-status='iptables -L -n'
alias log-cleanup='log-cleanup.sh'
alias disk-usage='log-cleanup.sh --report'

# Enhanced directory listing with colors and beautiful formatting
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lt='ls -altr --color=auto'  # List by time
alias lh='ls -alh --color=auto'   # Human readable sizes

# Colorized grep and other tools
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# Quick navigation aliases with visual feedback
alias ..='echo "📁 Going up..." && cd ..'
alias ...='echo "📁 Going up 2 levels..." && cd ../..'
alias ....='echo "📁 Going up 3 levels..." && cd ../../..'

# Development shortcuts
alias ports='netstat -tuln'
alias processes='ps aux'

# Git shortcuts with beautiful feedback and emojis
alias ga='echo "📦 Adding files to git..." && git add'
alias gc='echo "💾 Committing changes..." && git commit'
alias gp='echo "🚀 Pushing to remote..." && git push'
alias gpu='echo "⬇️ Pulling from remote..." && git pull'
alias gco='echo "🔀 Switching branch..." && git checkout'
alias gb='echo "🌿 Listing branches..." && git branch --color=always'
alias gst='echo "📊 Git status..." && git status'

# NPM shortcuts with beautiful feedback
alias ni='echo "📦 Installing npm packages..." && npm install'
alias nr='echo "🏃 Running npm script..." && npm run'
alias ns='echo "▶️ Starting npm..." && npm start'
alias nt='echo "🧪 Running npm tests..." && npm test'

# Help command to show welcome message
help() { source ~/.welcome.sh; }
welcome() { source ~/.welcome.sh; }
alias aliases='alias | grep -E "^(claude|dev-|goto|help|welcome)" | sort'
alias show-aliases='alias | sort'

# Show welcome message on login
source ~/.welcome.sh

# Navigate to workspace on login
cd /workspace 2>/dev/null || true

ZSHEOF

echo "✅ Development environment setup complete!"
echo "🎯 Welcome message will be shown when you SSH into the container"
echo "🔌 SSH access: ssh dev@localhost -p 2222 (password: dev)"

ENVEOF

# Keep the container running
echo "🔄 Container is ready!"
echo "🔌 SSH access: ssh dev@localhost -p 2222"
echo "🔑 Password: dev"
echo "🤖 Once inside, run 'claude' to start Claude Code"

# Start a simple service to keep container alive
tail -f /dev/null