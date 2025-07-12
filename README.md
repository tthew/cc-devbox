# Claude Code Development Environment

## Enhanced with Official Claude Code Best Practices

A containerized development environment for the Life In Hand project, enhanced with recommendations from the official [Claude Code repository](https://github.com/anthropics/claude-code) for a robust, secure, and optimized development experience.

## New Features Added (v2.0)

### 🔒 Security Enhancements
- **Firewall Configuration**: Automatic iptables rules for network security
- **Capability Management**: NET_ADMIN and NET_RAW capabilities for network management
- **Secure Port Configuration**: Only essential ports are exposed

### 🚀 Developer Experience
- **ZSH Shell**: Default shell with autocompletion and history management
- **Enhanced Git**: Delta for beautiful git diffs, persistent history
- **Performance Optimizations**: 4GB Node.js memory allocation, disabled git status in prompts
- **Persistent Storage**: History and configuration persist across container restarts

### 🛠️ Development Tools
- **Enhanced CLI Tools**: 
  - `delta` - Beautiful git diffs
  - `fzf` - Fuzzy finder
  - `tree` - Directory visualization
  - Enhanced shell aliases
- **Multi-Shell Support**: Aliases configured for both bash and zsh
- **VSCode Integration**: Recommended settings file included (`vscode-settings.json`)

## Quick Start

### 1. Build and Start the Environment

```bash
# Navigate to the .claude directory
cd .claude

# Build and start the development environment
docker-compose up --build -d

# Check container status
docker-compose ps
```

### 2. Access the Environment

#### SSH Access (Recommended)
```bash
# SSH into the development environment
ssh dev@localhost -p 2222

# Password: dev
```

#### Mosh Access (Better for Unstable Connections)
```bash
# Mosh into the development environment
mosh --ssh="ssh -p 2222" dev@localhost

# Password: dev
```

#### Direct Container Access
```bash
# Alternative: Access container directly
docker exec -it life-in-hand-claude-dev bash
```

### 3. Launch Claude Code

Once inside the container:

```bash
# Launch Claude Code with permission bypass
claude

# Or use the full command
claude-code --dangerously-skip-permissions

# Or launch in interactive mode
claude -i
```

## Container Features

### 🚀 Pre-installed Tools
- **Node.js 20 LTS** - Latest stable Node.js version
- **npm & pnpm** - Package managers
- **Claude Code CLI** - Latest version with auto-install
- **Supabase CLI** - Database management
- **GitHub CLI (gh)** - GitHub command line tool
- **AWS CLI** - Amazon Web Services command line interface
- **Python 3 with uv** - Modern Python package manager and tool runner
- **Git** - Version control
- **SSH Server** - Remote access
- **Development Tools** - vim, nano, htop, curl, wget, jq, mosh

### 🔧 Development Environment
- **Project Directory**: `/workspace` (mounted from host)
- **SSH Access**: `localhost:2222`
- **Mosh Access**: `localhost` (UDP ports 60000-61000)
- **Development Server**: `localhost:3000`
- **Host Supabase Services**: Uses host machine's Supabase instance
- **User**: `dev` (password: `dev`)

### 📦 Automatic Setup
- NPM dependencies installation
- Environment configuration
- SSH key generation
- Development aliases
- Claude Code optimization

## Usage Instructions

### Starting the Development Server

```bash
# Inside the container
dev-start

# Or using the helper script
dev-helper start

# Or directly
npm run dev
```

### Running Tests

```bash
# All tests
dev-helper test

# Specific test types
dev-helper test unit
dev-helper test integration
dev-helper test e2e
dev-helper test watch
```

### Quality Checks

```bash
# Run linting and type checking
dev-helper check

# Individual commands
dev-lint
dev-typecheck
```

### Database Management

```bash
# Setup database connection to host
dev-helper db

# Check host database connectivity
dev-helper check-db

# Individual commands (run on host machine)
npm run db:start    # Run this on host
npm run db:reset    # Run this on host
npm run db:studio   # Run this on host
```

### Claude Code Usage

```bash
# Launch Claude Code (recommended)
claude

# Launch with specific options
claude-launcher.sh -i          # Interactive mode
claude-launcher.sh -r          # Restart Claude Code
claude-launcher.sh -c          # Check installation
claude-launcher.sh -v          # Show version
```

### CLI Tools Usage

```bash
# GitHub CLI
gh auth login                  # Authenticate with GitHub
gh repo clone <repo>           # Clone repository
gh pr create                   # Create pull request
gh issue list                  # List issues

# AWS CLI
aws configure                  # Set up AWS credentials
aws s3 ls                      # List S3 buckets
aws ec2 describe-instances     # List EC2 instances

# Python with uv
uv --version                   # Check uv version
uv pip install <package>       # Install Python package
uvx <tool>                     # Run Python tools (alias for 'uv tool run')
python --version               # Check Python version
```

## Available Commands

### Built-in Aliases (automatically configured)
- `claude` - Launch Claude Code with permissions bypass
- `claude-dev` - Launch Claude Code in project directory
- `dev-start` - Start development server
- `dev-test` - Run tests
- `dev-build` - Build project
- `dev-lint` - Run linting
- `dev-typecheck` - Run type checking
- `goto-workspace` - Navigate to project directory
- `check` - Run lint and typecheck
- `logs` - View debug logs

### Helper Scripts
- `claude-launcher.sh` - Claude Code management
- `dev-helper.sh` - Development task automation

## Port Mapping

| Service | Container Port | Host Port | Description |
|---------|---------------|-----------|-------------|
| SSH | 22 | 2222 | SSH access |
| Mosh | 60000-61000/udp | 60000-61000/udp | Mosh access |
| Next.js Dev | 3000 | 3000 | Development server |
| Next.js Build | 3001 | 3001 | Build server |

**Note**: Supabase services run on the host machine and are accessed via `host.docker.internal:54321-54324`

## Environment Variables

The container automatically creates a `.env.local` file with development settings:

```env
# Supabase Configuration (Host Services)
NEXT_PUBLIC_SUPABASE_URL=http://host.docker.internal:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Development Settings
NODE_ENV=development
NEXT_TELEMETRY_DISABLED=1
```

## Project Structure

```
.claude/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Container orchestration
├── entrypoint.sh           # Container startup script
├── scripts/
│   ├── claude-launcher.sh  # Claude Code launcher
│   └── dev-helper.sh       # Development helper
└── README.md               # This file
```

## Common Workflows

### 1. Starting a New Development Session

```bash
# Start the container
docker-compose up -d

# SSH into the container
ssh dev@localhost -p 2222

# Launch Claude Code
claude

# Start development server (in another terminal)
dev-start
```

### 2. Running Tests Before Deployment

```bash
# Run all quality checks
dev-helper check

# Run all tests
dev-helper test all

# Build the project
dev-helper build
```

### 3. Database Development

```bash
# Check host database connectivity
dev-helper check-db

# Setup database connection to host
dev-helper db

# Open database studio (on host machine)
# Navigate to http://localhost:54322
```

### 4. Debugging Issues

```bash
# Check project status
dev-helper status

# View logs
logs

# Restart development server
dev-helper start
```

## Troubleshooting

### Container Won't Start
```bash
# Check container logs
docker-compose logs claude-dev

# Rebuild container
docker-compose down
docker-compose up --build -d
```

### SSH Connection Issues
```bash
# Check if SSH service is running
docker exec life-in-hand-claude-dev service ssh status

# Restart SSH service
docker exec life-in-hand-claude-dev service ssh restart
```

### Claude Code Issues
```bash
# Check Claude Code installation
claude-launcher.sh -c

# Reinstall Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Restart Claude Code
claude-launcher.sh -r
```

### Development Server Issues
```bash
# Check if port is in use
lsof -i :3000

# Kill existing processes
pkill -f "next dev"

# Clear Next.js cache
rm -rf .next
```

### Database Connection Issues
```bash
# Check host database connectivity
dev-helper check-db

# Check Supabase status (on host machine)
npm run db:status

# Restart Supabase (on host machine)
npm run db:stop
npm run db:start
```

## Advanced Usage

### Custom Environment Variables
Edit the `docker-compose.yml` file to add custom environment variables:

```yaml
environment:
  - CUSTOM_VAR=value
  - ANOTHER_VAR=another_value
```

### Mounting Additional Volumes
Add additional volume mounts in `docker-compose.yml`:

```yaml
volumes:
  - /path/to/host/directory:/container/directory
```

### Using with Different Projects
The container is designed to be project-agnostic. Simply change the volume mount path:

```yaml
volumes:
  - /path/to/your/project:/workspace:cached
```

## Security Considerations

- **Development Only**: This container is designed for development use only
- **SSH Access**: Uses password authentication for convenience (dev/dev)
- **Permissions**: Claude Code runs with `--dangerously-skip-permissions` flag
- **Container User**: All development work is done as the `dev` user
- **Host Services**: Container connects to host Supabase services via `host.docker.internal`

## Contributing

To improve this development environment:

1. Update the relevant files in `.claude/`
2. Test changes with `docker-compose up --build -d`
3. Update this README with any new features or changes

## Support

For issues specific to this development environment, check:
1. Container logs: `docker-compose logs claude-dev`
2. SSH into container and check logs: `logs`
3. Project status: `dev-helper status`

For Claude Code issues, refer to the official documentation at https://docs.anthropic.com/claude-code