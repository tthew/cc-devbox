# Claude Code Development Environment Makefile
# Convenient commands for managing the development environment
# NOTE: Requires .env.host file with environment variables

.PHONY: help build start stop restart logs shell claude status clean setup-env check-env

# Default target
help:
	@echo "Claude Code Development Environment"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make setup-env - Set up environment file from example"
	@echo "  make check-env - Validate environment variables"
	@echo "  make build     - Build the development container"
	@echo "  make start     - Start the development environment"
	@echo "  make stop      - Stop the development environment"
	@echo "  make restart   - Restart the development environment"
	@echo "  make logs      - View container logs"
	@echo "  make shell     - SSH into the development environment"
	@echo "  make mosh      - Mosh into the development environment"
	@echo "  make claude    - SSH into container and launch Claude Code"
	@echo "  make status    - Show container status"
	@echo "  make env-status - Show environment configuration status"
	@echo "  make clean     - Clean up containers and volumes"
	@echo "  make help      - Show this help message"
	@echo "  make first-run - Complete first-time setup and start"
	@echo ""
	@echo "Examples:"
	@echo "  make first-run # First time: setup environment + start"
	@echo "  make setup-env # Set up .env.host file (first time setup)"
	@echo "  make start     # Start the environment"
	@echo "  make shell     # SSH into the container (enhanced ZSH with welcome message)"
	@echo "  make mosh      # Mosh into the container (better for unstable connections)"
	@echo "  make claude    # Launch Claude Code directly"
	@echo ""
	@echo "⚠️  IMPORTANT: Ensure .env.host exists with your secrets before running commands"
	@echo "   Run 'make first-run' for complete first-time setup"
	@echo ""

# Set up environment file from example
setup-env:
	@echo "🔧 Setting up environment file..."
	@if [ ! -f .env.host ]; then \
		cp .env.host.example .env.host; \
		echo "✅ Created .env.host from example"; \
		echo "⚠️  IMPORTANT: Edit .env.host with your actual secrets!"; \
		echo "   Required changes:"; \
		echo "   - Generate JWT_SECRET: openssl rand -hex 32"; \
		echo "   - Generate NEXTAUTH_SECRET: openssl rand -base64 32"; \
		echo "   - Update Supabase keys from your project dashboard"; \
		echo ""; \
		echo "📚 See SECURITY-SETUP.md for detailed instructions"; \
	else \
		echo "⚠️  .env.host already exists - not overwriting"; \
		echo "   Delete .env.host first if you want to recreate it"; \
	fi

# Check environment variables
check-env:
	@echo "🔍 Checking environment setup..."
	@if [ ! -f .env.host ]; then \
		echo "❌ .env.host file not found"; \
		echo "   Run 'make setup-env' to create it"; \
		exit 1; \
	fi
	@echo "✅ .env.host file exists"
	@echo "🔍 Checking required variables..."
	@source .env.host && \
	missing=0; \
	for var in NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY DATABASE_URL DIRECT_URL JWT_SECRET NEXTAUTH_SECRET NEXTAUTH_URL; do \
		if [ -z "$${!var}" ]; then \
			echo "❌ Missing: $$var"; \
			missing=$$((missing+1)); \
		else \
			echo "✅ Set: $$var"; \
		fi; \
	done; \
	if [ $$missing -gt 0 ]; then \
		echo ""; \
		echo "❌ $$missing required variables are missing"; \
		echo "   Edit .env.host and set all required variables"; \
		echo "   See .env.template for guidance"; \
		exit 1; \
	fi
	@echo "✅ All required environment variables are set"

# First-time setup and start
first-run: setup-env
	@echo "🎯 Starting first-time setup..."
	@echo ""
	@echo "⚠️  NEXT STEPS REQUIRED:"
	@echo "1. Edit .env.host with your actual secrets:"
	@echo "   - Generate JWT_SECRET: openssl rand -hex 32"
	@echo "   - Generate NEXTAUTH_SECRET: openssl rand -base64 32"
	@echo "   - Update Supabase keys from your project dashboard"
	@echo ""
	@echo "2. After editing .env.host, run: make start"
	@echo ""
	@echo "📚 See SECURITY-SETUP.md for detailed instructions"
	@echo ""
	@read -p "Press Enter after you've edited .env.host with your secrets..."
	@$(MAKE) check-env
	@$(MAKE) start

# Build the development container
build: check-env
	@echo "🏗️  Building Claude Code development environment..."
	@bash -c 'set -a && source .env.host && docker-compose build'

# Start the development environment
start: check-env
	@echo "🚀 Starting Claude Code development environment..."
	@bash -c 'set -a && source .env.host && docker-compose up -d'
	@echo "✅ Environment started!"
	@echo "🔌 SSH access: ssh dev@localhost -p 2222 (password: dev)"
	@echo "🌐 Development server: http://localhost:3000"
	@echo "🗄️  Supabase Studio: http://localhost:54322"

# Stop the development environment
stop:
	@echo "🛑 Stopping Claude Code development environment..."
	@if [ -f .env.host ]; then \
		bash -c 'set -a && source .env.host && docker-compose down'; \
	else \
		docker-compose down; \
	fi

# Restart the development environment
restart: stop start

# View container logs
logs:
	@echo "📋 Viewing container logs..."
	@if [ -f .env.host ]; then \
		set -a && source .env.host && docker-compose logs -f claude-dev; \
	else \
		docker-compose logs -f claude-dev; \
	fi

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
	@if [ -f .env.host ]; then \
		set -a && source .env.host && docker-compose ps; \
	else \
		docker-compose ps; \
	fi
	@echo ""
	@echo "🔍 Port status:"
	@echo "SSH (2222): $$(nc -z localhost 2222 && echo '✅ Open' || echo '❌ Closed')"
	@echo "Next.js (3000): $$(nc -z localhost 3000 && echo '✅ Open' || echo '❌ Closed')"
	@echo "Supabase (54321): $$(nc -z localhost 54321 && echo '✅ Open' || echo '❌ Closed')"
	@echo "Supabase Studio (54322): $$(nc -z localhost 54322 && echo '✅ Open' || echo '❌ Closed')"

# Show environment configuration status
env-status:
	@echo "🔧 Environment Configuration Status"
	@echo "=================================="
	@echo ""
	@echo "📁 Files:"
	@echo "  .env.template: $$([ -f .env.template ] && echo '✅ Exists' || echo '❌ Missing')"
	@echo "  .env.host.example: $$([ -f .env.host.example ] && echo '✅ Exists' || echo '❌ Missing')"
	@echo "  .env.host: $$([ -f .env.host ] && echo '✅ Exists' || echo '❌ Missing')"
	@echo ""
	@if [ -f .env.host ]; then \
		echo "🔍 Environment Variables:"; \
		source .env.host 2>/dev/null && \
		for var in NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY DATABASE_URL JWT_SECRET NEXTAUTH_SECRET; do \
			if [ -n "$${!var}" ]; then \
				if [ "$$var" = "JWT_SECRET" ] || [ "$$var" = "NEXTAUTH_SECRET" ] || [ "$$var" = "SUPABASE_SERVICE_ROLE_KEY" ]; then \
					echo "  $$var: ✅ Set (hidden)"; \
				else \
					echo "  $$var: ✅ Set"; \
				fi; \
			else \
				echo "  $$var: ❌ Missing"; \
			fi; \
		done; \
	else \
		echo "❌ .env.host not found - run 'make setup-env'"; \
	fi
	@echo ""
	@echo "🔒 Security:"
	@echo "  .env.host gitignored: $$(git check-ignore .env.host >/dev/null 2>&1 && echo '✅ Protected' || echo '⚠️  Not protected')"
	@echo "  Templates not gitignored: $$(git check-ignore .env.template >/dev/null 2>&1 && echo '❌ Protected' || echo '✅ Available')"

# Clean up containers and volumes
clean:
	@echo "🧹 Cleaning up development environment..."
	@if [ -f .env.host ]; then \
		set -a && source .env.host && docker-compose down -v; \
	else \
		docker-compose down -v; \
	fi
	docker system prune -f
	@echo "✅ Cleanup complete!"

# Quick development workflow
dev: start
	@echo "🚀 Development environment ready!"
	@echo "Opening development server..."
	@sleep 3
	@open http://localhost:3000 || echo "Visit http://localhost:3000 in your browser"

# Full rebuild (clean build)
rebuild: check-env
	@echo "🔄 Rebuilding development environment..."
	@bash -c 'set -a && source .env.host && \
	docker-compose down -v && \
	docker-compose build --no-cache && \
	docker-compose up -d'
	@echo "✅ Rebuild complete!"

# Install/Update Claude Code in container
update-claude:
	@echo "🔄 Updating Claude Code in container..."
	docker exec life-in-hand-claude-dev bash -c "export PATH=~/.npm-global/bin:$$PATH && npm update -g @anthropic-ai/claude-code"
	@echo "✅ Claude Code updated!"

# Backup container configuration
backup:
	@echo "💾 Creating backup of development environment..."
	@mkdir -p backups
	@tar -czf backups/claude-dev-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		Dockerfile docker-compose.yml entrypoint.sh scripts/ README.md
	@echo "✅ Backup created in backups/ directory"

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
	@echo "  Supabase API: http://localhost:54321"
	@echo "  Supabase Studio: http://localhost:54322"
	@echo "  Supabase Inbucket: http://localhost:54323"
	@echo "  Supabase Storage: http://localhost:54324"
	@echo ""
	@echo "🛠️  Tools:"
	@echo "  Node.js: $$(docker exec life-in-hand-claude-dev node --version 2>/dev/null || echo 'Container not running')"
	@echo "  NPM: $$(docker exec life-in-hand-claude-dev npm --version 2>/dev/null || echo 'Container not running')"
	@echo "  Claude Code: $$(docker exec life-in-hand-claude-dev bash -c 'export PATH=~/.npm-global/bin:$$PATH && claude --version' 2>/dev/null || echo 'Container not running')"
	@echo "  GitHub CLI: $$(docker exec life-in-hand-claude-dev gh --version 2>/dev/null | head -1 || echo 'Container not running')"
	@echo "  AWS CLI: $$(docker exec life-in-hand-claude-dev aws --version 2>/dev/null || echo 'Container not running')"
	@echo "  Python: $$(docker exec life-in-hand-claude-dev python3 --version 2>/dev/null || echo 'Container not running')"
	@echo "  uv: $$(docker exec life-in-hand-claude-dev bash -c 'export PATH=$$HOME/.local/bin:$$PATH && uv --version' 2>/dev/null || echo 'Container not running')"