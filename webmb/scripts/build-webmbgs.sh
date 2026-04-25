#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-gnr092/webmbgs}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
GSPDL_VERSION="${GSPDL_VERSION:-10.07.0}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.gspt}"
CONTEXT_DIR="${CONTEXT_DIR:-.}"

echo "==> Building ${IMAGE_NAME}:${IMAGE_TAG}"
echo "==> Dockerfile: ${DOCKERFILE}"
echo "==> GSPDL_VERSION: ${GSPDL_VERSION}"

docker build \
  -f "${DOCKERFILE}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  --build-arg "GSPDL_VERSION=${GSPDL_VERSION}" \
  "${CONTEXT_DIR}"

echo "==> Done: ${IMAGE_NAME}:${IMAGE_TAG}"
