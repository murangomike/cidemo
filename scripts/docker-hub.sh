#!/bin/bash

# Docker Hub Management Script
# This script helps with building, tagging, and pushing images to Docker Hub

set -e

# Configuration
DOCKER_HUB_USERNAME="murango001"
IMAGE_NAME="ciddemo"
FULL_IMAGE_NAME="${DOCKER_HUB_USERNAME}/${IMAGE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${GREEN}➤ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Build the Docker image
build_image() {
    local tag=${1:-latest}
    
    print_header "Building Docker Image"
    print_step "Building ${FULL_IMAGE_NAME}:${tag}..."
    
    docker build -t "${FULL_IMAGE_NAME}:${tag}" .
    
    print_success "Image built successfully!"
    docker images "${FULL_IMAGE_NAME}:${tag}"
}

# Tag an image
tag_image() {
    local source_tag=${1:-latest}
    local target_tag=${2}
    
    if [ -z "$target_tag" ]; then
        print_error "Target tag is required for tagging"
        exit 1
    fi
    
    print_header "Tagging Docker Image"
    print_step "Tagging ${FULL_IMAGE_NAME}:${source_tag} as ${FULL_IMAGE_NAME}:${target_tag}..."
    
    docker tag "${FULL_IMAGE_NAME}:${source_tag}" "${FULL_IMAGE_NAME}:${target_tag}"
    
    print_success "Image tagged successfully!"
    docker images "${FULL_IMAGE_NAME}"
}

# Push image to Docker Hub
push_image() {
    local tag=${1:-latest}
    
    print_header "Pushing to Docker Hub"
    
    # Check if logged in
    if ! docker info | grep -q "Username: ${DOCKER_HUB_USERNAME}"; then
        print_step "Please log in to Docker Hub..."
        docker login
    fi
    
    print_step "Pushing ${FULL_IMAGE_NAME}:${tag}..."
    docker push "${FULL_IMAGE_NAME}:${tag}"
    
    print_success "Image pushed successfully!"
    print_info "Image available at: https://hub.docker.com/r/${DOCKER_HUB_USERNAME}/${IMAGE_NAME}"
}

# Pull image from Docker Hub
pull_image() {
    local tag=${1:-latest}
    
    print_header "Pulling from Docker Hub"
    print_step "Pulling ${FULL_IMAGE_NAME}:${tag}..."
    
    docker pull "${FULL_IMAGE_NAME}:${tag}"
    
    print_success "Image pulled successfully!"
    docker images "${FULL_IMAGE_NAME}:${tag}"
}

# List all tags for the image
list_tags() {
    print_header "Local Image Tags"
    docker images "${FULL_IMAGE_NAME}"
    
    print_header "Docker Hub Tags"
    print_info "Visit https://hub.docker.com/r/${DOCKER_HUB_USERNAME}/${IMAGE_NAME}/tags to see all available tags"
}

# Remove local images
cleanup() {
    local tag=${1}
    
    print_header "Cleaning Up Local Images"
    
    if [ -n "$tag" ]; then
        print_step "Removing ${FULL_IMAGE_NAME}:${tag}..."
        docker rmi "${FULL_IMAGE_NAME}:${tag}" || true
    else
        print_step "Removing all ${FULL_IMAGE_NAME} images..."
        docker images "${FULL_IMAGE_NAME}" -q | xargs -r docker rmi || true
    fi
    
    print_success "Cleanup completed!"
}

# Build and push in one go
build_and_push() {
    local tag=${1:-latest}
    
    build_image "$tag"
    push_image "$tag"
    
    # Also tag and push as latest if not already latest
    if [ "$tag" != "latest" ]; then
        tag_image "$tag" "latest"
        push_image "latest"
    fi
}

# Release workflow - build, tag with version, and push
release() {
    local version=${1}
    
    if [ -z "$version" ]; then
        print_error "Version is required for release (e.g., v1.0.0)"
        exit 1
    fi
    
    print_header "Creating Release: $version"
    
    # Build with version tag
    build_image "$version"
    
    # Tag as latest
    tag_image "$version" "latest"
    
    # Push both tags
    push_image "$version"
    push_image "latest"
    
    print_success "Release $version created and pushed!"
}

# Show usage
usage() {
    echo "Docker Hub Management Script for ${FULL_IMAGE_NAME}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  build [tag]           Build Docker image (default: latest)"
    echo "  tag <src> <dst>       Tag an existing image"
    echo "  push [tag]            Push image to Docker Hub (default: latest)"
    echo "  pull [tag]            Pull image from Docker Hub (default: latest)"
    echo "  list                  List local and Docker Hub tags"
    echo "  cleanup [tag]         Remove local images (all if no tag specified)"
    echo "  build-push [tag]      Build and push image (default: latest)"
    echo "  release <version>     Create a release (build, tag, and push)"
    echo "  login                 Login to Docker Hub"
    echo "  test [tag]            Test the image locally (default: latest)"
    echo ""
    echo "Examples:"
    echo "  $0 build              # Build with latest tag"
    echo "  $0 build v1.0.0       # Build with v1.0.0 tag"
    echo "  $0 push latest         # Push latest tag"
    echo "  $0 release v1.0.0      # Create and push release v1.0.0"
    echo "  $0 test                # Test latest image"
}

# Test the image locally
test_image() {
    local tag=${1:-latest}
    
    print_header "Testing Image Locally"
    print_step "Starting ${FULL_IMAGE_NAME}:${tag} for testing..."
    
    # Stop any existing test container
    docker stop cidemo-test 2>/dev/null || true
    docker rm cidemo-test 2>/dev/null || true
    
    # Run the container
    docker run -d \
        --name cidemo-test \
        -p 3001:3000 \
        -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
        "${FULL_IMAGE_NAME}:${tag}"
    
    sleep 5
    
    # Test health endpoint
    if curl -f http://localhost:3001/healthz > /dev/null 2>&1; then
        print_success "Health check passed!"
        curl http://localhost:3001/healthz
    else
        print_error "Health check failed!"
    fi
    
    print_info "Test container running on http://localhost:3001"
    print_info "Stop with: docker stop cidemo-test && docker rm cidemo-test"
}

# Login to Docker Hub
login_docker_hub() {
    print_header "Docker Hub Login"
    docker login
}

# Main execution
main() {
    check_docker
    
    case "$1" in
        "build")
            build_image "$2"
            ;;
        "tag")
            tag_image "$2" "$3"
            ;;
        "push")
            push_image "$2"
            ;;
        "pull")
            pull_image "$2"
            ;;
        "list")
            list_tags
            ;;
        "cleanup")
            cleanup "$2"
            ;;
        "build-push")
            build_and_push "$2"
            ;;
        "release")
            release "$2"
            ;;
        "login")
            login_docker_hub
            ;;
        "test")
            test_image "$2"
            ;;
        "")
            usage
            ;;
        *)
            print_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
