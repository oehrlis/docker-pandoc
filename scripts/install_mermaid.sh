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
  
  # Skip Puppeteer download since we're using system Chromium
  export PUPPETEER_SKIP_DOWNLOAD=true
  export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
  
  # Install mermaid-cli globally
  if [[ "${MERMAID_VERSION}" = "latest" ]]; then
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
  
  # Create Puppeteer config directory in default location
  mkdir -p /root/.config/puppeteer
  
  # Create Puppeteer configuration file
  # This tells Puppeteer to use system Chromium and skip download
  cat > /root/.config/puppeteer/config.json <<'EOF'
{
  "skipDownload": true
}
EOF
  
  # Set environment variables for Puppeteer/mermaid-cli
  cat >> /etc/profile.d/puppeteer.sh <<'EOF'
export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
export CHROME_PATH=/usr/bin/chromium
EOF
  
  # Also set it in the Docker environment
  echo "ENV PUPPETEER_SKIP_DOWNLOAD=true" >> /tmp/puppeteer_env
  echo "ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium" >> /tmp/puppeteer_env
  echo "ENV CHROME_PATH=/usr/bin/chromium" >> /tmp/puppeteer_env
  
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
