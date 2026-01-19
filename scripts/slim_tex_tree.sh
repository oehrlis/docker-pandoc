#!/bin/sh
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: slim_tex_tree.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Aggressively slim a TeX Live tree and (optionally) selected
#              system fonts to reduce image size. Intended for builder stage
#              after TeX Live/TinyTeX install.
# Usage......: slim_tex_tree.sh
# Env........: PRUNE_MS_FONTS=1  # remove selected MS fonts (Verdana, Georgia,
#                                 # Comic, Andale, Trebuchet)
#              SHOW_TOP=1        # show top remaining TeX directories by size
# Notes......: - Designed for Debian/TeX Live layouts under /usr/local/texlive.
#              - Safe to run multiple times (best effort cleanup).
#              - Requires: dpkg, du, awk, grep, sed, fc-cache.
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
set -eu

# --- Default Values ------------------------------------------------------------
TEXROOT="/usr/local/texlive"
FONTSROOT="/usr/share/fonts"

# --- Functions -----------------------------------------------------------------
usage() {
  cat <<'EOF'
Slim a TeX Live installation and optionally prune selected Microsoft fonts.

Environment:
  PRUNE_MS_FONTS=1   Remove Verdana/Trebuchet/Georgia/Andale/Comic from system.
  SHOW_TOP=1         Show top remaining TeX directories (by size) after prune.
EOF
}

err() {
  echo "Error: $*" >&2
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || err "Missing: $1"; }

to_kb() { du -sk "$1" 2>/dev/null | awk '{print $1+0}'; }

fmt_h() {
  # Format KB into MB/GB with one decimal
  awk -v kb="${1:-0}" '
    BEGIN {
      mb = kb/1024.0; gb = mb/1024.0;
      if (gb >= 1) printf "%.1f GB", gb; else printf "%.1f MB", mb;
    }'
}

# --- Main Script Logic ---------------------------------------------------------
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && {
  usage
  exit 0
}

# Pre-flight
need dpkg
need du
need awk
need grep
need fc-cache || true

tex_before_kb=$(to_kb "$TEXROOT")
fonts_before_kb=$(to_kb "$FONTSROOT")
total_before_kb=$((tex_before_kb + fonts_before_kb))

echo "=== Slimming report (before) ==="
echo "TeX Live:  $(fmt_h "$tex_before_kb")"
echo "Fonts:     $(fmt_h "$fonts_before_kb")"
echo "TOTAL:     $(fmt_h "$total_before_kb")"
echo

# --- Determine TeX Live bin dir (year + arch) ---------------------------------
DPKG_ARCH="$(dpkg --print-architecture)"
case "$DPKG_ARCH" in
  amd64) TLARCH="x86_64-linux" ;;
  arm64) TLARCH="aarch64-linux" ;;
  *) err "Unsupported dpkg architecture: ${DPKG_ARCH}" ;;
esac

# If TL is yearful, use the newest year; otherwise allow yearless layouts
# Find the newest 4-digit year directory, if any
TLYEAR=""
for d in "$TEXROOT"/[0-9][0-9][0-9][0-9]; do
  [ -d "$d" ] || continue
  year=$(basename "$d")
  if [ -z "$TLYEAR" ] || [ "$year" -gt "$TLYEAR" ]; then
    TLYEAR="$year"
  fi
done

if [ -n "$TLYEAR" ]; then
  TL_BINDIR="$TEXROOT/${TLYEAR}/bin/${TLARCH}"
else
  TL_BINDIR="$TEXROOT/bin/${TLARCH}"
fi
export PATH="${TL_BINDIR}:$PATH"

# --- 1) Remove user tree (if present) ------------------------------------------
rm -rf /root/texmf || true

# --- 2) Prune rarely used LaTeX packages --------------------------------------
LATEX_DIR="$TEXROOT/texmf-dist/tex/latex"
if [ -d "$LATEX_DIR" ]; then
  echo "Pruning LaTeX trees under $LATEX_DIR …"
  cd "$LATEX_DIR"
  rm -rf \
    a0poster a4wide achemso acro* actuarial* bewerbung biochemistr* \
    bithesis bizcard bondgraph* bookshelf bubblesort carbohydrates \
    catechis cclicenses changelog cheatsheet circui* commedit comment \
    contracard course* csv* currvita* cv* dateiliste* denisbdoc \
    diabetes* dinbrief directory dirtytalk duck* duotenzor \
    dynkin-diagrams easy* elegant* elzcards emoji enigma es* \
    etaremune europasscv europecv exam* exceltex exercis* exesheet \
    ffslides fibeamer fink fithesis fixme* fjodor fla* flip* form* \
    fonttable forest g-brief gauss gcard gender genealogy* git* \
    gloss* gmdoc* HA-prosper hackthefootline halloweenmath hand* \
    harnon-cv harpoon harveyballs he-she hobby hpsdiss ifmslide \
    image-gallery invoice* interactiveworkbook isorot isotope \
    istgame iwhdp jknapltx jlabels jslectureplanner jumplines \
    kalendarium kantlipsum keystroke kix knitting* knowledge \
    komacv* labels* ladder lectures lettr* lewis logbox magaz \
    mail* makebarcode mandi mathexam mceinleger mcexam \
    medstarbeamer menu* mi-solns minorrevision minutes mla-paper \
    mnotes moderncv modernposter moderntimeline modiagram moodle \
    multiaudience mwe my* neuralnetwork newspaper nomen* papermas \
    pas-* pb-diagram permutepetiteannonce phf* philex \
    phonenumbers photo piff* pinlabel pixelart plantslabels \
    pmboxdraw pmgraph polynom* powerdot ppr-prv practicalreports \
    pressrelease probsoln productbox progress* proofread protocol \
    psbao psfrag* pst-* python qcircuit qcm qrcode qs* quantikz \
    quicktype quiz2socrative quotchap qyxf-book ran* rcs* \
    readablecv realboxes recipe* rectopma \
    reflectgraphics register reotex repeatindex rterface \
    rulercompass runcode sa-tikz sauerj schedule schemabloc \
    schooldocs scratch* scsnowman sdrt semant* seminar sem* \
    sesstime setdeck sf298 sffms shadethm shdoc shipunov \
    signchart simple* skb skdoc skeldoc skills skrapport \
    smartdiagram spectralsequences sslides studenthandouts svn* \
    swfigure swimgraf syntaxdi syntrace syntree table-fct \
    tableaux tabu talk tasks tdclock technics ted texmate \
    texpower texshade threadcol ticket ticollege todo* \
    tqft tucv tufte-latex twoup uebungsblatt uml \
    unravel upmethodology uwmslide vdmlisting venndiagram \
    verbasef verifiche versonotes vhistory vocaltract was \
    webquiz williams willowtreebook worksheet xbmks xcookybooky \
    xcpdftips xdoc xebaposter xtuthesis xwatermark xytree ya* \
    ycbook ydoc yplan zebra-goodies zed-csp zhlipsum ziffer zw* ||
    true
fi

# --- 3) Remove CJK/legacy font trees not needed from TeX tree ------------------
find "$TEXROOT" -type d -name "wadalab" -exec rm -rf {} + || true
find "$TEXROOT" -type d -name "uhc" -exec rm -rf {} + || true
find "$TEXROOT" -type d -name "arphic" -exec rm -rf {} + || true

# --- 4) Optional: prune some Microsoft fonts from system -----------------------
if [ "${PRUNE_MS_FONTS:-0}" = "1" ]; then
  echo "Pruning selected MS core fonts …"
  rm -rf /usr/share/fonts/truetype/msttcorefonts/?erdana* || true # Verdana
  rm -rf /usr/share/fonts/truetype/msttcorefonts/?rebuc* || true  # Trebuchet
  rm -rf /usr/share/fonts/truetype/msttcorefonts/?eorgia* || true # Georgia
  rm -rf /usr/share/fonts/truetype/msttcorefonts/?ndale* || true  # Andale
  rm -rf /usr/share/fonts/truetype/msttcorefonts/?omic* || true   # Comic
fi

# --- 5) Rebuild caches / filename DB (best effort) -----------------------------
fc-cache -fv || true
mktexlsr || true

# --- Size report (after) -------------------------------------------------------
tex_after_kb=$(to_kb "$TEXROOT")
fonts_after_kb=$(to_kb "$FONTSROOT")
total_after_kb=$((tex_after_kb + fonts_after_kb))

tex_saved_kb=$((tex_before_kb - tex_after_kb))
fonts_saved_kb=$((fonts_before_kb - fonts_after_kb))
total_saved_kb=$((total_before_kb - total_after_kb))

echo
echo "=== Slimming report (after) ==="
echo "TeX Live:  $(fmt_h "$tex_after_kb")   (saved $(fmt_h "$tex_saved_kb"))"
echo "Fonts:     $(fmt_h "$fonts_after_kb")   (saved $(fmt_h "$fonts_saved_kb"))"
echo "TOTAL:     $(fmt_h "$total_after_kb")   (saved $(fmt_h "$total_saved_kb"))"

# --- Optional breakdown of largest remaining TeX dirs --------------------------
if [ "${SHOW_TOP:-0}" = "1" ] && [ -d "$TEXROOT/texmf-dist/tex" ]; then
  echo
  echo "--- Top remaining TeX directories (by size) ---"
  # Show top 20 heaviest dirs under texmf-dist/tex (2 levels deep)
  du -k -d 2 "$TEXROOT/texmf-dist/tex" 2>/dev/null |
    sort -n | tail -n 20 |
    awk '{kb=$1; path=$2; mb=kb/1024.0; printf "%7.1f MB  %s\n", mb, path}'
fi

echo
echo "Slimming complete."
# --- EOF -----------------------------------------------------------------------
