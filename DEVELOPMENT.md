# Development Guide

This guide covers local development workflows, building, testing, and releasing the docker-pandoc project.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Architecture](#project-architecture)
- [Build System](#build-system)
- [Testing](#testing)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)
- [Coding Standards](#coding-standards)

## Prerequisites

### Required Tools

- **Docker**: Version 20.10+ with buildx support
- **Git**: For version control
- **Make**: Build automation
- **Bash**: For running scripts (macOS/Linux native, Windows via WSL2)

### Optional Linting Tools

For local linting (CI will run these automatically):

```bash
# Shell linting
brew install shellcheck shfmt        # macOS
apt-get install shellcheck shfmt     # Debian/Ubuntu

# Markdown linting
npm install -g markdownlint-cli

# Dockerfile linting
brew install hadolint                # macOS
# or use Docker: docker run --rm -i hadolint/hadolint < Dockerfile
```

### Docker Buildx Setup

Enable multi-platform builds:

```bash
# Create and use a buildx builder
docker buildx create --name pandoc-builder --use
docker buildx inspect --bootstrap
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/oehrlis/docker-pandoc.git
cd docker-pandoc

# Build image (single platform)
make build

# Run tests
make test

# Run linters
make lint

# View all available commands
make help
```

## Project Architecture

### Multi-Stage Docker Build

The [Dockerfile](Dockerfile) uses a multi-stage build pattern:

1. **Builder stage**: Installs Pandoc, TeX Live, fonts, and filters
2. **Final stage**: Runtime image with minimal dependencies
3. **Non-root execution**: Container runs as `pandoc` user (uid/gid 1000)

### Directory Structure

```
/workdir/                 # User workspace (volume mount point)
/oradba/                  # Templates, themes, images
/opt/pandoc-data/         # Pandoc data directory
/usr/local/texlive/       # TeX Live installation
```

### Template Integration

Templates are embedded in the Docker image (not downloaded at runtime):
- All templates copied from `templates/` directory during build
- Themes from `themes/` directory
- Images from `images/` directory
- Symlinked to Pandoc data directories

### Key Components

- **Pandoc**: Latest version from GitHub releases
- **TeX Live**: Minimal installation optimized for document conversion
- **Templates**: Custom LaTeX templates (OraDBA, TechDoc, Trivadis)
- **Fonts**: MS Core Fonts, Open Sans, Montserrat
- **Mermaid**: Diagram rendering via mermaid-cli and Chromium

## Build System

### Build Scripts

All build scripts are located in the `scripts/` directory:

- **`scripts/build.sh`**: Docker image build with buildx
- **`scripts/release.sh`**: Version bumping and automated release
- **`scripts/test.sh`**: Generate sample documents for validation
- **`scripts/install_pandoc.sh`**: Pandoc installation
- **`scripts/install_texlive.sh`**: TeX Live package installation
- **`scripts/install_pandoc_filters.sh`**: Python filters installation
- **`scripts/install_fonts_runtime.sh`**: Font installation
- **`scripts/slim_tex_tree.sh`**: TeX Live cleanup for smaller image

### Makefile Targets

```bash
# Building
make build              # Build locally (current platform only)
make build-multi        # Build for linux/amd64 and linux/arm64, push to registry

# Testing
make test               # Run test.sh to generate sample documents
make test-samples       # Alias for 'make test'

# Quality Assurance
make lint               # Run all linters
make lint-shell         # Run shellcheck and shfmt
make lint-markdown      # Run markdownlint
make lint-docker        # Run hadolint

# Development
make shell              # Open interactive shell in container
make clean              # Remove generated artifacts

# Versioning
make version            # Display current version
make release            # Create new release (bump version, tag, push)

# Help
make help               # Show all available targets
```

### Building Locally

#### Single Platform (Fast)

```bash
make build
# Builds for your current architecture (amd64 or arm64)
```

#### Multi-Platform (Slow, requires push)

```bash
make build-multi
# Builds for linux/amd64 AND linux/arm64
# Pushes to Docker Hub (requires authentication)
```

#### Custom Build Options

```bash
# Build without cache (force fresh build)
docker buildx build --no-cache --platform linux/amd64 -t oehrlis/pandoc:dev .

# Build with specific version tag
docker buildx build --platform linux/amd64 -t oehrlis/pandoc:1.2.3 .

# Slim build (minimal TeX packages)
docker buildx build --build-arg SLIM_TEX=true -t oehrlis/pandoc:slim .
```

## Testing

### Automated Tests

```bash
make test
```

This runs `scripts/test.sh` which generates:
1. **PDF** from Markdown (with XeLaTeX engine)
2. **DOCX** from Markdown
3. **PPTX** from Markdown
4. **Mermaid diagrams** in PDF

Test documents use:
- `sample/sample.md` - Main test document
- `sample/metadata.yml` - Pandoc metadata configuration
- `examples/test-mermaid.md` - Mermaid diagram test

### Expected Behavior

#### Successful Output
- Sample documents generated in `sample/` directory
- PDF renders correctly with custom LaTeX template
- Mermaid diagrams embedded in PDF

#### Expected Warnings
- LaTeX warnings about `\underbar` and `\underline` changes (from ulem package)
- These warnings are **non-fatal** and can be ignored

### Manual Testing

```bash
# Test PDF generation
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  sample/sample.md -o sample/output.pdf \
  --defaults sample/metadata.yml

# Test with specific template
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  sample/sample.md -o sample/output.pdf \
  --template oradba \
  --pdf-engine xelatex

# Interactive testing
make shell
pandoc --version
pandoc sample.md -o test.pdf --template oradba
```

## Release Process

### Version Management

Version is stored in the `VERSION` file at the repository root.

### Creating a Release

#### Option 1: Using Makefile (Recommended)

```bash
# Bump patch version (1.0.0 → 1.0.1)
make release

# Bump minor version (1.0.0 → 1.1.0)
make release BUMP=minor

# Bump major version (1.0.0 → 2.0.0)
make release BUMP=major
```

This will:
1. Bump version in `VERSION` file
2. Commit the change
3. Create a git tag
4. Push to GitHub (triggers automated build/release)

#### Option 2: Manual Process

```bash
# Update VERSION file
echo "1.0.1" > VERSION

# Commit and tag
git add VERSION
git commit -m "Bump version to 1.0.1"
git tag 1.0.1

# Push to trigger release workflow
git push
git push --tags
```

### Automated Release Workflow

When a version tag is pushed:
1. GitHub Actions workflow (`.github/workflows/release.yml`) triggers
2. Multi-platform Docker image built (linux/amd64, linux/arm64)
3. Image pushed to Docker Hub as:
   - `oehrlis/pandoc:latest`
   - `oehrlis/pandoc:<version>` (e.g., `oehrlis/pandoc:1.0.1`)
4. GitHub release created with:
   - Release notes
   - Sample documents (PDF, DOCX, PPTX)
   - Build logs

## Troubleshooting

### Build Failures

#### Network Timeouts During apt-get

**Symptom**: `Failed to fetch` errors during Debian package installation

**Solution**: Retry the build. The Dockerfile includes retry logic (5 attempts, 120s timeout), but network instability can still cause failures.

```bash
# Retry the build
make build

# If persistent, try building without cache
docker buildx build --no-cache -t oehrlis/pandoc:dev .
```

#### Cache Issues

**Symptom**: Changes to templates or scripts not reflected in container

**Solution**: Build without cache

```bash
docker buildx build --no-cache -t oehrlis/pandoc:dev .
```

#### Multi-Platform Build Requires Push

**Symptom**: `ERROR: docker exporter does not currently support exporting manifest lists`

**Explanation**: Multi-platform builds cannot be loaded to local Docker, they must be pushed to a registry.

**Solution**: Either:
- Push to registry: `make build-multi`
- Or build single platform: `make build`

### Runtime Issues

#### Permission Denied on Mounted Files

**Symptom**: Container cannot write to `/workdir`

**Solution**: Container runs as uid/gid 1000. Ensure host files match:

```bash
# Check current ownership
ls -la /path/to/documents

# Fix ownership (macOS/Linux)
sudo chown -R 1000:1000 /path/to/documents

# Or run with user override (not recommended)
docker run --rm -u root -v $PWD:/workdir:z oehrlis/pandoc [OPTIONS]
```

#### Chromium/Mermaid Crashes

**Symptom**: Mermaid diagram rendering fails with sandbox namespace errors

```
Error: Failed to launch the browser process!
Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted
```

**Root Cause**: Chromium requires either root privileges or `--no-sandbox` flag, but even with the flag, Docker's security restrictions prevent namespace creation for non-root users.

**Current Status**: ⚠️ **Known Limitation** - Mermaid diagram rendering does not work in the containerized non-root environment.

**Workarounds**:

1. **Use mermaid-cli locally** (outside Docker):
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   mmdc -i diagram.mmd -o diagram.png
   pandoc document.md -o output.pdf --filter mermaid-filter
   ```

2. **Pre-render diagrams** before using the container:
   ```bash
   # Generate PNG diagrams first
   mmdc -i diagram.mmd -o diagram.png
   
   # Then use regular images in Markdown
   ![Diagram](diagram.png)
   ```

3. **Use alternative diagram tools** that don't require Chromium:
   - PlantUML (Java-based, works in containers)
   - Graphviz/dot (C-based, works in containers)
   - TikZ (LaTeX-native, works with XeLaTeX)

**Not Recommended** (Security Risk):
```bash
# Run container as root (bypasses security)
docker run --rm --user root -v $PWD:/workdir:z oehrlis/pandoc [OPTIONS]
```

**Technical Details**: The issue arises because:
- Chromium/Puppeteer requires sandbox namespace creation
- Docker's default seccomp profile blocks certain syscalls for non-root users
- Adding `--no-sandbox` flag disables security features but doesn't resolve namespace permission issues
- Running as root poses security risks and is not recommended for production use

**Future Resolution**: This limitation may be resolved by:
- Using headless rendering alternatives (e.g., Playwright with different backend)
- Running with `--security-opt` Docker flags (requires host-level configuration)
- Switching to server-side SVG rendering libraries that don't require browsers

#### Missing Fonts in PDF

**Symptom**: Font warnings in LaTeX output, incorrect fonts in PDF

**Solution**: Fonts are installed at build time. Rebuild without cache:

```bash
make build --no-cache
```

### Template Errors

#### LaTeX Error: No counter 'X' defined

**Symptom**: `! LaTeX Error: No counter 'none' defined.`

**Solution**: Add counter definition to template:

```latex
\newcounter{none}
```

This is already fixed in `templates/oradba.tex` (line 358).

#### Package Conflicts

**Symptom**: `! LaTeX Error: Option clash for package X`

**Solution**: Check package load order in template. Packages with options must be loaded before packages that load them as dependencies.

### Development Workflow Issues

#### Git Push Fails (SSH Port 22 Blocked)

**Symptom**: `Connection timed out` when pushing to GitHub

**Solution**: Use HTTPS instead of SSH:

```bash
# Change remote URL
git remote set-url origin https://github.com/oehrlis/docker-pandoc.git

# Verify
git remote -v
```

#### Shellcheck/Linting Failures

**Symptom**: CI fails on linting checks

**Solution**: Run linters locally before committing:

```bash
make lint

# Fix shell script formatting
shfmt -i 2 -ci -w scripts/*.sh

# Fix markdown issues
markdownlint -f *.md
```

## Coding Standards

### Shell Scripts

- **Shebang**: Use `#!/usr/bin/env bash` for portability
- **Error handling**: Always use `set -euo pipefail` and `IFS=$'\n\t'`
- **Quoting**: Always quote variables: `"${VAR}"` not `$VAR`
- **Exit codes**: Use meaningful exit codes and error messages
- **Linting**: Code must pass `shellcheck` and `shfmt -i 2 -ci`

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Function with documentation
# Purpose: Download file with retry logic
# Args:
#   $1 - URL to download
#   $2 - Output path
# Returns: 0 on success, 1 on failure
download_file() {
  local url="${1}"
  local output="${2}"
  
  curl -fsSL -o "${output}" "${url}" || {
    echo "ERROR: Failed to download ${url}" >&2
    return 1
  }
}
```

### Dockerfile

- **Base image**: `debian:bookworm-slim`
- **Layer optimization**: Combine related commands, clean up in same layer
- **Security**: Run as non-root user (`USER pandoc`)
- **Multi-arch**: Support both amd64 and arm64
- **Build args**: Use for configurable options
- **Comments**: Clearly separate and document each stage

### LaTeX Templates

- **Counter compatibility**: Always define `\newcounter{none}` for Pandoc longtable support
- **Package loading order**: Load packages in correct order to avoid conflicts
- **Conditional blocks**: Use Pandoc template variables properly (e.g., `$if(beamer)$...$endif$`)

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build process, tooling changes

Examples:
```
feat(templates): Add new techdoc template
fix(docker): Resolve Chromium sandbox issue
docs(readme): Update installation instructions
chore(ci): Update GitHub Actions to v4
```

## Additional Resources

- **User Documentation**: [README.md](README.md)
- **Template Authoring**: [AUTHOR_GUIDE.md](AUTHOR_GUIDE.md)
- **Contributing Guidelines**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **GitHub CI/CD Setup**: [.github/SETUP.md](.github/SETUP.md)
- **Change History**: [CHANGELOG.md](CHANGELOG.md)

For CI/CD setup and GitHub Actions configuration, see [.github/SETUP.md](.github/SETUP.md).
