# Contributing to docker-pandoc

Thank you for your interest in contributing to the docker-pandoc project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Quick Start](#quick-start)
- [Pull Request Process](#pull-request-process)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Getting Help](#getting-help)

## Quick Start

### Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Buildx
- [Git](https://git-scm.com/)
- [Make](https://www.gnu.org/software/make/)
- Linting tools: shellcheck, shfmt, markdownlint-cli, hadolint (see README.md for installation)

### Clone and Build

```bash
git clone https://github.com/oehrlis/docker-pandoc.git
cd docker-pandoc
make build
make lint
make test
```

## Pull Request Process

All pull requests are automatically checked by CI for:

- Shellcheck (shell scripts validation)
- shfmt (shell script formatting)
- markdownlint (markdown linting)
- hadolint (Dockerfile linting)
- Example validation

### Submitting a Pull Request

1. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make focused, minimal changes**

3. **Run linters and tests**:

   ```bash
   make lint
   make build
   make test
   ```

4. **Commit with conventional commit messages**:

   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```

   Commit types: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`

5. **Push and create PR**:

   ```bash
   git push origin feature/your-feature-name
   ```

### PR Requirements

- ✓ All CI checks pass
- ✓ Code follows existing style
- ✓ Minimal, focused changes
- ✓ Clear commit messages
- ✓ Documentation updated if needed

## Development Workflow

### Common Commands

```bash
make help              # Show all available targets
make build             # Build Docker image locally
make build-multi       # Build multi-platform image
make lint              # Run all linters
make lint-shell        # Run shellcheck only
make lint-markdown     # Run markdownlint only
make lint-docker       # Run hadolint only
make test              # Build and test samples
make shell             # Open shell in container
make clean             # Clean up artifacts
make version           # Show current version
make release           # Create new release (maintainers only)
```

### Testing Changes

```bash
# Build and test
make build
make test

# Test manually
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:latest \
  sample/sample.md -o test-output.pdf --toc --listings
```

### Creating a Release (Maintainers Only)

Use semantic versioning (no `v` prefix):

```bash
make release           # Interactive release process
# OR manually:
echo "1.0.1" > VERSION
git add VERSION
git commit -m "Bump version to 1.0.1"
git tag 1.0.1
git push origin main --tags
```

The release workflow automatically:

- Builds multi-platform images (linux/amd64, linux/arm64)
- Pushes to Docker Hub with version and `latest` tags
- Creates GitHub release with sample artifacts

## Code Style Guidelines

### Shell Scripts

- Use 2-space indentation
- Follow shellcheck recommendations
- Use meaningful variable names
- Add comments for complex logic

### Markdown

- Use 2-space indentation for lists
- Use reference-style links for repeated URLs
- Follow existing document structure

### Dockerfile

- Use multi-stage builds when appropriate
- Minimize layers by combining commands
- Sort multi-line commands alphabetically
- Clean up package manager caches

### Makefile

- Use tabs for indentation (not spaces)
- Keep target names lowercase with hyphens
- Add help text for all public targets

## Getting Help

### Reporting Issues

Check [existing issues](https://github.com/oehrlis/docker-pandoc/issues) or [create a new issue](https://github.com/oehrlis/docker-pandoc/issues/new) with:

- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Docker version, etc.)

### Questions

- Open a GitHub Discussion
- File an issue with the "question" label

### Resources

- [Pandoc Documentation](https://pandoc.org/MANUAL.html)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/actions)

## License

By contributing to docker-pandoc, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing! 🎉
