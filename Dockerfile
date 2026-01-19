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

# --- Set shell to bash with pipefail for all RUN commands ---------------------
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
  ARCH="$(dpkg --print-architecture)"; \
  case "$ARCH" in  \
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

# --- Mermaid support temporarily disabled -------------------------------------
# Chromium-based rendering doesn't work with non-root Docker users due to
# sandbox namespace restrictions. See GitHub issue for alternative solutions
# (Kroki, PlantUML, etc.). Keeping fonts for other diagram tools.

# --- Install fonts for diagram rendering --------------------------------------
RUN set -eux; \
  echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80retries; \
  echo 'Acquire::http::Timeout "120";' >> /etc/apt/apt.conf.d/80retries; \
  echo 'Acquire::https::Timeout "120";' >> /etc/apt/apt.conf.d/80retries; \
  echo 'Acquire::ftp::Timeout "120";' >> /etc/apt/apt.conf.d/80retries; \
  for i in 1 2 3; do \
    apt-get update && break || { \
      echo "Attempt $i failed, waiting 10 seconds..."; \
      sleep 10; \
    }; \
  done; \
  apt-get install -y --no-install-recommends \
    fonts-liberation \
    fonts-noto-color-emoji; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# --- Install fonts + runtime deps ---------------------------------------------
COPY scripts/install_fonts_runtime.sh /usr/local/src/scripts/
RUN set -eux; chmod +x /usr/local/src/scripts/install_fonts_runtime.sh; \
    /usr/local/src/scripts/install_fonts_runtime.sh

# --- Install OraDBA Pandoc templates from local files -------------------------
COPY templates/ "${ORADBA}/templates/"
COPY themes/ "${ORADBA}/themes/"
COPY images/ "${ORADBA}/images/"

RUN set -eux; \
    echo "Install OraDBA Templates from local files."; \
    mkdir -p "${WORKDIR}" "${ORADBA}" "${XDG_DATA_HOME}" \
             "${PANDOC_DATA}" "${PANDOC_TEMPLATES}" "${PANDOC_THEMES}"; \
    ln -sf "${ORADBA}/templates/oradba.tex" "${ORADBA}/templates/oradba.latex"; \
    for i in "${ORADBA}"/templates/*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/$(basename "$i")"; \
    done; \
    for i in "${ORADBA}"/templates/oradba.*; do \
      ln -sf "$i" "${PANDOC_TEMPLATES}/default.${i##*.}"; \
    done; \
    for i in "${ORADBA}"/themes/*; do \
      ln -sf "$i" "${PANDOC_THEMES}/$(basename "$i")"; \
    done; \
    ln -sf "${ORADBA}/templates/oradba.pptx" "${PANDOC_DATA}/reference.pptx"; \
    ln -sf "${ORADBA}/templates/oradba.docx" "${PANDOC_DATA}/reference.docx"

# --- Create non-root user for running pandoc ----------------------------------
RUN set -eux; \
    groupadd -r pandoc --gid=1000; \
    useradd -r -g pandoc --uid=1000 --home-dir=/workdir --shell=/bin/bash pandoc; \
    chown -R pandoc:pandoc "${WORKDIR}" "${XDG_DATA_HOME}" "${ORADBA}"; \
    chmod -R 755 "${WORKDIR}" "${XDG_DATA_HOME}" "${ORADBA}"

# --- Define volume, workdir, user, entrypoint ---------------------------------
VOLUME ["${WORKDIR}"]
WORKDIR "${WORKDIR}"
USER pandoc

ENTRYPOINT ["/usr/local/bin/pandoc"]
CMD ["--help"]

# --- EOF ----------------------------------------------------------------------
