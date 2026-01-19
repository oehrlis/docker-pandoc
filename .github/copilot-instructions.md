# GitHub Copilot Instructions - docker-pandoc

## Project Overview

This repository contains a Docker image for Pandoc with full PDF conversion support, custom LaTeX templates, and Mermaid diagram rendering. The image is built for multi-architecture support (linux/amd64, linux/arm64) and includes:

- **Pandoc**: Latest version from GitHub releases
- **TeX Live**: Minimal installation optimized for document conversion
- **Templates**: Custom LaTeX templates (OraDBA, TechDoc, Trivadis) embedded in the image
- **Fonts**: MS Core Fonts, Open Sans, Montserrat
- **Mermaid**: Diagram rendering via mermaid-cli and Chromium

## Architecture

### Multi-Stage Build
- **Builder stage**: Installs Pandoc, TeX Live, and builds artifacts
- **Final stage**: Runtime image with minimal dependencies
- **Non-root execution**: Container runs as `pandoc` user (uid/gid 1000)

### Key Directories
```
/workdir/                 # User workspace (volume mount point)
/oradba/                  # Templates, themes, images
/opt/pandoc-data/         # Pandoc data directory
/usr/local/texlive/       # TeX Live installation
```

### Template Integration
Templates are now embedded in the Docker image (no GitHub download at runtime):
- All templates copied from `templates/` directory
- Themes from `themes/` directory
- Images from `images/` directory
- Symlinked to Pandoc data directories during build

## Coding Standards

### Shell Scripts
- **Shebang**: Use `#!/usr/bin/env bash` for portability
- **Error handling**: Always use `set -euo pipefail` and `IFS=$'\n\t'`
- **Functions**: Document with purpose, args, and return values
- **Quoting**: Always quote variables: `"${VAR}"` not `$VAR`
- **Exit codes**: Use meaningful exit codes and error messages
- **Linting**: Code must pass `shellcheck` and `shfmt -i 2 -ci`

### Dockerfile
- **Base image**: `debian:bookworm-slim`
- **Layer optimization**: Combine related commands, clean up in same layer
- **Security**: Run as non-root user (`USER pandoc`)
- **Multi-arch**: Support both amd64 and arm64
- **Build args**: Use for configurable options (SLIM_TEX, PRUNE_MS_FONTS)
- **Comments**: Clearly separate and document each stage/section

### LaTeX Templates
- **Counter compatibility**: Always define `\newcounter{none}` for Pandoc longtable support
- **Package loading order**: Load packages in correct order to avoid conflicts
- **Conditional blocks**: Use Pandoc template variables properly (e.g., `$if(beamer)$...$endif$`)

## Build System

### Scripts in `scripts/` Directory
- **build.sh**: Build Docker image with buildx for multi-platform
- **release.sh**: Version bumping and automated release
- **test.sh**: Generate sample documents to validate functionality
- **install_*.sh**: Modular installation scripts for Pandoc, TeX Live, filters, fonts

### Makefile Targets
```bash
make build         # Build locally (single platform)
make build-multi   # Build multi-platform and push
make test          # Run all tests
make lint          # Run all linting checks
make release       # Release with version bump
```

### Version Management
- Version stored in `VERSION` file
- Release script uses `treeder/bump` Docker image
- Git tags created automatically on release

## Docker Best Practices for This Project

### Running Containers
```bash
# Always mount workdir as volume
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc [OPTIONS]

# Non-root user (uid 1000) - ensure host permissions match
chown -R 1000:1000 /path/to/documents
```

### Chromium/Puppeteer Configuration
- Container runs as non-root, but Chromium requires `--no-sandbox` in containers
- Puppeteer config: `/workdir/.config/puppeteer/config.json`
- Never remove sandbox flags - required for container execution

### Network Issues During Build
- APT operations have retry logic (5 attempts, 120s timeout)
- If build fails with network errors, retry the build
- Multi-platform builds require stable network connection

## Common Tasks

### Adding New LaTeX Package
1. Edit `scripts/install_texlive.sh`
2. Add package name to `PKGS` variable
3. Rebuild without cache: `make build --no-cache`

### Updating Templates
1. Edit files in `templates/` directory (e.g., `oradba.tex`)
2. Templates are copied during Docker build
3. Test changes: `make build && make test`

### Adding New Pandoc Filter
1. Edit `scripts/install_pandoc_filters.sh`
2. Add filter to `FILTERS` variable
3. Ensure filter is compatible with venv installation (PEP 668)

### Fixing LaTeX Errors
- Check for missing counters (common: `none` counter for tables)
- Verify package load order (caption, longtable, etc.)
- Test with sample documents in `sample/` directory

## Important Files

### Configuration Files
- `Dockerfile` - Multi-stage Docker build definition
- `Makefile` - Build automation and common tasks
- `VERSION` - Current version number
- `.shellcheckrc` - Shellcheck linting configuration
- `.hadolint.yaml` - Dockerfile linting configuration

### Documentation
- `README.md` - User-facing documentation
- `AUTHOR_GUIDE.md` - Template authoring guide
- `CHANGELOG.md` - Version history and changes
- `scripts/README.md` - Script documentation

### Templates and Themes
- `templates/oradba.tex` - Main LaTeX template (most commonly used)
- `templates/*.tex` - Alternative templates (techdoc, trivadis)
- `templates/*.docx` - DOCX reference templates
- `themes/oradba.theme` - Presentation themes

### CI/CD
- `.github/workflows/ci.yml` - Continuous integration
- `.github/workflows/release.yml` - Automated releases

## Testing Strategy

### Sample Generation
The `test.sh` script validates the image by generating:
1. PDF from Markdown (with XeLaTeX)
2. DOCX from Markdown
3. PPTX from Markdown
4. Mermaid diagram rendering in PDF

### Test Files
- `sample/sample.md` - Main test document
- `sample/metadata.yml` - Pandoc metadata configuration
- `examples/test-mermaid.md` - Mermaid diagram test

### Expected Warnings
- LaTeX warnings about `\underbar` and `\underline` changes are expected (ulem package)
- These warnings are non-fatal and can be ignored

## Security Considerations

### Non-Root Execution
- Container runs as `pandoc` user (uid 1000, gid 1000)
- Never add `USER root` after user creation
- Ensure all necessary files are owned by `pandoc` user before USER switch

### Chromium Sandbox
- Sandbox must be disabled in containers (`--no-sandbox` flag)
- This is a known limitation of running Chromium in containers
- Still more secure than running entire container as root

## Troubleshooting

### Build Failures
- **Network timeouts**: Retry build, APT has retry logic
- **Cache issues**: Build with `--no-cache` flag
- **Multi-platform**: Ensure buildx builder exists: `docker buildx create --use`

### Runtime Issues
- **Permission denied**: Check file ownership matches uid 1000
- **Chromium crashes**: Verify Puppeteer config exists in `/workdir/.config/`
- **Missing fonts**: Font installation is part of `install_fonts_runtime.sh`

### Template Errors
- **Counter not defined**: Add `\newcounter{name}` in template
- **Package conflicts**: Check package load order
- **Missing template**: Templates copied from local `templates/` dir during build

## Contributing

When making changes:
1. Update CHANGELOG.md with your changes
2. Ensure all tests pass: `make test`
3. Run linting: `make lint`
4. Test multi-platform build if modifying build logic
5. Update documentation if adding features
6. Commit with descriptive messages following conventional commits style
