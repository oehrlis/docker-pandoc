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
# Notes......: Installs Node.js 20.x, Chromium, and configures Puppeteer for
#              non-root container execution
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
  
  # Install dependencies for setup script
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl gnupg
  
  # Setup NodeSource repository
  curl -fsSL "https://deb.nodesource.com/setup_${NODEJS_VERSION}.x" | bash -
  
  # Install Node.js
  apt-get install -y --no-install-recommends nodejs
  
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
  
  # Install Chromium and required libraries for headless browser
  apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    fonts-liberation \
    fonts-noto-color-emoji \
    libnss3 \
    libxss1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2
}

# ------------------------------------------------------------------------------
# Function: install_mermaid_cli
# Purpose.: Install mermaid-cli globally via npm
# Returns.: 0 on success
# ------------------------------------------------------------------------------
install_mermaid_cli() {
  log_info "Installing mermaid-cli"
  
  # Install mermaid-cli globally
  if [ "${MERMAID_VERSION}" = "latest" ]; then
    npm install -g @mermaid-js/mermaid-cli
  else
    npm install -g "@mermaid-js/mermaid-cli@${MERMAID_VERSION}"
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
  
  # Create Puppeteer config directory
  mkdir -p /workdir/.config/puppeteer
  
  # Create Puppeteer configuration file
  # This tells Puppeteer to use system Chromium and skip download
  cat > /workdir/.config/puppeteer/config.json <<'EOF'
{
  "executablePath": "/usr/bin/chromium",
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--disable-dev-shm-usage",
    "--disable-accelerated-2d-canvas",
    "--no-first-run",
    "--no-zygote",
    "--single-process",
    "--disable-gpu"
  ]
}
EOF
  
  # Set environment variable for Puppeteer config
  echo 'export PUPPETEER_CONFIG_PATH=/workdir/.config/puppeteer/config.json' >> /etc/profile.d/puppeteer.sh
  
  log_info "Puppeteer configured for non-root execution with system Chromium"
}

# ------------------------------------------------------------------------------
# Function: cleanup
# Purpose.: Clean up package manager caches
# Returns.: 0 on success
# ------------------------------------------------------------------------------
cleanup() {
  log_info "Cleaning up package manager caches"
  
  apt-get clean
  rm -rf /var/lib/apt/lists/*
  npm cache clean --force
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
