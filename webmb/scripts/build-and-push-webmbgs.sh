#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-gnr092/webmbgs}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
GSPDL_VERSION="${GSPDL_VERSION:-10.07.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME}" IMAGE_TAG="${IMAGE_TAG}" GSPDL_VERSION="${GSPDL_VERSION}" \
  "${SCRIPT_DIR}/build-webmbgs.sh"

echo "==> Pushing ${IMAGE_NAME}:${IMAGE_TAG}"
docker push "${IMAGE_NAME}:${IMAGE_TAG}"
echo "==> Push complete"
