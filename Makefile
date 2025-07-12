# Claude Code Development Environment Makefile
# Convenient commands for managing the development environment

.PHONY: help build start stop restart logs shell claude status clean first-run rebuild

# Load environment variables if .env.host exists
ifneq (,$(wildcard ./.env.host))
    include .env.host
    export
endif

# Default target
help:
	@echo "Claude Code Development Environment"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make build     - Build the development container"
	@echo "  make start     - Start the development environment"
	@echo "  make stop      - Stop the development environment"
	@echo "  make restart   - Restart the development environment"
	@echo "  make logs      - View container logs"
	@echo "  make shell     - SSH into the development environment"
	@echo "  make mosh      - Mosh into the development environment"
	@echo "  make claude    - SSH into container and launch Claude Code"
	@echo "  make status    - Show container status"
	@echo "  make clean     - Clean up containers and volumes"
	@echo "  make help      - Show this help message"
	@echo "  make first-run - Complete first-time setup and start"
	@echo "  make rebuild   - Full rebuild (clean build with --no-cache)"
	@echo ""
	@echo "Examples:"
	@echo "  make first-run # First time: build and start"
	@echo "  make start     # Start the environment"
	@echo "  make shell     # SSH into the container (enhanced ZSH with welcome message)"
	@echo "  make mosh      # Mosh into the container (better for unstable connections)"
	@echo "  make claude    # Launch Claude Code directly"
	@echo ""

# Build the development container
build:
	@echo "🏗️  Building Claude Code development environment..."
	@docker-compose build

# Start the development environment
start:
	@echo "🚀 Starting Claude Code development environment..."
	@docker-compose up -d
	@echo "✅ Environment started!"
	@echo "🔌 SSH access: ssh dev@localhost -p 2222 (password: dev)"
	@echo "🌐 Development server: http://localhost:3000"

# Stop the development environment
stop:
	@echo "🛑 Stopping Claude Code development environment..."
	@docker-compose down

# Restart the development environment
restart: stop start

# View container logs
logs:
	@echo "📋 Viewing container logs..."
	@docker-compose logs -f claude-dev

# SSH into the development environment
shell:
	@echo "🐚 Connecting to development environment..."
	@echo "💡 Use 'claude' command to launch Claude Code"
	ssh dev@localhost -p 2222

# Mosh into the development environment
mosh:
	@echo "🌐 Connecting via Mosh (better for unstable connections)..."
	@echo "💡 Use 'claude' command to launch Claude Code"
	mosh --ssh="ssh -p 2222" dev@localhost

# SSH into container and launch Claude Code directly
claude:
	@echo "🤖 Launching Claude Code..."
	ssh dev@localhost -p 2222 -t "claude"

# Show container status
status:
	@echo "📊 Container status:"
	@docker-compose ps
	@echo ""
	@echo "🔍 Port status:"
	@echo "SSH (2222): $$(nc -z localhost 2222 && echo '✅ Open' || echo '❌ Closed')"
	@echo "Next.js (3000): $$(nc -z localhost 3000 && echo '✅ Open' || echo '❌ Closed')"

# Clean up containers and volumes
clean:
	@echo "🧹 Cleaning up development environment..."
	@docker-compose down -v
	@docker system prune -f
	@echo "✅ Cleanup complete!"

# First-time setup and start
first-run: build start
	@echo "🎯 First-time setup complete!"
	@echo "✅ Environment is ready for development"
	@echo "🔌 SSH access: ssh dev@localhost -p 2222 (password: dev)"
	@echo "🤖 Run 'make claude' to launch Claude Code directly"

# Full rebuild (clean build)
rebuild:
	@echo "🔄 Rebuilding development environment..."
	@docker-compose down -v
	@docker-compose build --no-cache
	@docker-compose up -d
	@echo "✅ Rebuild complete!"

# Install/Update Claude Code in container
update-claude:
	@echo "🔄 Updating Claude Code in container..."
	docker exec life-in-hand-claude-dev bash -c "export PATH=~/.npm-global/bin:$$PATH && npm update -g @anthropic-ai/claude-code"
	@echo "✅ Claude Code updated!"

# Show environment information
info:
	@echo "ℹ️  Environment Information"
	@echo "=========================="
	@echo "Container Name: life-in-hand-claude-dev"
	@echo "Project Directory: /workspace"
	@echo "SSH User: dev"
	@echo "SSH Password: dev"
	@echo "SSH Port: 2222"
	@echo ""
	@echo "🔗 URLs:"
	@echo "  Development: http://localhost:3000"
	@echo ""
	@echo "🛠️  Tools:"
	@echo "  Node.js: $$(docker exec life-in-hand-claude-dev node --version 2>/dev/null || echo 'Container not running')"
	@echo "  NPM: $$(docker exec life-in-hand-claude-dev npm --version 2>/dev/null || echo 'Container not running')"
	@echo "  Claude Code: $$(docker exec life-in-hand-claude-dev bash -c 'export PATH=~/.npm-global/bin:$$PATH && claude --version' 2>/dev/null || echo 'Container not running')"
	@echo "  GitHub CLI: $$(docker exec life-in-hand-claude-dev gh --version 2>/dev/null | head -1 || echo 'Container not running')"
	@echo "  AWS CLI: $$(docker exec life-in-hand-claude-dev aws --version 2>/dev/null || echo 'Container not running')"
	@echo "  Python: $$(docker exec life-in-hand-claude-dev python3 --version 2>/dev/null || echo 'Container not running')"
	@echo "  uv: $$(docker exec life-in-hand-claude-dev bash -c 'export PATH=$$HOME/.local/bin:$$PATH && uv --version' 2>/dev/null || echo 'Container not running')"