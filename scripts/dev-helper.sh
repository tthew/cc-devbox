#!/bin/bash

# Development Helper Script
# Provides common development tasks and shortcuts

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

# Function to check if we're in the project directory
check_project_directory() {
    if [ ! -f "package.json" ]; then
        print_error "Not in a valid project directory"
        print_info "Changing to /workspace..."
        cd /workspace
        
        if [ ! -f "package.json" ]; then
            print_error "No package.json found in /workspace"
            exit 1
        fi
    fi
}

# Function to start development server
start_dev_server() {
    print_info "Starting development server..."
    check_project_directory
    
    # Check if server is already running
    if lsof -i :3000 &> /dev/null; then
        print_warning "Development server appears to be already running on port 3000"
        read -p "Would you like to kill the existing process and restart? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pkill -f "next dev" || true
            sleep 2
        else
            print_info "Exiting..."
            exit 0
        fi
    fi
    
    npm run dev
}

# Function to run tests
run_tests() {
    print_info "Running tests..."
    check_project_directory
    
    case "${1:-all}" in
        "unit")
            npm run test:unit
            ;;
        "integration")
            npm run test:integration
            ;;
        "e2e")
            npm run test:e2e
            ;;
        "watch")
            npm run test:watch
            ;;
        "coverage")
            npm run test:coverage
            ;;
        "all")
            npm run test:all
            ;;
        *)
            print_error "Unknown test type: $1"
            print_info "Available test types: unit, integration, e2e, watch, coverage, all"
            exit 1
            ;;
    esac
}

# Function to run linting and type checking
run_quality_checks() {
    print_info "Running quality checks..."
    check_project_directory
    
    print_info "Running linting..."
    npm run lint
    
    print_info "Running type checking..."
    npm run typecheck
    
    print_success "All quality checks passed!"
}

# Function to build the project
build_project() {
    print_info "Building project..."
    check_project_directory
    
    npm run build
    
    print_success "Build completed successfully!"
}

# Function to check host database connectivity
check_host_database() {
    print_info "Checking host Supabase connectivity..."
    
    # Test API connectivity
    if curl -s -f "http://host.docker.internal:54321/health" > /dev/null 2>&1; then
        print_success "Host Supabase API is reachable"
    else
        print_error "Host Supabase API is not reachable"
        print_info "Please ensure Supabase is running on the host machine"
        return 1
    fi
    
    # Test Studio connectivity
    if curl -s -f "http://host.docker.internal:54322" > /dev/null 2>&1; then
        print_success "Host Supabase Studio is reachable"
    else
        print_warning "Host Supabase Studio may not be accessible"
    fi
    
    print_success "Host database connectivity verified!"
}

# Function to setup database (uses host services)
setup_database() {
    print_info "Setting up database connection to host..."
    check_project_directory
    
    print_info "Checking host Supabase connectivity..."
    if ! check_host_database; then
        print_error "Cannot connect to host Supabase services"
        print_info "Please ensure Supabase is running on the host machine:"
        print_info "  npm run db:start"
        return 1
    fi
    
    print_info "Generating types from host database..."
    npm run db:types
    
    print_success "Database setup completed!"
}

# Function to check environment configuration
check_environment() {
    print_info "Checking environment configuration..."
    check_project_directory
    
    # Check basic container setup
    print_success "Container development environment configured"
    print_info "No additional environment files required for this container setup"
    
    print_success "Environment check completed!"
}

# Function to show project status
show_status() {
    print_info "Project Status"
    echo "==============="
    
    check_project_directory
    
    echo "📁 Project Directory: $(pwd)"
    echo "📦 Node Version: $(node --version)"
    echo "📦 NPM Version: $(npm --version)"
    
    if [ -f "package.json" ]; then
        echo "📋 Project Name: $(jq -r '.name' package.json)"
        echo "📋 Project Version: $(jq -r '.version' package.json)"
    fi
    
    echo ""
    echo "🚀 Available Services:"
    
    # Check if development server is running
    if lsof -i :3000 &> /dev/null; then
        echo "  ✅ Development Server: http://localhost:3000"
    else
        echo "  ❌ Development Server: Not running"
    fi
    
    # Check if host Supabase is running
    if curl -s -f "http://host.docker.internal:54321/health" > /dev/null 2>&1; then
        echo "  ✅ Host Supabase API: http://host.docker.internal:54321"
    else
        echo "  ❌ Host Supabase API: Not reachable"
    fi
    
    # Check if host Supabase Studio is running
    if curl -s -f "http://host.docker.internal:54322" > /dev/null 2>&1; then
        echo "  ✅ Host Supabase Studio: http://host.docker.internal:54322"
    else
        echo "  ❌ Host Supabase Studio: Not reachable"
    fi
    
    echo ""
    echo "🔧 Quick Commands:"
    echo "  dev-helper start     # Start development server"
    echo "  dev-helper test      # Run all tests"
    echo "  dev-helper check     # Run linting and type checking"
    echo "  dev-helper build     # Build the project"
    echo "  dev-helper db        # Setup database"
    echo "  claude               # Launch Claude Code"
    echo ""
}

# Function to show help
show_help() {
    echo -e "${BLUE}🛠️  Development Helper${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start                Start development server"
    echo "  test [type]          Run tests (types: unit, integration, e2e, watch, coverage, all)"
    echo "  check                Run linting and type checking"
    echo "  build                Build the project"
    echo "  db                   Setup database connection to host"
    echo "  check-db             Check host database connectivity"
    echo "  check-env            Check environment configuration"
    echo "  status               Show project status"
    echo "  help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start             # Start development server"
    echo "  $0 test unit         # Run unit tests"
    echo "  $0 test watch        # Run tests in watch mode"
    echo "  $0 check             # Run quality checks"
    echo "  $0 build             # Build project"
    echo "  $0 db                # Setup database connection to host"
    echo "  $0 check-db          # Check host database connectivity"
    echo "  $0 check-env         # Check environment configuration"
    echo "  $0 status            # Show project status"
    echo ""
}

# Main script logic
main() {
    case "${1:-help}" in
        "start")
            start_dev_server
            ;;
        "test")
            run_tests "${2:-all}"
            ;;
        "check")
            run_quality_checks
            ;;
        "build")
            build_project
            ;;
        "db")
            setup_database
            ;;
        "check-db")
            check_host_database
            ;;
        "check-env")
            check_environment
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"