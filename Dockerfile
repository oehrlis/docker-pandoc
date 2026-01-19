# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Dockerfile to build a minimal Pandoc + TeX Live (TinyTeX style)
#              image with required fonts and filters. Optimized for multi-arch
#              (amd64, arm64) builds using Buildx.
#
# Features...:
#   - Base: debian:bookworm-slim
#   - Pandoc: latest per-arch from GitHub (multi-stage install)
#   - TeX: TinyTeX-like minimal profile, stripped down (no tlmgr at runtime)
#   - Fonts: MS Core Fonts, Open Sans, Montserrat
#   - Filters: installed in a PEP-668 safe venv
#   - Multi-stage: build heavy artifacts in "builder", copy only runtime
#
# Build......:
#   docker buildx create --use --name multi || true
#   docker buildx build --platform linux/amd64,linux/arm64 \
#       -t oehrlis/pandoc:tinytex \
#       --push .
#
# Quick Test.:
#   echo '\documentclass{article}\usepackage{fontspec}\setmainfont{Times New Roman}\begin{document}Hello Times € ✓\end{document}' \
#     > /tmp/fonttest.tex
#   xelatex -interaction=nonstopmode -halt-on-error -output-directory=/tmp /tmp/fonttest.tex
#
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ==============================================================================
# Builder stage: installs pandoc, TeX Live, and optionally slims the tree
# ==============================================================================
FROM debian:bookworm-slim AS builder
ARG TARGETARCH
ARG SLIM_TEX=0
ARG PRUNE_MS_FONTS=0
ARG PANDOC_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC

# --- Install base build tools -------------------------------------------------
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates curl wget xz-utils unzip fontconfig \
    file perl rsync gnupg binutils; \
  rm -rf /var/lib/apt/lists/*

# --- Copy helper scripts into image -------------------------------------------
COPY scripts/ /usr/local/src/scripts/
RUN chmod +x /usr/local/src/scripts/*.sh

# --- Install Pandoc (latest, per arch) ----------------------------------------
RUN set -eux; \
  /usr/local/src/scripts/install_pandoc.sh "${TARGETARCH}"

# --- Install TeX Live (minimal profile) ---------------------------------------
RUN set -eux; \
  /usr/local/src/scripts/install_texlive.sh

# --- Optionally slim the TeX tree and fonts -----------------------------------
RUN set -eux; \
  if [ "${SLIM_TEX:-0}" = "1" ]; then \
    /usr/local/src/scripts/slim_tex_tree.sh; \
  else \
    echo "SLIM_TEX disabled (pass --build-arg SLIM_TEX=1 to enable)"; \
  fi

# ==============================================================================
# Final stage: runtime image with fonts, pandoc, TeX Live, and filters
# ==============================================================================
FROM debian:bookworm-slim

# --- Labels (for metadata) ----------------------------------------------------
ARG PANDOC_VERSION
LABEL maintainer="stefan.oehrli@oradba.ch" \
      provider="OraDBA" \
      description="Minimal multi-arch Docker image for Pandoc with TeX Live (TinyTeX style), MS Core Fonts, Open Sans, Montserrat, and Pandoc filters." \
      issues="https://github.com/oehrlis/pandoc_template/issues" \
      source="https://github.com/oehrlis/pandoc_template" \
      org.opencontainers.image.vendor="OraDBA" \
      org.opencontainers.image.title="OraDBA Pandoc + TeX Live" \
      org.opencontainers.image.description="Multi-arch (amd64/arm64) image with Pandoc, TeX Live, MS fonts, and Pandoc filters for reproducible document builds." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${PANDOC_VERSION}" \
      volume.workdir="/workdir" \
      volume.templates="/opt/pandoc-data/pandoc/templates" \
      volume.themes="/opt/pandoc-data/pandoc/themes"

# --- Environment --------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    XDG_DATA_HOME="/opt/pandoc-data" \
    PANDOC_DATA="/opt/pandoc-data/pandoc" \
    PANDOC_TEMPLATES="/opt/pandoc-data/pandoc/templates" \
    PANDOC_THEMES="/opt/pandoc-data/pandoc/themes" \
    GITHUB_URL="https://github.com/oehrlis/pandoc_template/archive/refs/heads/master.tar.gz" \
    ORADBA="/oradba" \
    WORKDIR="/workdir"

# --- Copy runtime artifacts from builder --------------------------------------
COPY --from=builder /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY --from=builder /usr/local/texlive /usr/local/texlive
COPY --from=builder /etc/profile.d/texlive.sh /etc/profile.d/texlive.sh
COPY --from=builder /usr/share/fonts /usr/share/fonts
COPY --from=builder /etc/fonts /etc/fonts

# --- Setup PATH for TeX Live + symlinks ---------------------------------------
RUN set -eux; \
  set -o pipefail; \
  ARCH="$(dpkg --print-architecture)"; \
  case "$ARCH" in  \
    amd64) TLARCH="x86_64-linux" ;; \
    arm64) TLARCH="aarch64-linux" ;; \
    *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
  esac; \
  TLYEAR=""; \
  for d in /usr/local/texlive/[0-9][0-9][0-9][0-9]; do \
    [ -d "$d" ] || continue; \
    year=$(basename "$d"); \
    if [ -z "$TLYEAR" ] || [ "$year" -gt "$TLYEAR" ]; then \
      TLYEAR="$year"; \
    fi; \
  done; \
  TL_BINDIR="/usr/local/texlive/${TLYEAR}/bin/${TLARCH}"; \
  ln -sfn "${TL_BINDIR}" /usr/local/texlive/current-bin || true; \
  ln -sfn /usr/local/texlive/current-bin/* /usr/local/bin/ || true; \
  ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-lua; \
  ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-server; \
  fc-cache -fv || true

# --- Install Pandoc filters in venv (PEP-668 safe) ----------------------------
COPY scripts/install_pandoc_filters.sh /usr/local/src/scripts/install_pandoc_filters.sh
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends python3 python3-venv python3-pip curl ca-certificates; \
  chmod +x /usr/local/src/scripts/install_pandoc_filters.sh; \
  FILTER_VENV_DIR=/opt/pandoc-filters \
  FILTERS="pandoc-latex-color pandoc-include pandoc-latex-environment" \
  /usr/local/src/scripts/install_pandoc_filters.sh; \
  apt-get purge -y --auto-remove; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# --- Install Node.js and dependencies for Mermaid rendering ------------------
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    chromium \
    chromium-sandbox \
    fonts-liberation \
    fonts-noto-color-emoji \
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
    libasound2; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# --- Install mermaid-cli and pandoc filter globally --------------------------
RUN set -eux; \
  npm install -g \
    @mermaid-js/mermaid-cli \
    mermaid-filter; \
  npm cache clean --force

# --- Configure Puppeteer to use system Chromium (avoid download) -------------
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    CHROME_BIN=/usr/bin/chromium

# --- Install fonts + runtime deps ---------------------------------------------
COPY scripts/install_fonts_runtime.sh /usr/local/src/scripts/
RUN set -eux; chmod +x /usr/local/src/scripts/install_fonts_runtime.sh; \
    /usr/local/src/scripts/install_fonts_runtime.sh

# --- Install OraDBA Pandoc templates from GitHub ------------------------------
RUN set -eux; \
    set -o pipefail; \
    echo "Install latest OraDBA Templates from GitHub."; \
    mkdir -p "${WORKDIR}" "${ORADBA}" "${XDG_DATA_HOME}" \
             "${PANDOC_DATA}" "${PANDOC_TEMPLATES}" "${PANDOC_THEMES}"; \
    curl -Lf "${GITHUB_URL}" | tar zxv --strip-components=1 -C "${ORADBA}"; \
    rm -rf "${ORADBA}/examples" "${ORADBA}/.gitignore" \
           "${ORADBA}/LICENSE" "${ORADBA}/README.md"; \
    ln -sf "${ORADBA}/templates/oradba.tex" "${ORADBA}/templates/oradba.latex"; \
    for i in "${ORADBA}"/templates/*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/$(basename "$i")"; \
    done; \
    for i in "${ORADBA}"/templates/oradba.*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/default.${i##*.}"; \
    done; \
    for i in "${ORADBA}"/themes/*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/$(basename "$i")"; \
    done; \
    ln -sf "${ORADBA}/templates/oradba.pptx" "${PANDOC_DATA}/reference.pptx"; \
    ln -sf "${ORADBA}/templates/oradba.docx" "${PANDOC_DATA}/reference.docx"

# --- Define volume, workdir, entrypoint ---------------------------------------
VOLUME ["${WORKDIR}"]
WORKDIR "${WORKDIR}"

ENTRYPOINT ["/usr/local/bin/pandoc"]
CMD ["--help"]

# --- EOF ----------------------------------------------------------------------
