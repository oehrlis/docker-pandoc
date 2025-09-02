# OraDBA TeX & Pandoc Build Scripts

This folder contains helper scripts to build and slim down a minimal **LaTeX**
and **Pandoc** toolchain inside Debian-based container images.  
All scripts follow the OraDBA style: single-layer installation, safe defaults,
aggressive cleanup, and clear separation of runtime vs. build dependencies.

## Scripts Overview

### `install_pandoc.sh`

Install a specific (or latest) [Pandoc](https://pandoc.org) binary from GitHub.

- **Usage**
  
  ```sh
  install_pandoc.sh <amd64|arm64> [version]
  ```

- **Examples**

  ```sh
  install_pandoc.sh amd64
  install_pandoc.sh arm64 3.2.1
  PANDOC_VERSION=3.2.1 install_pandoc.sh amd64
  ```

- Installs into `/usr/local/bin`, strips ELF symbols, and creates symlinks:
  `pandoc-lua`, `pandoc-server`.

### `install_texlive.sh`

Install a **minimal TeX Live** tree into `/usr/local/texlive` with curated
packages needed for OraDBA templates (basic, LaTeX, XeTeX).

- Uses a **profile file** (yearless layout).
- Fetches installer from stable mirrors with retries.
- Installs only required collections and packages.
- Removes docs/sources and `tlmgr` after install.
- Strips ELF binaries to keep image size small.

### `install_fonts_runtime.sh`

Install **runtime dependencies and fonts** in one layer.

- Enables `contrib non-free non-free-firmware` repos automatically.
- Installs:

  - MS Core Fonts (EULA preseeded)
  - Open Sans
  - Montserrat (APT if available, else Google Fonts fallback)
- Includes:

  - `ca-certificates`, `fontconfig`, `curl`
  - `python3`, `python3-venv`, `python3-pip`
- Cleans apt caches and temp files.

### `slim_tex_tree.sh`

Aggressively prune TeX Live and optionally system fonts.

- Removes:

  - Rarely-used LaTeX packages (long curated list).
  - Legacy CJK font trees (wadalab, uhc, arphic).
  - Optional MS fonts (Verdana, Trebuchet, Georgia, Andale, Comic).

- Rebuilds font caches and TeX filename DB.

- Reports before/after sizes and saved space.

- **Environment**

  - `PRUNE_MS_FONTS=1` → remove selected MS fonts.
  - `SHOW_TOP=1` → show top remaining TeX dirs by size.

## Typical Workflow

1. Install fonts and runtime deps:

   ```sh
   ./install_fonts_runtime.sh
   ```

2. Install Pandoc:

   ```sh
   ./install_pandoc.sh amd64 latest
   ```

3. Install TeX Live:

   ```sh
   ./install_texlive.sh
   ```

4. Slim the TeX tree (optional):

   ```sh
   PRUNE_MS_FONTS=1 SHOW_TOP=1 ./slim_tex_tree.sh
   ```

## Resulting Layout

- `/usr/local/bin/pandoc` (+ symlinks)
- `/usr/local/texlive` (yearless TeX Live tree)
- Fonts available under `/usr/share/fonts` and `/usr/local/share/fonts`

## License

All scripts are provided under the
**Apache License, Version 2.0** (see [http://www.apache.org/licenses/](http://www.apache.org/licenses/)).
