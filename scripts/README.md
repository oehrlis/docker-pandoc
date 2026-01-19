# OraDBA Docker Pandoc Build & Helper Scripts

This folder contains scripts to build, release, test, and slim down a minimal
**LaTeX** and **Pandoc** toolchain inside Debian-based container images.  
All scripts follow the OraDBA style: single-layer installation, safe defaults,
aggressive cleanup, and clear separation of runtime vs. build dependencies.

## Build & Release Scripts

### `build.sh`

Build multi-arch Docker image for Pandoc with TinyTeX and MS fonts.

- **Usage**

  ```sh
  build.sh [RELEASE] [options]
  ```

- **Options**
  - `--no-cache` - Build without cache
  - `--local|--load` - Local-only build (use --load, do not push)
  - `--push` - Force push to registry (default behavior)
  - `--platform=LIST` - Target platforms (default: linux/amd64,linux/arm64)

- **Examples**

  ```sh
  build.sh                      # Build beta tag, push to registry
  build.sh 1.2.3 --push         # Build version 1.2.3 and push
  build.sh beta --local         # Build beta locally only
  build.sh 1.2.3 --no-cache     # Build without cache
  ```

### `release.sh`

Release Docker image with version bumping and git tagging.

- **Usage**

  ```sh
  release.sh [RELEASE_TYPE] [BUILD_OPTIONS]
  ```

- **Release Types**
  - `patch` - Bump patch version (default)
  - `minor` - Bump minor version
  - `major` - Bump major version

- **Examples**

  ```sh
  release.sh                      # Bump patch version and release
  release.sh minor                # Bump minor version and release
  release.sh major --no-cache     # Bump major version, build without cache
  ```

- **Notes**
  - Requires treeder/bump Docker image for version bumping
  - Pulls latest changes from git before bumping
  - Creates git commit and tag with new version
  - Pushes commits and tags to trigger CI/CD release workflow

### `test.sh`

Generate sample documents to test Docker image functionality.

- **Usage**

  ```sh
  test.sh [RELEASE]
  ```

- **Tests**
  - PDF generation with XeLaTeX
  - DOCX generation
  - PPTX generation
  - Mermaid diagram filter

- **Examples**

  ```sh
  test.sh           # Test beta tag
  test.sh 1.2.3     # Test version 1.2.3
  ```

## Installation Scripts

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

### `install_pandoc_filters.sh`

Install Pandoc filters.

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

### Development Workflow

1. Build locally for testing:

   ```sh
   ./build.sh beta --local
   ```

2. Test the image:

   ```sh
   ./test.sh beta
   ```

3. Build and push to registry:

   ```sh
   ./build.sh beta --push
   ```

### Release Workflow

1. Release a new version:

   ```sh
   ./release.sh patch    # For patch version bump
   ./release.sh minor    # For minor version bump
   ./release.sh major    # For major version bump
   ```

### Container Build Workflow

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
