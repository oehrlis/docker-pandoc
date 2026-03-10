#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: install_mermaid.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-20
# Revision...: 1.0.0
# Purpose....: Install Node.js, mermaid-cli, and required dependencies for
#              Mermaid diagram rendering in Docker containers
# Notes......: Installs Node.js (Debian bookworm), Chromium, and configures
#              Puppeteer for non-root container execution.
#              npm is removed after mermaid-cli install to save space.
#              Vulkan/GPU libs removed from Chromium (headless/--disable-gpu).
# Reference..: https://github.com/mermaid-js/mermaid-cli
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
readonly NODEJS_VERSION="${NODEJS_VERSION:-20}"
readonly MERMAID_VERSION="${MERMAID_VERSION:-latest}"

# ------------------------------------------------------------------------------
# Function: log_info
# Purpose.: Print informational message
# Args....: $* - Message to print
# Returns.: 0
# ------------------------------------------------------------------------------
log_info() {
  echo "==> $*"
}

# ------------------------------------------------------------------------------
# Function: install_nodejs
# Purpose.: Install Node.js from NodeSource repository
# Returns.: 0 on success
# ------------------------------------------------------------------------------
install_nodejs() {
  log_info "Installing Node.js ${NODEJS_VERSION}.x"

  # Install Node.js and npm from Debian repositories
  apt-get update
  apt-get install -y --no-install-recommends nodejs npm

  # Configure npm to skip SSL verification (workaround for DNS proxy)
  npm config set strict-ssl false

  # Verify installation
  node --version
  npm --version
}

# ------------------------------------------------------------------------------
# Function: install_chromium_deps
# Purpose.: Install Chromium and required runtime dependencies for Puppeteer
# Returns.: 0 on success
# ------------------------------------------------------------------------------
install_chromium_deps() {
  log_info "Installing Chromium and Puppeteer dependencies"

  # Clean up any broken dpkg state first
  apt-get update || log_info "Warning: apt-get update had issues (continuing)"
  dpkg --configure -a 2>/dev/null || log_info "Warning: No incomplete packages to configure"

  # Install Chromium and required libraries for headless browser
  # Note: libxss1 is not available in Debian bookworm; omitted intentionally
  # Note: chromium-sandbox omitted — we use --no-sandbox via puppeteerConfigFile
  # Note: fonts-noto-color-emoji omitted — mermaid diagrams do not use emoji
  apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 || {
    log_info "Warning: Some Chromium dependencies failed to install (continuing)"
  }
}

# ------------------------------------------------------------------------------
# Function: install_mermaid_cli
# Purpose.: Install mermaid-cli globally via npm
# Returns.: 0 on success
# ------------------------------------------------------------------------------
install_mermaid_cli() {
  log_info "Installing mermaid-cli"

  # Skip Puppeteer download since we're using system Chromium
  export PUPPETEER_SKIP_DOWNLOAD=true
  export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

  # Install mermaid-cli globally; use pinned version for reproducibility
  # The Lua filter (mermaid.lua) calls mmdc directly - no mermaid-filter npm pkg needed
  # --omit=optional skips optional deps not required for headless rendering
  if [[ "${MERMAID_VERSION}" = "latest" ]]; then
    npm install -g --omit=optional @mermaid-js/mermaid-cli
  else
    npm install -g --omit=optional "@mermaid-js/mermaid-cli@${MERMAID_VERSION}"
  fi

  # Verify installation
  mmdc --version
}

# ------------------------------------------------------------------------------
# Function: configure_puppeteer
# Purpose.: Configure Puppeteer for non-root container execution
# Returns.: 0 on success
# ------------------------------------------------------------------------------
configure_puppeteer() {
  log_info "Configuring Puppeteer for container execution"

  # Create Puppeteer config directories for both root and typical users
  mkdir -p /root/.config/puppeteer
  mkdir -p /home/pandoc/.config/puppeteer

  # Create Puppeteer configuration file with proper sandbox options
  cat >/root/.config/puppeteer/config.json <<'EOF'
{
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu",
    "--disable-extensions",
    "--disable-crash-reporter",
    "--disable-breakpad"
  ]
}
EOF

  # Copy for pandoc user as well
  cp /root/.config/puppeteer/config.json /home/pandoc/.config/puppeteer/config.json 2>/dev/null || true

  # Set environment variables for Puppeteer/mermaid-cli
  cat >/etc/profile.d/puppeteer.sh <<'EOF'
export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
export CHROME_PATH=/usr/bin/chromium
EOF

  log_info "Puppeteer configured for non-root execution with system Chromium"
}

# ------------------------------------------------------------------------------
# Function: cleanup
# Purpose.: Clean up package manager caches and unnecessary files
# Returns.: 0 on success
# ------------------------------------------------------------------------------
cleanup() {
  log_info "Cleaning up package manager caches and unnecessary files"

  apt-get clean
  rm -rf /var/lib/apt/lists/*
  npm cache clean --force
  rm -rf /root/.npm /tmp/* /var/tmp/*
  
  # Remove Vulkan/GPU files from Chromium — unused with --disable-gpu/--no-sandbox
  rm -f /usr/lib/chromium/libvk_swiftshader.so \
        /usr/lib/chromium/libVkLayer_khronos_validation.so \
        /usr/lib/chromium/libVkICD_mock_icd.so \
        /usr/lib/chromium/libvulkan.so.1 \
        /usr/lib/chromium/chrome_crashpad_handler || true

  # Remove npm — only needed during install, not at runtime
  # Mark nodejs as manually installed so autoremove does not pull it out
  apt-mark manual nodejs 2>/dev/null || true
  apt-get remove -y npm 2>/dev/null || true
  apt-get autoremove -y 2>/dev/null || true

  # Remove mermaid-cli package TypeScript sources (dist is what runs)
  rm -rf /usr/local/lib/node_modules/@mermaid-js/mermaid-cli/src \
         /usr/local/lib/node_modules/@mermaid-js/mermaid-cli/dist-types || true

  # Remove unnecessary files from node_modules to save space
  find /usr/local/lib/node_modules -name "*.md"       -delete 2>/dev/null || true
  find /usr/local/lib/node_modules -name "*.map"      -delete 2>/dev/null || true
  find /usr/local/lib/node_modules -name "*.ts"       -delete 2>/dev/null || true
  find /usr/local/lib/node_modules -name "CHANGELOG*" -delete 2>/dev/null || true
  find /usr/local/lib/node_modules -name "LICENSE*"   -delete 2>/dev/null || true
  find /usr/local/lib/node_modules -name "test"       -type d -exec rm -rf {} + 2>/dev/null || true
  find /usr/local/lib/node_modules -name "__tests__"  -type d -exec rm -rf {} + 2>/dev/null || true
  find /usr/local/lib/node_modules -name "docs"       -type d -exec rm -rf {} + 2>/dev/null || true

  log_info "Cleanup completed"
}

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
main() {
  log_info "Starting Mermaid installation"

  install_nodejs
  install_chromium_deps
  install_mermaid_cli
  configure_puppeteer
  cleanup

  log_info "Mermaid installation completed successfully"
}

# Run main function
main "$@"
# --- EOF ----------------------------------------------------------------------
