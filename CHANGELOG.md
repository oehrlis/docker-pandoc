# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-01-20

### Added

- **Comprehensive AUTHOR_GUIDE.md enhancements**:
  - Advanced template options documentation (title pages, colors, headers/footers, logos)
  - Complete YAML metadata configuration examples with all supported variables
  - Box types and custom environments section (note, tip, warning, caution, important boxes)
  - Comprehensive troubleshooting guide (resource paths, mounting, fonts, templates, permissions)
  - Markdownlint configuration examples (inline and global)
  - Pandoc filters usage documentation
  - Output formats section covering PDF, DOCX, PPTX, HTML, EPUB, and LaTeX
  - References section with complete citations to oehrlis/pandoc_template sources
- `examples/metadata-advanced.yml` - Complete metadata configuration example with all available options and inline documentation
- `examples/formatting-examples.md` - Comprehensive formatting reference demonstrating all Markdown syntax, extended features, and box types
- Enhanced README.md with:
  - Advanced template features overview
  - Better cross-references to AUTHOR_GUIDE.md
  - Organized Documentation section for different audiences
  - Updated References section with pandoc_template repository links

### Changed

- Restructured AUTHOR_GUIDE.md with improved organization:
  - Added Table of Contents for easy navigation
  - Moved from basic "release guide" to comprehensive "authoring and user guide"
  - Incorporated best practices from oehrlis/pandoc_template repository
  - Enhanced with practical examples and code snippets
- Updated README.md template section with advanced usage example
- Enhanced documentation structure with clear separation for users, contributors, and developers

### Documentation Sources

All documentation enhancements incorporate content from the following sources in the [oehrlis/pandoc_template](https://github.com/oehrlis/pandoc_template) repository:

- [README.md](https://github.com/oehrlis/pandoc_template/blob/master/README.md) - Template usage and configuration
- [AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md) - Document structure and authoring
- [examples/complex/README.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/README.md) - Complex document examples
- [examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md) - Comprehensive formatting examples
- [examples/complex/metadata.yml](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/metadata.yml) - Complete metadata example
- [templates/oradba.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/oradba.tex) - OraDBA template source
- [templates/techdoc.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/techdoc.tex) - Technical documentation template
- [templates/trivadis.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/trivadis.tex) - Trivadis corporate template

## [Unreleased] - 2026-01-19

### Added

- Add `lineno` package to TeX Live minimal installation
- Add `\newcounter{none}` to LaTeX template for Pandoc table compatibility with caption package
- Add custom environment definitions (noteblock, tipblock, warningblock, cautionblock, importantblock) mapped to awesomebox for pandoc-latex-environment filter
- Add `DEVELOPMENT.md` - comprehensive local development guide covering architecture, build system, testing, troubleshooting, and coding standards
- Add `.github/copilot-instructions.md` - detailed project documentation for GitHub Copilot context
- Add GitHub API fallback mechanism in `install_pandoc.sh` to bypass rate limiting by using direct download URLs
- Add `.cache/` and `.config/` to `.gitignore` for runtime artifacts
- Add `.github/ISSUE_MERMAID_SUPPORT.md` - tracking issue for future Mermaid/Kroki implementation

### Changed

- Add retry logic and timeouts to APT operations in Dockerfile for improved network reliability
- Add automatic fallback to alternative Debian mirror (ftp.us.debian.org) if primary repository fails
- Add BUILDKIT_INLINE_CACHE build argument for better multi-platform build performance
- Restructured `.github/SETUP.md` to focus on CI/CD configuration, referencing `DEVELOPMENT.md` for local workflows
- Updated `install_pandoc.sh` to use direct GitHub release URLs first, falling back to API only if needed (avoids rate limiting)
- Migrated `build.sh`, `release.sh`, and `test.sh` scripts from root to `scripts/` directory
- Updated `Makefile` to reference scripts in new `scripts/` directory location
- Changed Git remote from SSH to HTTPS for firewall compatibility

### Removed

- **Mermaid support temporarily removed**: Removed `mermaid-cli`, `mermaid-filter`, Node.js, npm, Chromium, and related dependencies due to Docker sandbox incompatibility with non-root users
- Removed Chromium and browser dependencies (saves ~300MB in image size)
- Disabled Mermaid test in `scripts/test.sh`

### Fixed

- Fix multi-platform Docker build issues with `--load` flag by automatically detecting and using single platform for local builds
- Fix `build-multi` target to use `--push` instead of `--load` since Docker buildx doesn't support loading manifest lists
- Fix mermaid-filter version from non-existent 1.4.8 to available 1.4.7
- Remove deprecated `--listings` flag causing LaTeX errors, replaced with modern Pandoc syntax highlighting
- Update metadata.yml to comment out deprecated listings configuration that caused "No counter 'none' defined" LaTeX error
- Fix Pandoc installation failures due to GitHub API rate limiting (403 errors) by implementing direct download URL fallback

### Deprecated

- Mermaid diagram rendering via `mermaid-cli` - will be replaced with Kroki integration in future release

### Documentation

- Added comprehensive `DEVELOPMENT.md` covering local development workflows, architecture, testing, and troubleshooting
- Updated `README.md` to remove Mermaid feature listing and add Diagram Support section with alternatives (PlantUML, Graphviz, TikZ)
- Updated `.github/SETUP.md` to clarify separation between CI/CD setup and local development
- Added `.github/copilot-instructions.md` for AI-assisted development context
- Created `.github/ISSUE_MERMAID_SUPPORT.md` tracking future Mermaid/Kroki implementation

### Security

- Improved security posture by removing Chromium and Node.js dependencies (reduced attack surface)
- Maintains non-root container execution without security compromises
- Fix network connectivity issues during Docker build with retry mechanism and mirror fallback
- Fix "No counter 'none' defined" LaTeX error for tables without captions by defining missing counter in template
- Fix pandoc-latex-environment filter compatibility by adding awesomebox environment mappings

### Removed

## [4.0.0] -

### Added

- Introduce script folder for different installation scripts see [README](./scripts/REAMDE.md)
- Add script *install_fonts_runtime.sh* Install minimal runtime deps (Python/venv, curl, fontconfig) and fonts (MS core, Open Sans, Montserrat) in a single layer.
- Add script *install_filters_runtime.sh* Install Pandoc filters into a dedicated venv (PEP 668 safe), symlink entry points, and prune unused packages for a small runtime.
- Add script *install_pandoc.sh* Install a specific (or latest) pandoc binary (amd64/arm64) from GitHub Releases and strip ELF symbols to reduce size.
- Add script *install_texlive.sh* Install a minimal, yearless TeX Live into /usr/local/texlive with just the packages needed for our Pandoc/XeLaTeX templates.
- Add script *slim_tex_tree.sh* Aggressively slim a TeX Live tree and (optionally) selected system fonts to reduce image size.

### Changed

- rework *Dockerfile* to use new install scripts rather than everthing in RUN commands
- change base image to *debian:bookworm-slim* rather than *ubuntu*
  
### Fixed

- add *ulem* to the initial version of *install_texlive.sh*

### Removed

- remove *texlive.amd64.profile* local profile is not required anymore. Adhoc profile will be generated in *install_texlive.sh*
- remove *texlive.arm64.profile* local profile is not required anymore. Adhoc profile will be generated in *install_texlive.sh*

## [3.2.2] - 2021-09-01

### Fixed

- add missing TeX module *ragged2e*
- add missing TeX module *sotabularxurcesanspro*

## [3.2.1] - 2024-03-08

### Fixed

- add missing TeX module *fancyvrb*
- add missing TeX module *sourcesanspro*
- add missing TeX module *lineno*
- add missing Tex moduel *sourcecodepro*
- update to latest version of *oehrlis/pandoc_templates*

## [3.2.0] - 2024-02-14

### Fixed

- update pip, setuptools and wheel to the latest release

## [3.1.0] - 2023-08-18

### Add

- Add a cache flag to the Build script *build.sh*

## [3.0.1] - 2023-08-17

### Fixed

- add missing *awsomebox* package

## [3.0.0] - 2023-08-17

### Changed

- Remove reference to *Trivadis*
- Change to new Template based on *OraDBA*

## [2.1.1] - 2022.09.28

### Fixed

- Fix version number in *CHANGELOG.md*

## [2.1.0] - 2022.09.28

### Changed

- Split basic container setup and *TexLive* installation in two *RUN* blocks
- Remove *no-cache* from build

### Fixed

- Add missing *TexLive* package *koma-script*
- Add missing *TexLive* package *setspace*
- Add missing *TexLive* package *xcolor*
- Add missing *TexLive* package *xkeyval*
- Add missing *TexLive* package *listings*
- Add missing *TexLive* package *booktabs*
- Add missing *TexLive* package *pgf*
- Add missing *TexLive* package *caption*

### Removed

- Remove *zip* from OS package installation
- Remove *divpng* from OS package installation
- Remove *make* from OS package installation
- Remove asian languages and fonts
- Remove *TexLive* package *sourcecodepro*
- Remove *TexLive* package *sourcesanspro*

## [2.0.0] - 2022-09-27

### Changed

- Introduce multi platform build using *buildx* for *arm64* and *amd64*.
- Change base image to ubuntu in Dockerfile
- Create platform specific *texlive.profile* files.

### Fixed

- Fix font name in metadata.xml

### Removed

- Remove unused files e.g. texlive.profile, font folder, etc.

## [1.4.0] - 2021-11-10

### Changed

- update to latest [oehrlis/pandoc_template](https://github.com/oehrlis/pandoc_template)

### Fixed

- fix download url for getnonfreefonts install script

## [1.3.1] - 2021-10-13

### Changed

- Update PPTX reference doc to latest OraDBA CI layout / templates

## [1.3.0] - 2021-08-29

### Changed

- update to latest pandoc 2.14.2
- Update OraDBA CI layout / templates
- update LateX installation

### Fixed

- add workaround to fix LaTeX issue with Open+Sans. Somehow Open Sans contains
  fonts with commas. It seams that xelatex can not handle this.

## [1.2.2] - 2021-06-12

### Added

- add [CHANGELOG.md](CHANGELOG.md) file

[unreleased]: https://github.com/oehrlis/docker-pandoc
[1.2.2]: https://github.com/oehrlis/docker-pandoc/releases/tag/v1.2.2
[1.3.0]: https://github.com/oehrlis/docker-pandoc/releases/tag/v1.3.0
[1.3.1]: https://github.com/oehrlis/docker-pandoc/releases/tag/v1.3.1
[1.4.0]: https://github.com/oehrlis/docker-pandoc/releases/tag/v1.4.0
[2.0.0]: https://github.com/oehrlis/docker-pandoc/releases/tag/v2.0.0
[2.1.0]: https://github.com/oehrlis/docker-pandoc/releases/tag/v2.1.0
[2.1.1]: https://github.com/oehrlis/docker-pandoc/releases/tag/v2.1.1
