# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-03-09
# Revision...: --
# Purpose....: Multi-variant Pandoc Docker image
#              Variants: minimal | standard | mermaid | full
#
# Variants...:
#   minimal   Pandoc binary only, no TeX, no Mermaid (~300MB)
#   standard  Pandoc + TeX Live + fonts + templates (~600MB) [DEFAULT]
#   mermaid   Pandoc + Mermaid/Chromium, no TeX (~1.1GB)
#   full      Pandoc + TeX Live + Mermaid + fonts + templates (~1.4GB)
#
# Build Args.:
#   IMAGE_VARIANT   minimal|standard|mermaid|full (default: standard)
#   SLIM_TEX        0|1 - Slim TeX tree after install (default: 1)
#   PANDOC_VERSION  Pandoc version to install (default: latest)
#
# Build......:
#   # Single variant, local (current arch):
#   docker buildx build --build-arg IMAGE_VARIANT=standard \
#       -t oehrlis/pandoc:dev-standard --load .
#
#   # All variants, multi-platform:
#   ./scripts/build-variants.sh
#
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ==============================================================================
# Builder stage: installs Pandoc and (conditionally) TeX Live
# ==============================================================================
FROM debian:bookworm-slim AS builder
ARG TARGETARCH
ARG IMAGE_VARIANT=standard
ARG SLIM_TEX=1
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

# --- Install Pandoc (always, per arch) ----------------------------------------
RUN set -eux; \
  /usr/local/src/scripts/install_pandoc.sh "${TARGETARCH}"

# --- Install TeX Live (standard and full variants only) -----------------------
RUN set -eux; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    /usr/local/src/scripts/install_texlive.sh; \
  else \
    echo "==> Skipping TeX Live for '${IMAGE_VARIANT}' variant"; \
    mkdir -p /usr/local/texlive; \
  fi; \
  mkdir -p /usr/share/fonts /etc/fonts; \
  touch /etc/profile.d/texlive.sh

# --- Optionally slim the TeX tree (standard/full only) ------------------------
RUN set -eux; \
  if [ "${SLIM_TEX:-0}" = "1" ] && \
     { [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; }; then \
    /usr/local/src/scripts/slim_tex_tree.sh; \
  else \
    echo "==> SLIM_TEX skipped (variant=${IMAGE_VARIANT}, SLIM_TEX=${SLIM_TEX:-0})"; \
  fi

# ==============================================================================
# Final stage: runtime image with selective feature installation
# ==============================================================================
FROM debian:bookworm-slim

# --- Set shell to bash with pipefail for all RUN commands ---------------------
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Build arguments (must be re-declared after FROM) -------------------------
ARG IMAGE_VARIANT=standard
ARG PANDOC_VERSION

# --- Labels -------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@oradba.ch" \
      provider="OraDBA" \
      description="Multi-arch Pandoc image. Variants: minimal|standard|mermaid|full." \
      issues="https://github.com/oehrlis/docker-pandoc/issues" \
      source="https://github.com/oehrlis/docker-pandoc" \
      org.opencontainers.image.vendor="OraDBA" \
      org.opencontainers.image.title="OraDBA Pandoc" \
      org.opencontainers.image.description="Multi-arch (amd64/arm64) Pandoc image with optional TeX Live, Mermaid, MS fonts and filters." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${PANDOC_VERSION}" \
      image.variant="${IMAGE_VARIANT}" \
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
    WORKDIR="/workdir" \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    CHROME_BIN=/usr/bin/chromium \
    MERMAID_CLI_BIN=/usr/local/bin/mmdc

# --- Copy runtime artifacts from builder --------------------------------------
COPY --from=builder /usr/local/bin/pandoc         /usr/local/bin/pandoc
COPY --from=builder /usr/local/texlive            /usr/local/texlive
COPY --from=builder /etc/profile.d/texlive.sh     /etc/profile.d/texlive.sh
COPY --from=builder /usr/share/fonts              /usr/share/fonts
COPY --from=builder /etc/fonts                    /etc/fonts

# --- Copy helper scripts ------------------------------------------------------
COPY scripts/install_pandoc_filters.sh  /usr/local/src/scripts/
COPY scripts/install_fonts_runtime.sh   /usr/local/src/scripts/
COPY scripts/install_mermaid.sh         /usr/local/src/scripts/
RUN chmod +x /usr/local/src/scripts/*.sh

# --- Setup Pandoc symlinks and TeX Live PATH (TeX only for standard/full) -----
RUN set -eux; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
      amd64) TLARCH="x86_64-linux" ;; \
      arm64) TLARCH="aarch64-linux" ;; \
      *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac; \
    TLYEAR=""; \
    for dir in /usr/local/texlive/[0-9][0-9][0-9][0-9]; do \
      if [ -d "$dir" ]; then \
        dirname=$(basename "$dir"); \
        if [ -z "$TLYEAR" ] || [ "$dirname" -gt "$TLYEAR" ]; then \
          TLYEAR="$dirname"; \
        fi; \
      fi; \
    done; \
    TL_BINDIR="/usr/local/texlive/${TLYEAR}/bin/${TLARCH}"; \
    ln -sfn "${TL_BINDIR}" /usr/local/texlive/current-bin || true; \
    ln -sfn /usr/local/texlive/current-bin/* /usr/local/bin/ 2>/dev/null || true; \
    echo "==> TeX Live PATH configured: ${TL_BINDIR}"; \
  else \
    echo "==> Skipping TeX Live PATH setup for '${IMAGE_VARIANT}' variant"; \
  fi; \
  ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-lua; \
  ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-server; \
  fc-cache -fv || true

# --- Install Pandoc Python filters (standard and full variants only) ----------
RUN set -eux; \
  apt-get update; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip curl ca-certificates; \
    FILTER_VENV_DIR=/opt/pandoc-filters \
    FILTERS="pandoc-latex-color pandoc-include pandoc-latex-environment" \
    /usr/local/src/scripts/install_pandoc_filters.sh; \
  else \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    echo "==> Skipping Python filters for '${IMAGE_VARIANT}' variant"; \
  fi; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# --- Install Mermaid / Node.js / Chromium (mermaid and full variants only) ----
RUN set -eux; \
  if [ "${IMAGE_VARIANT}" = "mermaid" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    echo 'Acquire::Retries "3";'         >  /etc/apt/apt.conf.d/80retries; \
    echo 'Acquire::http::Timeout "30";'  >> /etc/apt/apt.conf.d/80retries; \
    echo 'Acquire::https::Timeout "30";' >> /etc/apt/apt.conf.d/80retries; \
    /usr/local/src/scripts/install_mermaid.sh; \
    mkdir -p /usr/local/share/pandoc/filters; \
  else \
    echo "==> Skipping Mermaid for '${IMAGE_VARIANT}' variant"; \
  fi

# --- Install fonts (full suite for standard/full, minimal otherwise) ----------
RUN set -eux; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    /usr/local/src/scripts/install_fonts_runtime.sh; \
  else \
    apt-get update; \
    apt-get install -y --no-install-recommends fontconfig; \
    fc-cache -fv || true; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    echo "==> Minimal font setup for '${IMAGE_VARIANT}' variant"; \
  fi

# --- Install OraDBA templates from GitHub (standard and full variants only) ---
RUN set -eux; \
  mkdir -p "${WORKDIR}"; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    echo "==> Installing OraDBA Templates from GitHub"; \
    mkdir -p "${ORADBA}" "${XDG_DATA_HOME}" \
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
    ln -sf "${ORADBA}/templates/oradba.docx" "${PANDOC_DATA}/reference.docx"; \
  else \
    echo "==> Skipping templates for '${IMAGE_VARIANT}' variant"; \
  fi

# --- Copy local template overrides (standard and full variants only) ----------
COPY templates/ /tmp/pandoc-templates-override/
RUN set -eux; \
  if [ "${IMAGE_VARIANT}" = "standard" ] || [ "${IMAGE_VARIANT}" = "full" ]; then \
    cp -r /tmp/pandoc-templates-override/. "${ORADBA}/templates/"; \
    ln -sf "${ORADBA}/templates/oradba.tex" "${ORADBA}/templates/oradba.latex"; \
    for i in "${ORADBA}"/templates/*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/$(basename "$i")"; \
    done; \
    for i in "${ORADBA}"/templates/oradba.*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/default.${i##*.}"; \
    done; \
  fi; \
  rm -rf /tmp/pandoc-templates-override

# --- Copy Mermaid Lua filter (available in all variants; used by mermaid/full)
RUN mkdir -p /usr/local/share/pandoc/filters
COPY mermaid.lua /usr/local/share/pandoc/filters/mermaid.lua

# --- Define volume, workdir, entrypoint ---------------------------------------
VOLUME ["${WORKDIR}"]
WORKDIR "${WORKDIR}"

ENTRYPOINT ["/usr/local/bin/pandoc"]
CMD ["--help"]

# --- EOF ----------------------------------------------------------------------
