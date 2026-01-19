#!/bin/sh
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: install_filters_runtime.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.09.02
# Revision...: --
# Purpose....: Install Pandoc filters into a dedicated venv (PEP 668 safe),
#              symlink entry points, and prune unused packages for a small runtime.
#              Env:
#                FILTER_VENV_DIR=/opt/pandoc-filters
#                FILTERS="pandoc-latex-color pandoc-include pandoc-latex-environment"
#                PIP_CONSTRAINTS=/usr/local/src/constraints.txt   # optional
# Notes......: Keeps only: panflute, click, PyYAML(+_yaml), and your filters.
#              Removes: pip/setuptools/wheel, requests stack, rich, etc.
# License....: Apache License Version 2.0
# ------------------------------------------------------------------------------
set -eu

: "${FILTER_VENV_DIR:=/opt/pandoc-filters}"
: "${FILTERS:=pandoc-latex-color pandoc-include pandoc-latex-environment}"
: "${PIP_CONSTRAINTS:=}"

# Create venv
python3 -m venv "${FILTER_VENV_DIR}"

# Upgrade tooling just for install step (we will remove them later)
"${FILTER_VENV_DIR}/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel

# Build pip args
PIP_ARGS="--no-cache-dir --no-compile"
if [ -n "${PIP_CONSTRAINTS}" ] && [ -f "${PIP_CONSTRAINTS}" ]; then
  PIP_ARGS="$PIP_ARGS -c ${PIP_CONSTRAINTS}"
fi

# Install minimal explicit deps first so we can use --no-deps for filters
# - pin versions you trust; PyYAML via wheels for C extension (_yaml)
"${FILTER_VENV_DIR}/bin/pip" install $PIP_ARGS \
  --only-binary=:all: \
  "PyYAML==6.0.2"

"${FILTER_VENV_DIR}/bin/pip" install $PIP_ARGS \
  "panflute==2.3.1" \
  "click==8.2.1" \
  "typing_extensions>=4.0,<5"

# Install the filters themselves without dragging more deps
# shellcheck disable=SC2086
"${FILTER_VENV_DIR}/bin/pip" install $PIP_ARGS --no-deps ${FILTERS}

# Symlink only pandoc-* console scripts to PATH
for bin in "${FILTER_VENV_DIR}"/bin/pandoc-*; do
  [ -x "$bin" ] || continue
  ln -sf "$bin" "/usr/local/bin/$(basename "$bin")"
done

SITEPKG="$(python3 -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])' 2>/dev/null || true)"
# Fallback if running under different python while sourcing path:
[ -z "${SITEPKG}" ] && SITEPKG="${FILTER_VENV_DIR}/lib/$(basename "$(dirname "$(command -v python3)")")/site-packages"
# If still empty, assume Debian layout:
[ -z "${SITEPKG}" ] && SITEPKG="${FILTER_VENV_DIR}/lib/python3.11/site-packages"

# Prune heavy/unneeded packages if they slipped in
rm -rf \
  "${SITEPKG}/pip"* \
  "${SITEPKG}/setuptools"* \
  "${SITEPKG}/wheel"* \
  "${SITEPKG}/pkg_resources"* \
  "${SITEPKG}/_distutils_hack"* \
  "${SITEPKG}/requests"* \
  "${SITEPKG}/urllib3"* \
  "${SITEPKG}/idna"* \
  "${SITEPKG}/certifi"* \
  "${SITEPKG}/truststore"* \
  "${SITEPKG}/rich"* \
  "${SITEPKG}/platformdirs"* \
  "${SITEPKG}/importlib_metadata"* \
  "${SITEPKG}/more_itertools"* \
  "${SITEPKG}/jaraco"* \
  "${SITEPKG}/packaging"* \
  "${SITEPKG}/tomli"* \
  "${SITEPKG}/tomli_w"* \
  "${SITEPKG}/typeguard"* \
  "${SITEPKG}/lxml"* \
  "${SITEPKG}/isoschematron"* \
  "${SITEPKG}/natsort"* 2>/dev/null || true

# Remove activation helpers and leftover CLIs we don't need
find "${FILTER_VENV_DIR}/bin" -maxdepth 1 -type f \( \
  -name 'Activate.ps1' -o -name 'activate' -o -name 'activate.csh' -o -name 'activate.fish' \
  -o -name 'pip' -o -name 'pip*' -o -name 'wheel' -o -name 'natsort' \
  \) -exec rm -f {} + || true

# Clean caches and bytecode/tests
"${FILTER_VENV_DIR}/bin/python" - <<'PY'
import os, sys
root = sys.prefix
for d in ('/root/.cache/pip','/tmp','/var/tmp'):
    try:
        os.system(f'rm -rf {d}/* >/dev/null 2>&1')
    except Exception:
        pass
PY

find "${FILTER_VENV_DIR}" -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
find "${FILTER_VENV_DIR}" -type f -name '*.pyc' -delete 2>/dev/null || true
find "${FILTER_VENV_DIR}" -type d \( -name 'tests' -o -name 'test' \) -prune -exec rm -rf {} + 2>/dev/null || true

# Final echo with a tiny footprint summary
du -sh "${FILTER_VENV_DIR}" 2>/dev/null || true
echo "Pandoc filters installed and pruned at ${FILTER_VENV_DIR}"
# --- EOF ----------------------------------------------------------------------
