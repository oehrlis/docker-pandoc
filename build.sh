#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: v5
# Purpose....: Build and optionally test a multi-arch Docker image
#              for Pandoc + TinyTeX + MS fonts.
# Notes......: - buildx multi-platform; supports --push (default) or --load
#              - sample outputs (PDF/DOCX/PPTX) gated by --test/--no-test
# License....: Apache License Version 2.0
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $(basename "$0") [RELEASE] [options]

Positional:
  RELEASE               Tag to build (default: beta). Examples: beta, 1.2.3

Options:
  --no-cache            Build without cache
  --local|--load        Local-only build (use --load, do not push)
  --push                Force push to registry (default behavior)
  --platform=LIST       Target platforms (default: linux/amd64,linux/arm64)
  --test                Generate sample PDF/DOCX/PPTX after build (default)
  --no-test             Skip sample generation (useful in CI)
  -h, --help            Show this help
EOF
}

# --- Defaults ---------------------------------------------------------------
export DOCKER_USER="oehrlis"
# Separate cd and assignment to avoid masking return values
_build_dir="$(dirname "${BASH_SOURCE[0]}")"
cd "$_build_dir" || exit 1
export BUILD_CONTEXT
BUILD_CONTEXT="$(pwd -P)"
cd - >/dev/null || exit 1
export PROJECT
PROJECT="$(basename "${BUILD_CONTEXT}")"

# Derive image name; fallback to folder name if no dash present
if [[ "${PROJECT}" == *-* ]]; then
  IMAGE="$(echo "${PROJECT}" | cut -d- -f2)"
else
  IMAGE="${PROJECT}"
fi

RELEASE="beta"
USE_NO_CACHE=0
LOCAL_BUILD=0 # 1 -> --load, 0 -> --push
DO_PUSH=1     # explicitly toggled by --push/--local; LOCAL_BUILD wins
TEST=1
PLATFORM="linux/amd64,linux/arm64"

# --- Parse arguments --------------------------------------------------------
for arg in "$@"; do
  case "${arg}" in
    -h | --help)
      usage
      exit 0
      ;;
    --no-cache) USE_NO_CACHE=1 ;;
    --local | --load)
      LOCAL_BUILD=1
      DO_PUSH=0
      ;;
    --push)
      LOCAL_BUILD=0
      DO_PUSH=1
      ;;
    --platform=*) PLATFORM="${arg#*=}" ;;
    --test) TEST=1 ;;
    --no-test) TEST=0 ;;
    --*)
      echo "Unknown option: ${arg}"
      usage
      exit 1
      ;;
    *) RELEASE="${arg}" ;;
  esac
done

# --- Sanity checks ----------------------------------------------------------
: "${DOCKER_USER:?DOCKER_USER must be set}"
: "${IMAGE:?IMAGE must resolve from project folder name}"

CURRENT_PATH="$(pwd)"
cd "${BUILD_CONTEXT}"

echo "==> Building '${DOCKER_USER}/${IMAGE}'"
echo "    Release: ${RELEASE}"
echo "    Mode:    $([[ ${LOCAL_BUILD} -eq 1 ]] && echo 'LOCAL (--load)' || echo 'REGISTRY (--push)')"
echo "    Cache:   $([[ ${USE_NO_CACHE} -eq 1 ]] && echo 'disabled' || echo 'enabled')"
echo "    Test:    $([[ ${TEST} -eq 1 ]] && echo 'on' || echo 'off')"
echo "    Platf.:  ${PLATFORM}"

# --- Tags (as an array, not a string) --------------------------------------
TAG_OPTS=()
if [[ "${RELEASE}" == "beta" ]]; then
  TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:${RELEASE}")
else
  TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:${RELEASE}")
  TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:latest")
  TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:texlive-slim")
fi
echo "==> Tags: ${TAG_OPTS[*]}"

# --- Build args (array) -----------------------------------------------------
BUILD_OPTS=(
  --build-arg "SLIM_TEX=1"
  --build-arg "PRUNE_MS_FONTS=1"
  --platform="${PLATFORM}"
  --network=host
  --build-arg "BUILDKIT_INLINE_CACHE=1"
)
[[ ${USE_NO_CACHE} -eq 1 ]] && BUILD_OPTS+=(--no-cache)

# --- Build ------------------------------------------------------------------
if [[ ${LOCAL_BUILD} -eq 1 ]]; then
  echo "==> LOCAL build (--load)"
  # Use single platform for --load (buildx limitation)
  LOCAL_PLATFORM="$(uname -m)"
  [[ "${LOCAL_PLATFORM}" == "x86_64" ]] && LOCAL_PLATFORM="linux/amd64"
  [[ "${LOCAL_PLATFORM}" == "aarch64" || "${LOCAL_PLATFORM}" == "arm64" ]] && LOCAL_PLATFORM="linux/arm64"
  echo "    Single platform: ${LOCAL_PLATFORM}"
  # Override BUILD_OPTS platform for local build
  LOCAL_BUILD_OPTS=("${BUILD_OPTS[@]}")
  for i in "${!LOCAL_BUILD_OPTS[@]}"; do
    if [[ "${LOCAL_BUILD_OPTS[$i]}" == --platform=* ]]; then
      LOCAL_BUILD_OPTS[$i]="--platform=${LOCAL_PLATFORM}"
    fi
  done
  docker buildx build --load "${TAG_OPTS[@]}" "${LOCAL_BUILD_OPTS[@]}" .
else
  echo "==> REGISTRY build (--push)"
  docker buildx build --push "${TAG_OPTS[@]}" "${BUILD_OPTS[@]}" .
  echo "==> Pulling ${DOCKER_USER}/${IMAGE}:${RELEASE}"
  docker pull "${DOCKER_USER}/${IMAGE}:${RELEASE}"
fi

# --- Optional sample generation --------------------------------------------
if [[ ${TEST} -eq 1 ]]; then
  echo "==> Generating sample documents"
  RUN_OPTS=(-v "${PWD}:/workdir:z" "${DOCKER_USER}/${IMAGE}:${RELEASE}")

  echo "   -> PDF"
  docker run --rm "${RUN_OPTS[@]}" \
    --metadata-file sample/metadata.yml --filter pandoc-latex-environment \
    --resource-path=sample --pdf-engine=xelatex \
    -o sample/sample.pdf sample/sample.md

  echo "   -> DOCX"
  docker run --rm "${RUN_OPTS[@]}" \
    --metadata-file sample/metadata.yml --resource-path=sample \
    -o sample/sample.docx sample/sample.md

  echo "   -> PPTX"
  docker run --rm "${RUN_OPTS[@]}" \
    --metadata-file sample/metadata.yml --resource-path=sample \
    -o sample/sample.pptx sample/sample.md

  echo "   -> Mermaid PDF Test"
  docker run --rm "${RUN_OPTS[@]}" \
    examples/test-mermaid.md \
    -o examples/test-output.pdf \
    --filter mermaid-filter \
    --pdf-engine=xelatex \
    --toc
  echo "      Test complete. Check examples/test-output.pdf"
else
  echo "==> Skipping sample generation (--no-test)"
fi

# --- Teardown ---------------------------------------------------------------
cd "${CURRENT_PATH}"
echo "==> Build completed."
# --- EOF --------------------------------------------------------------------
