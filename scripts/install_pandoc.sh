#!/bin/sh
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: install_pandoc.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Install a specific (or latest) pandoc binary (amd64/arm64) from
#              GitHub Releases and strip ELF symbols to reduce size.
# Usage......: install_pandoc.sh <amd64|arm64> [version]
#              - <amd64|arm64> : target architecture
#              - [version]     : e.g. 3.2.1 (default: latest)
#              You can also set PANDOC_VERSION env var instead of [version].
# Notes......: - Installs into /usr/local/bin.
#              - Creates symlinks for pandoc-lua and pandoc-server.
#              - Requires: curl, tar, file, strip, install, grep.
# Reference..: https://github.com/jgm/pandoc/releases
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
set -eu

# --- Default Values ------------------------------------------------------------
ARCH="${1:-}"
REQ_VERSION="${2:-${PANDOC_VERSION:-latest}}"

# --- Functions -----------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") <amd64|arm64> [version]

Install pandoc for the given architecture. If [version] is omitted or 'latest',
the newest release is installed. Example versions: 3.2.1, 3.1.11.1

Examples:
  $(basename "$0") amd64
  $(basename "$0") arm64 3.2.1
  PANDOC_VERSION=3.2.1 $(basename "$0") amd64
EOF
}

err() {
  echo "Error: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || err "Missing dependency: $1"
}

http_ok() {
  # Returns 0 if URL returns HTTP 200; otherwise non-zero.
  curl -fsSLI -o /dev/null -w '%{http_code}' "$1" 2>/dev/null | grep -qx 200
}

# --- Main Script Logic ---------------------------------------------------------
# Basic help
[ "${ARCH:-}" = "-h" ] || [ "${ARCH:-}" = "--help" ] && {
  usage
  exit 0
}
[ -n "${ARCH}" ] || {
  usage
  exit 1
}

# Verify required tools
need curl
need tar
need file
need strip
need install
need grep

# Map script argument to GitHub architecture string
case "$ARCH" in
  amd64) GH_ARCH="linux-amd64" ;;
  arm64) GH_ARCH="linux-arm64" ;;
  *) err "Unsupported architecture: $ARCH (use amd64 or arm64)" ;;
esac

# Build the GitHub API endpoint based on requested version
if [ "${REQ_VERSION}" = "latest" ]; then
  API_URL="https://api.github.com/repos/jgm/pandoc/releases/latest"
  # Fallback: Try to get latest version from redirect (no API call)
  echo "Attempting to fetch latest Pandoc release info..."
  LATEST_VERSION="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    'https://github.com/jgm/pandoc/releases/latest' 2>/dev/null | \
    grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?' | tail -1 || echo '')"
  
  if [ -n "${LATEST_VERSION}" ]; then
    echo "Detected latest version via redirect: ${LATEST_VERSION}"
    REQ_VERSION="${LATEST_VERSION}"
    # Try direct download URL first (no API needed)
    URL="https://github.com/jgm/pandoc/releases/download/${REQ_VERSION}/pandoc-${REQ_VERSION}-${GH_ARCH}.tar.gz"
    if http_ok "${URL}"; then
      echo "Using direct download URL (no API): ${URL}"
    else
      echo "Direct URL failed, falling back to API query..."
      URL=""
    fi
  else
    echo "Could not detect version from redirect, trying API..."
    URL=""
  fi
  
  # If direct URL didn't work, try API
  if [ -z "${URL}" ]; then
    URL="$(curl -fsSL -H 'Accept: application/vnd.github+json' "${API_URL}" |
      grep -Eo "https://[^\"]*pandoc-[0-9][^\"]*-${GH_ARCH}\.tar\.gz" |
      head -n1 || true)"
  fi
else
  # Specific version requested - try direct URL first
  echo "Installing specific Pandoc version: ${REQ_VERSION}"
  URL="https://github.com/jgm/pandoc/releases/download/${REQ_VERSION}/pandoc-${REQ_VERSION}-${GH_ARCH}.tar.gz"
  
  if ! http_ok "${URL}"; then
    echo "Direct download failed, trying API fallback..."
    API_URL="https://api.github.com/repos/jgm/pandoc/releases/tags/${REQ_VERSION}"
    URL="$(curl -fsSL -H 'Accept: application/vnd.github+json' "${API_URL}" |
      grep -Eo "https://[^\"]*pandoc-[0-9][^\"]*-${GH_ARCH}\.tar\.gz" |
      head -n1 || true)"
  else
    echo "Using direct download URL: ${URL}"
  fi
fi

[ -n "${URL}" ] || err "Cannot find pandoc tarball for ${GH_ARCH} (${REQ_VERSION})."

# Create a temporary directory for download and extraction
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Download and extract into the temporary directory
curl -fsSL "$URL" | tar xz -C "$TMP"

# Locate the unpacked versioned directory
PVERDIR="$(find "$TMP" -maxdepth 1 -type d -name 'pandoc-*' | head -1)"
[ -n "${PVERDIR}" ] || err "Unpacked pandoc directory not found in $TMP."

# Install pandoc binary into /usr/local/bin
install -D -m 0755 "$PVERDIR/bin/pandoc" /usr/local/bin/pandoc

# Strip ELF symbols to reduce size (only if binary is ELF)
if file -b "/usr/local/bin/pandoc" | grep -q ELF; then
  strip --strip-unneeded "/usr/local/bin/pandoc" || true
fi

# Create helper symlinks (pandoc-lua and pandoc-server are identical upstream)
ln -sf pandoc /usr/local/bin/pandoc-lua
ln -sf pandoc /usr/local/bin/pandoc-server

# Verify installation with version and supported lists
echo "Installed pandoc version:"
/usr/local/bin/pandoc --version
/usr/local/bin/pandoc --list-output-formats
/usr/local/bin/pandoc --list-extensions
/usr/local/bin/pandoc --list-highlight-languages
/usr/local/bin/pandoc --list-highlight-styles

echo "Finished installing pandoc (${ARCH}, ${REQ_VERSION})."
# --- EOF -----------------------------------------------------------------------
