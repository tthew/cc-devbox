#!/bin/bash

# Optimized Docker build script for M4 Pro
# Leverages BuildKit and multi-stage builds for maximum performance

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
IMAGE_NAME="life-in-hand-dev"
CONTAINER_NAME="life-in-hand-claude-dev"
BUILD_CONTEXT="/Users/tthew/Development/cc-devbox"

echo -e "${BLUE}🚀 Starting optimized Docker build for M4 Pro${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Set BuildKit environment variables for maximum performance
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Build with aggressive caching and BuildKit optimizations
echo -e "${YELLOW}📦 Building with ARM64 optimizations...${NC}"
time docker buildx build \
    --platform linux/arm64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from "$IMAGE_NAME:latest" \
    --tag "$IMAGE_NAME:latest" \
    --tag "$IMAGE_NAME:$(date +%Y%m%d-%H%M%S)" \
    --load \
    "$BUILD_CONTEXT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    
    # Show image size
    echo -e "${BLUE}📊 Image information:${NC}"
    docker images "$IMAGE_NAME:latest" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "1. Run: docker-compose down && docker-compose up -d"
    echo "2. Monitor: ./.claude/performance-monitor.sh status"
    echo "3. Connect: ssh dev@localhost -p 2222"
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi