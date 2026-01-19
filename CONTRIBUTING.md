# Contributing to docker-pandoc

Thank you for your interest in contributing to the docker-pandoc project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Development Setup](#development-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Release Process](#release-process)
- [Linting Requirements](#linting-requirements)
- [Testing Locally](#testing-locally)
- [Pull Request Process](#pull-request-process)
- [Code Style Guidelines](#code-style-guidelines)

## Development Setup

### Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Buildx
- [Git](https://git-scm.com/)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on Linux/macOS)
- Recommended linting tools (see [Linting Requirements](#linting-requirements))

### Clone the Repository

```bash
git clone https://github.com/oehrlis/docker-pandoc.git
cd docker-pandoc
```

### Install Linting Tools (Optional but Recommended)

#### Shellcheck (Shell script linter)
```bash
# Ubuntu/Debian
apt-get install shellcheck

# macOS
brew install shellcheck
```

#### shfmt (Shell script formatter)
```bash
# Download from GitHub releases
curl -L "https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64" -o shfmt
chmod +x shfmt
sudo mv shfmt /usr/local/bin/
```

#### markdownlint-cli (Markdown linter)
```bash
npm install -g markdownlint-cli
```

#### hadolint (Dockerfile linter)
```bash
# Download from GitHub releases
wget https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64
sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint
```

## CI/CD Pipeline

### CI Workflow (Continuous Integration)

The CI workflow runs automatically on:
- Pull requests to `main`/`master` branch
- Pushes to `main`/`master` branch

**What it checks**:
1. **Shellcheck**: Validates all shell scripts for common issues and best practices
2. **Shell Format**: Ensures shell scripts follow consistent formatting
3. **Markdown Lint**: Checks all markdown files for formatting issues
4. **Docker Lint**: Validates Dockerfile best practices with Hadolint
5. **Example Validation**: Ensures example markdown files are valid

### Release Workflow (Continuous Deployment)

The release workflow runs automatically when a semantic version tag is pushed (e.g., `1.0.0`).

**What it does**:
1. Builds multi-platform Docker images (linux/amd64, linux/arm64)
2. Pushes images to Docker Hub with version and `latest` tags
3. Builds sample documents to verify functionality
4. Creates a GitHub release with auto-generated notes and sample artifacts

## Release Process

### Creating a New Release

#### Option 1: Using Make (Recommended)

```bash
make release
```

This interactive command will:
- Display the current version
- Prompt for a new version number
- Update the VERSION file
- Create a git commit and tag
- Optionally push the tag to trigger the release workflow

#### Option 2: Manual Process

```bash
# 1. Update the VERSION file
echo "1.0.1" > VERSION

# 2. Commit the change
git add VERSION
git commit -m "Bump version to 1.0.1"

# 3. Create and push the tag
git tag 1.0.1
git push origin main
git push --tags
```

### Version Numbering

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Incompatible API changes
- **MINOR** version (0.X.0): New functionality in a backward-compatible manner
- **PATCH** version (0.0.X): Backward-compatible bug fixes

**Important**: 
- Tags and VERSION file should use format: `1.0.0` (no `v` prefix)
- Docker images are tagged as: `oehrlis/pandoc:1.0.0` and `oehrlis/pandoc:latest`

## Linting Requirements

All pull requests must pass linting checks. Run linters locally before submitting:

### Run All Linters

```bash
make lint
```

### Run Individual Linters

```bash
make lint-shell          # Shellcheck
make lint-shell-format   # shfmt
make lint-markdown       # markdownlint
make lint-docker         # hadolint
```

### Linting Configuration Files

- `.shellcheckrc`: Shellcheck configuration
- `.markdownlint.json`: Markdownlint rules
- `.hadolint.yaml`: Hadolint rules
- `.editorconfig`: Editor configuration for consistent formatting

## Testing Locally

### Build the Docker Image

```bash
# Build for local platform only
make build

# Build multi-platform (requires Buildx)
make build-multi
```

### Run Tests

```bash
# Build all sample documents
make test

# Or specifically test samples
make test-samples
```

### Test the Image Manually

```bash
# Open a shell in the container
make shell

# Convert a sample markdown to PDF
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:4.0.0 \
  sample/sample.md -o test-output.pdf --toc --listings
```

### Clean Up Test Artifacts

```bash
make clean
```

## Pull Request Process

### Before Submitting a PR

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** with focused, minimal modifications

3. **Run linters**:
   ```bash
   make lint
   ```

4. **Test your changes**:
   ```bash
   make build
   make test
   ```

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```
   
   Use conventional commit messages:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `style:` Code style changes (formatting)
   - `refactor:` Code refactoring
   - `test:` Adding or updating tests
   - `chore:` Maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a pull request** on GitHub

### PR Requirements

- ✓ All CI checks must pass
- ✓ Code follows existing style and conventions
- ✓ Commit messages are clear and descriptive
- ✓ Changes are minimal and focused on the issue
- ✓ Documentation is updated if needed
- ✓ No unrelated changes or files

### PR Review Process

1. Automated CI checks run on your PR
2. Maintainers review your code
3. Address any feedback or requested changes
4. Once approved, your PR will be merged

## Code Style Guidelines

### Shell Scripts

- Use 2-space indentation
- Follow shellcheck recommendations
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

### Markdown

- Use 2-space indentation for lists
- Keep lines under 120 characters (when reasonable)
- Use reference-style links for repeated URLs
- Follow the existing document structure

### Dockerfile

- Use multi-stage builds when appropriate
- Minimize layers by combining commands
- Sort multi-line commands alphabetically
- Clean up package manager caches
- Add comments for complex operations

### Makefile

- Use tabs for indentation (not spaces)
- Keep target names lowercase with hyphens
- Add help text for all public targets
- Group related targets with ##@ headers

## Common Development Tasks

### View Current Version

```bash
make version
```

### View All Available Make Targets

```bash
make help
```

### Push Image to Docker Hub

```bash
make push
```

### Build Without Cache

```bash
./build.sh 4.0.0 --no-cache
```

## Getting Help

### Reporting Issues

- Check [existing issues](https://github.com/oehrlis/docker-pandoc/issues)
- Create a [new issue](https://github.com/oehrlis/docker-pandoc/issues/new) with:
  - Clear description of the problem
  - Steps to reproduce
  - Expected vs actual behavior
  - Your environment (OS, Docker version, etc.)

### Asking Questions

- Open a discussion in GitHub Discussions
- File an issue with the "question" label

## Resources

- [Pandoc Documentation](https://pandoc.org/MANUAL.html)
- [TeX Live Documentation](https://www.tug.org/texlive/doc.html)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/actions)

## License

By contributing to docker-pandoc, you agree that your contributions will be licensed under the Apache License 2.0.

Thank you for contributing! 🎉
