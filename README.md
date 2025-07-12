# Claude Code Development Environment

A streamlined, secure containerized development environment optimized for Claude Code with DNS-based domain filtering and comprehensive development tools.

## Features

### 🔒 Security & Network Filtering
- **DNS-based Domain Filtering**: Whitelist-only network access using dnsmasq
- **Real-time Monitoring**: Track blocked/allowed requests with `monitor-blocks.sh`
- **Secure Container**: Isolated environment with minimal attack surface

### 🚀 Development Experience  
- **Claude Code Integration**: Pre-configured with launcher scripts and proper permissions
- **Enhanced Shell**: ZSH with autocompletion, persistent history, and development aliases
- **Development Tools**: Node.js 20 LTS, Python 3 with uv, GitHub CLI, AWS CLI, Supabase CLI
- **Persistent Environment**: Home directory and configurations survive container restarts

### 🛠️ Management & Automation
- **Make-based Commands**: 20+ commands for container lifecycle management
- **Whitelist Management**: Simple commands to add/remove domains (`whitelist add domain.com`)
- **Environment Validation**: Automated setup and configuration validation
- **Performance Optimized**: M4 Pro specific optimizations with 8GB memory allocation

## Quick Start

### 1. Clone and Setup
```bash
git clone git@github.com:tthew/cc-devbox.git
cd cc-devbox

# Build and start the development environment
make first-run
```

### 2. Start Development
```bash
# Start the container
make start
```

### 3. Access Development Environment
```bash
# SSH into the environment  
make shell

# Launch Claude Code (inside container)
claude
```

## Core Commands

### Container Management
- `make start` - Start the development environment
- `make stop` - Stop the development environment
- `make restart` - Restart the environment
- `make shell` - SSH into the container
- `make claude` - Launch Claude Code directly
- `make status` - Show container and port status
- `make logs` - View container logs
- `make clean` - Clean up containers and volumes

### Environment Management
- `make first-run` - Complete first-time setup
- `make check-env` - Validate environment variables
- `make rebuild` - Full rebuild with no cache

## Domain Whitelist Management

### Inside the Container
```bash
# Add domains to whitelist
whitelist add github.com
whitelist add anthropic.com

# Remove domains
whitelist remove domain.com

# List whitelisted domains
whitelist list

# Monitor blocked/allowed requests
monitor-blocks.sh summary    # Show stats and recent activity
monitor-blocks.sh monitor    # Real-time monitoring
monitor-blocks.sh blocked    # Show only blocked requests
monitor-blocks.sh allowed    # Show only allowed requests
```

## Configuration

### Git Configuration

The container requires git user configuration to function properly. You have two options:

#### Option 1: Environment Variables (Recommended)
Create a `.env.host` file in the project root:
```bash
# .env.host (git-ignored)
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"
```

Then source it before starting the container:
```bash
source .env.host
make start
```

#### Option 2: Container Environment
Set environment variables when starting:
```bash
docker-compose run -e GIT_USER_NAME="Your Name" -e GIT_USER_EMAIL="your.email@example.com" claude-dev
```

If no configuration is provided, defaults will be used that remind you to configure properly.

## Architecture

### Core Components
- **Dockerfile**: Ubuntu 24.04 with development tools and Claude Code
- **docker-compose.yml**: Container orchestration with resource limits
- **entrypoint.sh**: Container initialization and DNS filtering setup
- **Makefile**: Comprehensive command interface

### Network Security
- **DNS Filtering**: `whitelist.conf` configures dnsmasq for domain filtering
- **Default Deny**: All domains blocked by default, only whitelisted domains allowed
- **Real-time Monitoring**: DNS queries logged to `/workspace/logs/dnsmasq.log`

### Development Tools
- **Shell Scripts**: 
  - `scripts/claude-launcher.sh` - Claude Code management
  - `scripts/dev-helper.sh` - Development task automation
  - `manage-whitelist.sh` - Advanced domain and IP management
  - `monitor-blocks.sh` - Network activity monitoring

### Persistent Storage
- `/workspace` - Main project directory (mounted from host)
- `dev-home/` - Persistent user configuration and Claude Code data
- Environment configurations and SSH keys persist across rebuilds

## Security Model

### Network Isolation
- Only whitelisted domains can be accessed
- DNS queries are filtered through dnsmasq
- All blocked requests are logged and can be monitored

### Container Security
- Runs as non-root `dev` user for development work
- Limited capabilities (NET_ADMIN, NET_RAW for network management only)
- Isolated file system with controlled volume mounts

### Secret Management
- SSH keys and authentication data in persistent `dev-home/`
- No hardcoded credentials in the codebase
- All secrets managed through secure container access

## Troubleshooting

### Container Issues
```bash
# Check container status
make status

# View logs
make logs

# Restart container
make restart
```

### Network/DNS Issues
```bash
# Inside container - test DNS resolution
nslookup domain.com

# Monitor DNS activity
monitor-blocks.sh monitor

# Check whitelist
whitelist list
```

### Environment Issues
```bash
# Validate environment
make check-env

# Show environment status
make env-status

# Rebuild if needed
make rebuild
```

## File Structure

```
cc-devbox/
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Container orchestration  
├── Makefile                   # Command interface
├── entrypoint.sh             # Container initialization
├── whitelist.conf            # DNS filtering configuration
├── CLAUDE.md                 # Claude Code specific documentation
├── scripts/
│   ├── claude-launcher.sh    # Claude Code management
│   └── dev-helper.sh         # Development helpers
├── monitor-blocks.sh         # Network monitoring tool
├── manage-whitelist.sh       # Advanced whitelist management
└── dev-home/                 # Persistent user configuration
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes thoroughly with `make rebuild`
4. Ensure security and documentation are updated
5. Submit a pull request

## License

This project is designed for development use and includes security features for safe coding environments.