# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] -

### Added

### Changed

### Fixed

### Removed

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
