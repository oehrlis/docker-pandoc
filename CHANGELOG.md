# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-01-19

### Added

- Add `lineno` package to TeX Live minimal installation

### Changed

### Fixed

- Fix multi-platform Docker build issues with `--load` flag by automatically detecting and using single platform for local builds
- Fix `build-multi` target to use `--push` instead of `--load` since Docker buildx doesn't support loading manifest lists
- Fix mermaid-filter version from non-existent 1.4.8 to available 1.4.7
- Remove deprecated `--listings` flag causing LaTeX errors, replaced with modern Pandoc syntax highlighting
- Update metadata.yml to comment out deprecated listings configuration that caused "No counter 'none' defined" LaTeX error

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
