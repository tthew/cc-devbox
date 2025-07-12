#!/bin/bash

# Claude Code Launcher Script
# This script provides convenient ways to launch Claude Code with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Claude Code is installed
check_claude_installation() {
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code is not installed or not in PATH"
        print_info "Installing Claude Code via npm..."
        
        # Configure npm global directory if not already done
        if [ ! -d ~/.npm-global ]; then
            mkdir -p ~/.npm-global
            npm config set prefix ~/.npm-global
            echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        fi
        
        # Install Claude Code
        export PATH=~/.npm-global/bin:$PATH
        npm install -g @anthropic-ai/claude-code
        
        if ! command -v claude &> /dev/null; then
            print_error "Failed to install Claude Code"
            exit 1
        fi
        
        print_success "Claude Code installed successfully"
    else
        print_success "Claude Code is already installed"
    fi
}

# Function to launch Claude Code with standard configuration
launch_claude() {
    print_info "Launching Claude Code with development configuration..."
    
    # Change to workspace directory
    cd /workspace
    
    # Launch Claude Code with permissions bypass
    claude --dangerously-skip-permissions
}

# Function to launch Claude Code in interactive mode
launch_claude_interactive() {
    print_info "Launching Claude Code in interactive mode..."
    
    # Change to workspace directory
    cd /workspace
    
    # Launch Claude Code interactively
    claude --dangerously-skip-permissions --interactive
}

# Function to show help
show_help() {
    echo -e "${BLUE}🤖 Claude Code Launcher${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -i, --interactive    Launch Claude Code in interactive mode"
    echo "  -c, --check          Check Claude Code installation"
    echo "  -r, --restart        Restart Claude Code (kill existing processes first)"
    echo "  -v, --version        Show Claude Code version"
    echo ""
    echo "Examples:"
    echo "  $0                   # Launch Claude Code normally"
    echo "  $0 -i               # Launch in interactive mode"
    echo "  $0 -c               # Check installation"
    echo "  $0 -r               # Restart Claude Code"
    echo ""
    echo "Environment:"
    echo "  Project directory: /workspace"
    echo "  Working directory: $(pwd)"
    echo "  User: $(whoami)"
    echo ""
}

# Function to show version
show_version() {
    if command -v claude &> /dev/null; then
        claude --version
    else
        print_error "Claude Code is not installed"
        exit 1
    fi
}

# Function to restart Claude Code
restart_claude() {
    print_info "Stopping any existing Claude Code processes..."
    
    # Kill any existing claude processes
    pkill -f "claude" || true
    
    # Wait a moment for processes to fully terminate
    sleep 2
    
    print_success "Existing processes stopped"
    
    # Launch Claude Code
    launch_claude
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--interactive)
            check_claude_installation
            launch_claude_interactive
            ;;
        -c|--check)
            check_claude_installation
            print_success "Claude Code is properly installed"
            ;;
        -r|--restart)
            check_claude_installation
            restart_claude
            ;;
        -v|--version)
            show_version
            ;;
        "")
            # Default action: launch Claude Code
            check_claude_installation
            launch_claude
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"