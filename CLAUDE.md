# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment Commands

This is a Docker-based development environment for Claude Code. Use the Makefile for all container management:

### Essential Commands
- `make first-run` - Complete first-time setup (creates .env.host, starts container)
- `make start` - Start the development environment
- `make stop` - Stop the development environment  
- `make shell` - SSH into the development container (password: dev)
- `make claude` - SSH into container and launch Claude Code directly
- `make status` - Show container and port status
- `make logs` - View container logs
- `make clean` - Clean up containers and volumes

### Environment Setup
- `make setup-env` - Create .env.host from example (required for first-time setup)
- `make check-env` - Validate environment variables
- `make env-status` - Show environment configuration status

### Container Management
- `make build` - Build the development container
- `make restart` - Restart the development environment
- `make rebuild` - Full rebuild (clean build with --no-cache)

### Inside the Container
Once you SSH into the container (`make shell`), use these commands:
- `claude` - Launch Claude Code with proper configuration
- `dev-start` - Start the development server (if applicable)
- `dev-helper.sh [command]` - Development task automation

## Architecture Overview

### Container Structure
This is a containerized development environment that provides:
- **Base Environment**: Ubuntu container with Node.js 20 LTS, Python 3, and development tools
- **Security Features**: DNS-based domain filtering with dnsmasq, firewall configuration with iptables
- **Development Tools**: Claude Code CLI, GitHub CLI (gh), AWS CLI, Supabase CLI, Python uv package manager
- **Shell Environment**: Enhanced ZSH with autocompletion, persistent history, and development aliases

### Key Components
- **Docker Container**: Main development environment (`life-in-hand-claude-dev`)
- **Volume Mounts**: 
  - `/Users/tthew/Development:/workspace` (entire Development directory)
  - `/Users/tthew/Development/cc-devbox/dev-home:/home/dev` (persistent home directory)
- **Network Access**: SSH on port 2222, development server on port 3000
- **Security**: DNS filtering, network capabilities (NET_ADMIN, NET_RAW), firewall rules

### Directory Structure
- `/workspace` - Main project directory (mounted from host)
- `/workspace/logs` - Container logs and DNS query logs
- `scripts/` - Helper scripts (claude-launcher.sh, dev-helper.sh)
- Configuration files for dnsmasq, firewall, and shell enhancements

### Environment Requirements
- **Prerequisites**: .env.host file with required environment variables
- **Required Variables**: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, DATABASE_URL, DIRECT_URL, JWT_SECRET, NEXTAUTH_SECRET, NEXTAUTH_URL
- **Secret Generation**: Use `openssl rand -hex 32` for JWT_SECRET, `openssl rand -base64 32` for NEXTAUTH_SECRET

### Development Workflow
1. Run `make first-run` for initial setup (creates .env.host, requires manual secret configuration)
2. Edit .env.host with actual secrets and Supabase configuration
3. Run `make start` to launch the container
4. Use `make shell` to access the development environment
5. Run `claude` inside the container to launch Claude Code
6. Development server and external services are accessed via port forwarding

### Security Architecture
- **Network Isolation**: Container runs with restricted network access
- **DNS Filtering**: Whitelist-based domain resolution using dnsmasq
- **Firewall Rules**: Automatic iptables configuration for traffic control
- **User Isolation**: All development work done as 'dev' user, not root
- **Capability Management**: Limited to essential network capabilities only

This environment is designed for secure, isolated development work with Claude Code while maintaining full development functionality.