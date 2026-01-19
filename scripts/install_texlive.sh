#!/bin/sh
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: install_texlive.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Install a minimal, yearless TeX Live into /usr/local/texlive
#              with just the packages needed for our Pandoc/XeLaTeX templates.
#              - Small profile: basic + latex + xetex
#              - Curated mirrors with fallback and verification
#              - tlmgr used only during install, then removed
#              - Docs/sources removed; binaries stripped
# Usage......: install_texlive.sh
# Notes......: Requires root. Needs: curl, tar, dpkg, strip, fc-cache, wget.
# Reference..: https://tug.org/texlive/
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
set -eu

# --- Default Values ------------------------------------------------------------
TLROOT="/usr/local/texlive"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Environment for the TeX Live installer (robust downloads)
export TEXLIVE_DOWNLOADER=wget
export TL_DOWNLOAD_ARGS="--tries=5 --timeout=30 --continue"
export TEXLIVE_PREFER_HTTPS=1

# Curated mirror list (stable, fast, HTTPS)
MIRRORS="
https://ftp.fau.de/ctan/systems/texlive/tlnet
https://mirror.kumi.systems/ctan/systems/texlive/tlnet
https://ctan.mirror.garr.it/mirrors/CTAN/systems/texlive/tlnet
https://ctan.math.illinois.edu/systems/texlive/tlnet
https://mirrors.rit.edu/CTAN/systems/texlive/tlnet
https://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet
"

# Minimal package set for our templates (beyond collection-latex/xetex)
PKGS="adjustbox afterpage amsmath amssymb array awesomebox babel background
      beamerarticle biblatex bookmark booktabs calc caption csquotes etoolbox
      fancyvrb float fontenc fontspec footmisc footnote footnotehyper
      footnotebackref fvextra geometry graphicx hyperref iftex inputenc
      listings lmodern longtable lua-ul luacolor luatexja-fontspec
      luatexja-preset mathspec mdframed microtype multirow natbib pagecolor
      parskip pgfpages ragged2e scrlayer-scrpage sectsty selnolig setspace
      soul sourcecodepro sourcesanspro subcaption svg tabularx textcomp tikz
      titling unicode-math ulem upquote xcolor needspace zref xeCJK xurl
      fontawesome5 polyglossia"

# --- Functions -----------------------------------------------------------------
usage() {
  cat <<'EOF'
Install a minimal TeX Live into /usr/local/texlive (yearless layout).
No arguments required. Must be run as root.

Installs: scheme basic+latex+xetex + a curated package set.
Removes: docs, sources, tlmgr. Strips ELF binaries.
EOF
}

err() {
  echo "Error: $*" >&2
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || err "Missing: $1"; }

# --- Main Script Logic ---------------------------------------------------------
# Basic help (-h/--help)
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
  usage
  exit 0
}

# Check required tools up front
need curl
need tar
need dpkg
need strip
need fc-cache
need wget
need grep

# --- Architecture mapping (Debian arch -> TeX Live bin dir) -------------------
DPKG_ARCH="$(dpkg --print-architecture)"
case "$DPKG_ARCH" in
  amd64) TLARCH="x86_64-linux" ;;
  arm64) TLARCH="aarch64-linux" ;;
  *) err "Unsupported dpkg architecture: ${DPKG_ARCH}" ;;
esac

# --- Fetch installer (with fallback if mirror redirect fails) ------------------
echo "Fetching TeX Live installer (install-tl-unx.tar.gz)…"
if ! curl -fsSL \
  "https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz" |
  tar xz -C "$TMP" --strip-components=1; then
  curl -fsSL \
    "https://ftp.fau.de/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz" |
    tar xz -C "$TMP" --strip-components=1
fi

# --- Installer profile (yearless layout under /usr/local/texlive) -------------
cat >"$TMP/texlive.profile" <<'EOF'
selected_scheme scheme-basic
TEXDIR /usr/local/texlive
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/texmf-config
TEXMFSYSVAR /usr/local/texlive/texmf-var
TEXMFVAR ~/.texlive/texmf-var
TEXMFCONFIG ~/.texlive/texmf-config
TEXMFHOME ~/texmf
collection-basic 1
collection-latex 1
collection-xetex 1
instopt_adjustpath 0
instopt_letter 0
tlpdbopt_autobackup 0
tlpdbopt_create_formats 1
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
EOF

# --- Run installation against curated mirrors ---------------------------------
INSTALL_OK=0
for REPO in $MIRRORS; do
  echo "install-tl: trying mirror: $REPO"
  if "$TMP/install-tl" \
    --profile "$TMP/texlive.profile" \
    --repository "$REPO"; then
    INSTALL_OK=1
    TL_REPO="$REPO"
    break
  else
    echo "install-tl failed on $REPO, trying next…"
  fi
done
[ "$INSTALL_OK" -eq 1 ] || err "TeX Live installation failed on all mirrors"

# --- Validate bin dir and make available on PATH -------------------------------
TL_BINDIR="${TLROOT}/bin/${TLARCH}"
if [ ! -x "${TL_BINDIR}/tlmgr" ] && [ ! -x "${TL_BINDIR}/xelatex" ]; then
  echo "ERROR: TeX Live bin dir not found at ${TL_BINDIR}"
  ls -la "${TLROOT}" || true
  tail -200 "${TLROOT}/install-tl.log" 2>/dev/null || true
  exit 1
fi
export PATH="${TL_BINDIR}:$PATH"

# --- tlmgr updates & package installation (with repo verification) ------------
tlmgr option repository "$TL_REPO" || true
tlmgr update --self --verify-repo=all || true
tlmgr update --all --verify-repo=all || true

# The base collections are already installed; add only what we actually use.
# shellcheck disable=SC2086
tlmgr install $PKGS --verify-repo=all || true

# --- Rebuild file name db, formats, and font maps ------------------------------
mktexlsr || true
fmtutil-sys --all --no-error-if-no-format || true
updmap-sys --syncwithtrees || true

# --- Sanity checks for key binaries and style files ----------------------------
need xelatex
for sty in fontspec.sty fontawesome5.sty zref-abspage.sty listings.sty; do
  kpsewhich "$sty" >/dev/null 2>&1 || err "Missing TeX style: $sty"
done

# --- Cleanup: remove docs/sources, tlmgr, and strip binaries -------------------
rm -rf "${TLROOT}/texmf-dist/doc" "${TLROOT}/texmf-dist/source" || true
rm -rf "${TLROOT}/tlpkg" || true
rm -f "${TL_BINDIR}/tlmgr" || true

# Strip ELF executables to save space (ignore non-ELF files)
find "${TL_BINDIR}" -type f -perm -111 \
  -exec sh -c 'file -b "$1" | grep -q ELF && strip --strip-unneeded "$1" || : ' \
  _ {} \; || true

# --- Refresh font cache (harmless no-op if nothing changed) --------------------
fc-cache -fv || true

# --- Make TeX Live available to all shells ------------------------------------
echo "export PATH=${TL_BINDIR}:\$PATH" >/etc/profile.d/texlive.sh
chmod 0644 /etc/profile.d/texlive.sh

echo "TeX Live installed in ${TLROOT} (yearless); packages added; tlmgr removed."
# --- EOF -----------------------------------------------------------------------
