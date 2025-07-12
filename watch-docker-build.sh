#!/bin/bash

# Docker Build Watcher Script
# Automatically rebuilds the swarmdev Docker image when files change

set -e

# Configuration
DOCKER_TAG="swarmdev"
DOCKERFILE="Dockerfile.dev"
BUILD_CONTEXT="."
DEBOUNCE_TIME=2  # seconds to wait before rebuilding after changes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image: $DOCKER_TAG"
    if docker build -t "$DOCKER_TAG" -f "$DOCKERFILE" "$BUILD_CONTEXT"; then
        print_status "✅ Docker image built successfully!"
    else
        print_error "❌ Docker build failed!"
    fi
}

# Function to check if fswatch is installed
check_fswatch() {
    if ! command -v fswatch &> /dev/null; then
        print_error "fswatch is not installed. Please install it with:"
        print_error "  brew install fswatch"
        exit 1
    fi
}

# Function to cleanup on exit
cleanup() {
    print_status "Stopping file watcher..."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check dependencies
check_fswatch

# Initial build
print_status "Starting Docker build watcher..."
print_status "Watching for changes in: $BUILD_CONTEXT"
print_status "Docker tag: $DOCKER_TAG"
print_status "Dockerfile: $DOCKERFILE"
print_status ""
print_status "Press Ctrl+C to stop watching"
print_status ""

# Perform initial build
build_image

# Watch for changes
# Exclude common directories that don't affect the Docker build
fswatch -o \
    --exclude="\.git" \
    --exclude="_build" \
    --exclude="deps" \
    --exclude="node_modules" \
    --exclude="\.next" \
    --exclude="\.DS_Store" \
    --exclude="\.log" \
    --exclude="\.tmp" \
    --exclude="priv/static" \
    --latency="$DEBOUNCE_TIME" \
    . | while read -r changes; do
    
    print_warning "Files changed, rebuilding Docker image..."
    build_image
    print_status "Watching for more changes..."
done