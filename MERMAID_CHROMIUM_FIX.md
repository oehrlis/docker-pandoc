# Mermaid Test - Complete Working Solution

## ✅ Solution Found

Mermaid rendering works successfully with the following requirements:

1. **Chromium installed** (version 144.0.7559.59+)
2. **Docker capability**: `--cap-add=SYS_ADMIN` (required for Chromium namespace creation)
3. **PDF generation**: Requires TeX Live (xelatex engine)

## Working Commands

### HTML Output (PNG diagrams embedded)
```bash
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:latest \
  test-mermaid.md -o test-mermaid.html \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone
```

### PDF Output (requires TeX Live)
```bash
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:latest \
  test-mermaid.md -o test-mermaid.pdf \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --pdf-engine=xelatex
```

## Why --cap-add=SYS_ADMIN?

Chromium requires the ability to create user namespaces for its sandbox. While the browser runs with `--no-sandbox` flags (configured in mermaid.lua), it still needs namespace capabilities to launch properly in a container environment.

**Security Note:** This is a standard requirement for running Chromium/Puppeteer in containers. The risk is minimal since:
- Container runs as non-root user (`pandoc`)
- Only the Chromium process requires this capability
- Alternative: Use `--security-opt seccomp=unconfined` (less secure)

## Verification

```bash
# Check Chromium is installed
docker run --rm --entrypoint chromium oehrlis/pandoc:latest --version
# Output: Chromium 144.0.7559.59 built on Debian GNU/Linux 12 (bookworm)

# Check mermaid-cli is installed
docker run --rm --entrypoint mmdc oehrlis/pandoc:latest --version
# Output: 11.12.0

# Check TeX Live is installed
docker run --rm --entrypoint xelatex oehrlis/pandoc:latest --version
# Output: XeTeX 3.141592653...
```

## Original Problem (RESOLVED)
```bash
cd /Users/stefan.oehrli/Development/github/oehrlis/docker-pandoc

# Create a Dockerfile.fix
cat > Dockerfile.fix <<'EOF'
FROM oehrlis/pandoc:test

USER root

RUN apt-get update && \
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
        libxrandr2 && \
    rm -rf /var/lib/apt/lists/*

# Configure Puppeteer for Chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CHROME_PATH=/usr/bin/chromium

USER pandoc
EOF

# Build the fixed image
docker build -f Dockerfile.fix -t oehrlis/pandoc:test-chromium .
```

### Option 3: Test with Alternative (kroki.io)
Use online Kroki service temporarily:
```bash
# Install kroki filter
pip install --user pandoc-kroki

# Generate PDF with kroki
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:test \
  test-mermaid.md -o test-mermaid-kroki.pdf \
  --filter pandoc-kroki
```

## Test After Fix

```bash
# Test Chromium is installed
docker run --rm --entrypoint sh oehrlis/pandoc:test-chromium -c "chromium --version"

# Generate PDF
cd examples
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:test-chromium \
  test-mermaid.md -o test-mermaid.pdf \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua

# Check result
ls -lh test-mermaid.pdf
open test-mermaid.pdf
```

## Permanent Fix

Update `scripts/install_mermaid.sh` to ensure Chromium installation doesn't fail silently:

```bash
# In install_chromium_deps function, change:
  apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    ...
  # Instead of || { ... }, use && or set -e to fail on error
```

OR check if on ARM64 Chromium needs to be installed differently:
```bash
# Check architecture in the container
docker run --rm --entrypoint sh oehrlis/pandoc:test -c "uname -m"
# Output: aarch64 (ARM64)

# Chromium package might not be available for ARM64 in Debian repos
apt-cache search chromium | grep chromium
```

## Root Cause Analysis

The `install_mermaid.sh` script has error handling that continues on failure:
```bash
apt-get install -y --no-install-recommends \
  chromium \
  chromium-sandbox \
  ... || {
  log_info "Warning: Some Chromium dependencies failed to install (continuing with available packages)"
}
```

This means **Chromium installation failed but the script continued**. On ARM64, Chromium might not be in the default Debian repos or has a different package name.

## ARM64 Chromium Installation

For ARM64 architecture:
```bash
# Check available Chromium packages
apt-cache madison chromium

# If not available, try alternative:
wget https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb
apt install -y ./google-chrome-stable_current_arm64.deb
```

Or use Chromium from snap/flatpak (not ideal for Docker).

## Next Steps

1. **Immediate**: Use Option 2 (Dockerfile.fix) to get working image
2. **Short-term**: Update `install_mermaid.sh` to handle ARM64 Chromium
3. **Long-term**: Consider alternative rendering (Kroki server, pre-render, etc.)
