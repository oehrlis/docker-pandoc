#!/bin/sh
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: install_fonts_runtime.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Install minimal runtime deps (Python/venv, curl, fontconfig) and
#              fonts (MS core, Open Sans, Montserrat) in a single layer. Works
#              with classic sources.list or Deb822 debian.sources. Cleans up
#              caches to keep image small.
# Usage......: install_fonts_runtime.sh
# Notes......: - Requires root and Debian-based image.
#              - Enables contrib, non-free, non-free-firmware to fetch MS fonts.
#              - Preseeds EULA for ttf-mscorefonts-installer.
#              - Attempts Montserrat via APT; falls back to upstream Google repo.
# Reference..: Debian Deb822: /etc/apt/sources.list.d/debian.sources
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
set -eu
export DEBIAN_FRONTEND=noninteractive

# --- Default Values ------------------------------------------------------------
OPENSSL_CONF="${OPENSSL_CONF:-/etc/ssl/openssl.cnf}" # keep curl happy in slim

# --- Functions -----------------------------------------------------------------
err() {
  echo "Error: $*" >&2
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || err "Missing: $1"; }

enable_nonfree() {
  # Enable contrib, non-free, non-free-firmware for both classic and Deb822
  if [ -f /etc/apt/sources.list ] &&
    grep -q '^[[:space:]]*deb[[:space:]]' /etc/apt/sources.list; then
    # Classic sources.list: append components if only 'main' is present
    sed -E -i \
      's/^(deb[[:space:]][^#]*[[:space:]]main)([[:space:]].*)?$/\1 contrib non-free non-free-firmware\2/' \
      /etc/apt/sources.list
  elif [ -f /etc/apt/sources.list.d/debian.sources ]; then
    # Deb822: update Components: line or insert one next to Suites/URIs
    if grep -q '^Components:' /etc/apt/sources.list.d/debian.sources; then
      sed -i \
        's/^Components:.*/Components: main contrib non-free non-free-firmware/' \
        /etc/apt/sources.list.d/debian.sources
    else
      awk '
        /^Suites:|^URIs:/ && !added {
          print; print "Components: main contrib non-free non-free-firmware";
          added=1; next
        }
        /^$/ { added=0 } { print }
      ' /etc/apt/sources.list.d/debian.sources \
        >/etc/apt/sources.list.d/debian.sources.new
      mv /etc/apt/sources.list.d/debian.sources.new \
        /etc/apt/sources.list.d/debian.sources
    fi
  else
    # Construct a sensible default sources.list (e.g., bookworm)
    . /etc/os-release
    CODENAME="${VERSION_CODENAME:-bookworm}"
    cat >/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian ${CODENAME} main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${CODENAME}-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${CODENAME}-updates main contrib non-free non-free-firmware
EOF
  fi
}

install_montserrat_fallback() {
  # Install Montserrat variable fonts directly from the official Google repo
  echo "fonts-montserrat not available via APT, fetching from google/fonts…"
  install -d -m 0755 /usr/local/share/fonts/montserrat
  curl -fsSL \
    -o /usr/local/share/fonts/montserrat/Montserrat[wght].ttf \
    "https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf"
  curl -fsSL \
    -o /usr/local/share/fonts/montserrat/Montserrat-Italic[wght].ttf \
    "https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-Italic%5Bwght%5D.ttf"
  chmod 0644 /usr/local/share/fonts/montserrat/*.ttf
}

# --- Main Script Logic ---------------------------------------------------------
# Pre-flight checks (tools commonly present in Debian images)
need sed
need awk
need grep
need curl

# Enable non-free repos so MS core fonts can be installed
enable_nonfree
apt-get update

# Preseed EULA for MS core fonts to avoid interactive prompt
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" |
  debconf-set-selections || true

# Base runtime: certificate store, fontconfig, curl, Python venv tooling
apt-get install -y --no-install-recommends \
  ca-certificates fontconfig curl \
  python3 python3-venv python3-pip \
  ttf-mscorefonts-installer fonts-open-sans

# Try Montserrat via APT first; if unavailable, use official upstream files
if ! apt-get install -y --no-install-recommends fonts-montserrat 2>/dev/null; then
  install_montserrat_fallback
fi

# Rebuild font cache so XeLaTeX and system tools see the new fonts
fc-cache -fv || true

# Cleanup to keep the image minimal
apt-get purge -y --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* || true
rm -rf /tmp/* /var/tmp/* || true

echo "Fonts and minimal runtime deps installed; caches cleaned."
# --- EOF -----------------------------------------------------------------------
