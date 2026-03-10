# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.2.0] - 2026-03-10

### Added

- Add `latest-full` convenience tag for the `full` variant (analogous to `latest` → standard);
  updated `Makefile` (`build-release`, `build-multi`), `.github/workflows/release.yml`,
  and `IMAGE_VARIANTS.md` documentation

### Fixed

- Fix `mmdc: not found` error in `mermaid.lua`: `sh` invoked by `os.execute()`
  does not include `/usr/local/bin` in PATH; changed default `MMDC_BIN` to
  `/usr/local/bin/mmdc` and added `MERMAID_CLI_BIN=/usr/local/bin/mmdc` to
  Dockerfile `ENV` for explicitness and overridability

### Changed

- Set `SLIM_TEX` default to `1` in Dockerfile — TeX tree slimming now on by default,
  reducing standard/full image sizes by ~100-150 MB
- `mermaid.lua`: surface `mmdc` error details on render failure — first meaningful stderr
  line shown; improved fallback warning includes diagram type and `<br>` tip
- `scripts/install_mermaid.sh`: reduce mermaid/full image size by ~60-80 MB:
  - Remove unused Vulkan/GPU shared libraries from Chromium (`libvk_swiftshader.so`,
    `libVkLayer_khronos_validation.so`, `libVkICD_mock_icd.so`, `libvulkan.so.1`,
    `chrome_crashpad_handler`)
  - Remove `npm` post-install (runtime not needed); guard with `apt-mark manual nodejs`
  - Remove `fonts-noto-color-emoji` (not used in Mermaid diagrams, ~10 MB)
  - Remove `chromium-sandbox` from deps (unused — `--no-sandbox` via puppeteer config)
  - Add `--omit=optional` to `npm install` for mermaid-cli
  - Remove mermaid-cli TypeScript sources (`src/`, `dist-types/`) and extended
    node_modules cleanup (`*.map`, `*.ts`, `CHANGELOG*`, `LICENSE*`, `test/`,
    `__tests__/`, `docs/`)
- `scripts/slim_tex_tree.sh`: add METAFONT source removal (~6 MB) and AFM cleanup
  keeping only core fonts (~15-18 MB savings)

## [4.1.0] - 2026-03-09

### Added

- Implement `IMAGE_VARIANT` build argument in Dockerfile supporting four variants: `minimal`, `standard`, `mermaid`, `full`
- Add `mermaid.lua` Lua filter for Mermaid diagram rendering via mermaid-cli (`mmdc`) and Chromium
  - Configurable image width via `MERMAID_IMAGE_WIDTH` env var (default `80%`)
  - Configurable max height via `MERMAID_IMAGE_MAX_HEIGHT` env var (default `75%`) with `keepaspectratio` for tall diagrams
  - Optional caption support via `caption` code block attribute (`\`\`\`{.mermaid caption="..."}`)
  - Raw LaTeX figure environment for PDF; standard pandoc Image for HTML/DOCX
- Add `scripts/install_mermaid.sh` for reproducible Mermaid/Chromium/Node.js installation
- Add `IMAGE_VARIANTS.md` documenting all variants, feature matrix, and usage examples
- Add `sample/sample-mermaid.md` as dedicated Mermaid test/demo document (with captions)
- Add `sample/metadata-advanced.yml` with full template metadata reference
- Add `sample/sample-config.md` configuration reference document
- Rewrite `Makefile` with project-template-style version management targets (`version-bump-patch/minor/major`, `tag`, `release`), Docker variant build targets (`build`, `build-all`, `build-release`, `build-multi`), and test/lint targets

### Changed

- Restructure Dockerfile into two-stage build with conditional TeX Live (standard/full), conditional Mermaid/Chromium (mermaid/full), conditional fonts and templates
- Replace inline Node.js/Chromium RUN block with `scripts/install_mermaid.sh` call
- Update `scripts/install_mermaid.sh` Chromium dependency list for Debian bookworm (remove unavailable `libxss1`, add `libxkbcommon0`)
- Set `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD`, `PUPPETEER_EXECUTABLE_PATH`, `CHROME_BIN` as global ENV vars (harmless for non-mermaid variants)
- Consolidate `examples/` into `sample/` — single directory for all sample and test documents
- Update `scripts/test.sh` to reference `sample/` paths and `sample-mermaid.md`
- Rewrite `.github/workflows/test-mermaid.yml` to test the current Lua-filter implementation (no legacy approaches)
- Update `.github/workflows/release.yml` to build and push all four variants with `VERSION-VARIANT` tags; `latest` and `VERSION` tags point to `standard`
- Update `.github/workflows/ci.yml` markdown lint to reference `sample/` paths

### Fixed

- Fix `mermaid.lua` Chromium `--no-sandbox` error: switch from `.puppeteerrc.cjs` (CJS, ignored) to JSON config file passed explicitly via `--puppeteerConfigFile`
- Fix tall mermaid diagrams (e.g. sequence diagrams) overflowing page: add `keepaspectratio` with `height` constraint via raw LaTeX `\includegraphics`
- Fix `\noteblock already defined` LaTeX error: remove duplicate `\newenvironment` definitions from `oradba.tex` (awesomebox provides them natively)
- Fix `sourcesanspro.sty not found` LaTeX error: add `\IfFileExists` fallback to `lmodern` in template; add explicit retry loop in `install_texlive.sh`
- Fix `\l__fontspec_family_fontopts_clist` XeLaTeX error: remove obsolete sourcecodepro internal-macro adjustment block from template
- Remove `--cap-add=SYS_ADMIN` from test command: `--no-sandbox` flags via puppeteer JSON config make elevated capabilities unnecessary

### Removed

- Remove `scripts/build.sh` and `scripts/release.sh` (superseded by Makefile targets)
- Remove `.puppeteerrc.cjs` root-level file (puppeteer config now handled inline in `mermaid.lua`)
- Remove `.github/ISSUE_MERMAID_SUPPORT.md` (planning doc, feature now implemented)
- Remove `.github/copilot-instructions.md` (Copilot-specific, not used)
- Remove `examples/` directory (consolidated into `sample/`)
- Remove `Dockerfile.fix` (experimental scratch file, superseded by variant Dockerfile)
- Remove orphan status/planning documents: `PHASE1_RESULTS.md`, `PHASE2_COMPLETE.md`, `PHASE2_IMPLEMENTATION.md`, `OPTIMIZATION_PLAN.md`, `TEST_RESULTS.md`
- Remove superseded Mermaid debug docs: `MERMAID_CHROMIUM_FIX.md`, `MERMAID_CI_ALTERNATIVES.md`, `MERMAID_QUICK_TEST.md`, `MERMAID_STATUS.md`, `MERMAID_TEST_GUIDE.md`
- Remove `mermaid-filter.err` error log artifact
- Remove `mermaid-filter` npm package installation (replaced by `mermaid.lua` Lua filter)

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
