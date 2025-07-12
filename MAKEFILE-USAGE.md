# Makefile Usage Guide

## Overview

The updated Makefile now includes comprehensive environment variable management and validation. All Docker Compose commands automatically source the `.env.host` file to ensure proper secret management.

## 🚀 Quick Start

### First Time Setup

```bash
# Complete first-time setup (recommended)
make first-run

# OR step-by-step:
make setup-env    # Create .env.host from example
# Edit .env.host with your secrets
make check-env    # Validate configuration
make start        # Start the environment
```

### Daily Development

```bash
make start        # Start development environment
make shell        # SSH into container
make claude       # Launch Claude Code directly
make logs         # View container logs
make stop         # Stop environment
```

## 📋 Available Commands

### Environment Management
- `make setup-env` - Create `.env.host` from example template
- `make check-env` - Validate all required environment variables
- `make env-status` - Show comprehensive environment status
- `make first-run` - Interactive first-time setup workflow

### Container Operations
- `make build` - Build development container (with environment validation)
- `make start` - Start development environment (with environment validation)
- `make stop` - Stop development environment
- `make restart` - Restart development environment
- `make rebuild` - Full rebuild with clean cache

### Development Workflow
- `make shell` - SSH into development container
- `make mosh` - Connect via Mosh (better for unstable connections)
- `make claude` - SSH into container and launch Claude Code
- `make logs` - View real-time container logs

### Status & Monitoring
- `make status` - Show container and port status
- `make env-status` - Show environment configuration status
- `make clean` - Clean up containers and volumes

### Utilities
- `make dev` - Quick development workflow (start + open browser)
- `make update-claude` - Update Claude Code CLI in container
- `make backup` - Backup container configuration
- `make info` - Show detailed environment information

## 🔒 Security Features

### Automatic Environment Validation

All Docker operations automatically:
1. **Check for `.env.host`** - Ensures environment file exists
2. **Validate required variables** - Verifies all secrets are set
3. **Source environment** - Loads variables before Docker Compose
4. **Fail fast** - Stops execution if configuration is invalid

### Environment Status Checking

```bash
# Check environment configuration
make env-status

# Sample output:
🔧 Environment Configuration Status
==================================

📁 Files:
  .env.template: ✅ Exists
  .env.host.example: ✅ Exists  
  .env.host: ✅ Exists

🔍 Environment Variables:
  NEXT_PUBLIC_SUPABASE_URL: ✅ Set
  JWT_SECRET: ✅ Set (hidden)
  NEXTAUTH_SECRET: ✅ Set (hidden)

🔒 Security:
  .env.host gitignored: ✅ Protected
  Templates not gitignored: ✅ Available
```

## 🛠️ Troubleshooting

### Missing Environment File

```bash
❌ .env.host file not found
   Run 'make setup-env' to create it

# Solution:
make setup-env
```

### Missing Environment Variables

```bash
❌ 3 required variables are missing
   Edit .env.host and set all required variables

# Solution:
# Edit .env.host with your actual secrets
make check-env  # Verify fixes
```

### Environment Not Loading

```bash
# Check if Docker Compose can read variables
make env-status

# If variables show as missing in env-status but exist in .env.host:
# Ensure no syntax errors in .env.host (no spaces around =)
```

## 🔄 Development Workflow Examples

### New Developer Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd .claude

# 2. First-time setup
make first-run
# Follow prompts to edit .env.host

# 3. Start developing  
make claude  # Launch Claude Code
```

### Daily Development

```bash
# Start the day
make start

# Work with Claude Code
make claude

# Check logs if needed
make logs

# End of day
make stop
```

### Updating Secrets

```bash
# Edit environment
nano .env.host

# Validate changes
make check-env

# Restart with new environment
make restart
```

### Debugging Issues

```bash
# Check overall status
make env-status
make status

# View detailed logs
make logs

# Clean rebuild if needed
make clean
make rebuild
```

## 🔧 Advanced Usage

### Custom Environment File

```bash
# Use different environment file
ENV_FILE=.env.production make start
```

### Manual Environment Loading

```bash
# For debugging - manually load environment
source .env.host
docker-compose config  # Verify variables loaded
```

### Bypassing Validation

```bash
# Emergency bypass (not recommended)
docker-compose up  # Won't have environment variables
```

## 📚 Related Documentation

- [SECURITY-SETUP.md](./SECURITY-SETUP.md) - Detailed security setup guide
- [.env.template](./.env.template) - Template for environment variables
- [.env.host.example](./.env.host.example) - Example configuration