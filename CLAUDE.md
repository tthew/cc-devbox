# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment Commands

This is a Docker-based development environment for Claude Code with DNS filtering and security features.

### Essential Commands
- `make start` - Start the development environment
- `make stop` - Stop the development environment  
- `make shell` - SSH into the development container (password: dev)
- `make claude` - SSH into container and launch Claude Code directly
- `make status` - Show container and port status
- `make logs` - View container logs
- `make restart` - Restart the development environment
- `make clean` - Clean up containers and volumes

### Environment Setup
- `make first-run` - Complete first-time setup (builds and starts container)
- `make rebuild` - Full rebuild (clean build with --no-cache)
- `make clean` - Clean up containers and volumes

### Inside the Container
Once you SSH into the container (`make shell`), use these commands:
- `claude` - Launch Claude Code with proper configuration
- `whitelist add domain.com` - Add domains to network whitelist
- `whitelist list` - Show whitelisted domains
- `monitor-blocks.sh` - Monitor network activity and blocked requests

## Architecture Overview

### Container Structure
This is a secure, containerized development environment that provides:
- **Base Environment**: Ubuntu 24.04 with Node.js 20 LTS, Python 3, and development tools
- **Security Features**: DNS-based domain filtering with dnsmasq, whitelist-only network access
- **Development Tools**: Claude Code CLI, GitHub CLI (gh), AWS CLI, Supabase CLI, Python uv package manager
- **Shell Environment**: Enhanced ZSH with autocompletion, persistent history, and development aliases

### Key Components
- **Docker Container**: Main development environment (`life-in-hand-claude-dev`)
- **Volume Mounts**: 
  - `/Users/tthew/Development:/workspace` (entire Development directory)
  - `dev-home/:/home/dev` (persistent home directory with Claude Code data)
- **Network Access**: SSH on port 2222, development server on port 3000
- **Security**: DNS filtering with whitelist-only access, network monitoring

### Directory Structure
- `/workspace` - Main project directory (mounted from host)
- `/workspace/logs` - Container logs and DNS query logs
- `scripts/` - Helper scripts (claude-launcher.sh, dev-helper.sh)
- `dev-home/` - Persistent user configuration, Claude Code sessions, SSH keys

### Environment Requirements
- **Prerequisites**: Docker and Docker Compose installed
- **System Requirements**: Sufficient memory allocation (8GB+ recommended)
- **Port Availability**: SSH port 2222 and web ports 3000-3001

### Development Workflow
1. Run `make first-run` for initial setup (builds and starts container)
2. Use `make shell` to access the development environment
3. Run `claude` inside the container to launch Claude Code
4. Use `whitelist add domain.com` to allow access to new domains as needed
5. Use `make stop` to stop the environment when done

### Security Architecture
- **Network Isolation**: Container runs with DNS-based domain filtering
- **Whitelist-Only Access**: Only explicitly allowed domains can be reached
- **Real-time Monitoring**: All DNS queries logged, blocked requests tracked
- **User Isolation**: All development work done as 'dev' user, not root
- **Persistent Security**: Whitelist and security settings survive container restarts

### Monitoring and Debugging
- **DNS Activity**: Use `monitor-blocks.sh summary` to see blocked/allowed requests
- **Real-time Monitoring**: Use `monitor-blocks.sh monitor` for live DNS query tracking
- **Network Issues**: Check `whitelist list` and add domains with `whitelist add domain.com`
- **Container Logs**: Use `make logs` to view container startup and DNS filtering logs

This environment is designed for secure, isolated development work with Claude Code while maintaining full development functionality and network security.