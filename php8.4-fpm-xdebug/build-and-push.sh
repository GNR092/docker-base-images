#!/bin/bash
# =============================================================================
# Build and Push Script for php8.4-fpm-xdebug
# =============================================================================
# Usage: ./build-and-push.sh [version] [registry]
# Example: ./build-and-push.sh 8.4-xdebug3.4-alpine3.20 gnr092
# =============================================================================

set -euo pipefail

# Configuration
IMAGE_NAME="base-php8.4-fpm-xdebug"
DEFAULT_VERSION="8.4-xdebug3.4-alpine3.20"
DEFAULT_REGISTRY="gnr092"
DOCKERFILE="Dockerfile"
BUILD_CONTEXT="."

# Parse arguments
VERSION="${1:-$DEFAULT_VERSION}"
REGISTRY="${2:-$DEFAULT_REGISTRY}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}"

# Tags to apply
TAGS=(
    "latest"
    "8.4"
    "${VERSION}"
)

echo "============================================"
echo "Building ${FULL_IMAGE}"
echo "Version: ${VERSION}"
echo "Tags: ${TAGS[*]}"
echo "============================================"

# Build with all tags
BUILD_ARGS=()
for tag in "${TAGS[@]}"; do
    BUILD_ARGS+=("-t" "${FULL_IMAGE}:${tag}")
done

# Add build args for reproducibility + Xdebug version
XDEBUG_VERSION="${XDEBUG_VERSION:-3.4.0}"
BUILD_ARGS+=(
    "--build-arg" "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    "--build-arg" "VERSION=${VERSION}"
    "--build-arg" "VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    "--build-arg" "XDEBUG_VERSION=${XDEBUG_VERSION}"
)

echo "Building with XDEBUG_VERSION=${XDEBUG_VERSION}..."
docker build "${BUILD_ARGS[@]}" -f "${DOCKERFILE}" "${BUILD_CONTEXT}"

# Verify image
echo "Verifying image..."
docker run --rm "${FULL_IMAGE}:${VERSION}" php -v | head -1
docker run --rm "${FULL_IMAGE}:${VERSION}" php-fpm -v | head -1
docker run --rm "${FULL_IMAGE}:${VERSION}" php -m | grep -i xdebug || echo "Xdebug not loaded (expected when XDEBUG_MODE=off)"

# Push if not local-only
if [[ "${3:-}" != "--no-push" ]]; then
    echo "Logging in to registry (if needed)..."
    docker login

    echo "Pushing tags..."
    for tag in "${TAGS[@]}"; do
        echo "Pushing ${FULL_IMAGE}:${tag}"
        docker push "${FULL_IMAGE}:${tag}"
    done

    echo "============================================"
    echo "Successfully pushed:"
    for tag in "${TAGS[@]}"; do
        echo "  ${FULL_IMAGE}:${tag}"
    done
    echo "============================================"
else
    echo "============================================"
    echo "Build complete (push skipped with --no-push)"
    echo "Local tags:"
    for tag in "${TAGS[@]}"; do
        echo "  ${FULL_IMAGE}:${tag}"
    done
    echo "============================================"
fi