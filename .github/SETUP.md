# GitHub Repository Setup Instructions

This document provides instructions for repository maintainers to set up the automated build and release system.

## Required GitHub Secrets

To enable the automated release workflow, you need to configure the following secrets in your GitHub repository:

### Setting Up Secrets

1. Navigate to your GitHub repository: https://github.com/oehrlis/docker-pandoc
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click on **New repository secret** and add the following secrets:

### Required Secrets

#### `DOCKERHUB_USERNAME`
- **Value**: Your Docker Hub username (should be `oehrlis`)
- **Purpose**: Used to authenticate with Docker Hub for pushing images

#### `DOCKERHUB_TOKEN`
- **Value**: Docker Hub access token
- **Purpose**: Secure authentication token for Docker Hub
- **How to create**:
  1. Log in to Docker Hub: https://hub.docker.com
  2. Go to **Account Settings** → **Security** → **Access Tokens**
  3. Click **New Access Token**
  4. Give it a descriptive name (e.g., "GitHub Actions Release")
  5. Set permissions to **Read, Write, Delete**
  6. Click **Generate**
  7. Copy the token (you won't be able to see it again)
  8. Add it as a GitHub secret

## Repository Settings

### Enable GitHub Actions

1. Go to **Settings** → **Actions** → **General**
2. Ensure **Actions permissions** is set to "Allow all actions and reusable workflows"
3. Under **Workflow permissions**, select "Read and write permissions"
4. Check "Allow GitHub Actions to create and approve pull requests"

### Branch Protection (Optional but Recommended)

If you want to protect the main/master branch:

1. Go to **Settings** → **Branches**
2. Click **Add rule** for `main` or `master`
3. Configure protection rules:
   - ✓ Require status checks to pass before merging
   - ✓ Require branches to be up to date before merging
   - Select status checks: CI workflow jobs
   - ✓ Require linear history (optional)

## Workflow Overview

### CI Workflow (`.github/workflows/ci.yml`)

**Triggers**: Pull requests and pushes to main/master

**Jobs**:
- Shellcheck: Validates shell script syntax and best practices
- Shell Format Check: Ensures consistent shell script formatting
- Markdown Lint: Validates markdown file formatting
- Docker Lint: Checks Dockerfile best practices
- Validate Examples: Ensures example markdown files are valid

### Release Workflow (`.github/workflows/release.yml`)

**Triggers**: Git tags matching pattern `[0-9]+.[0-9]+.[0-9]+` (e.g., `1.0.0`, `2.1.3`)

**Jobs**:
1. Extract version from git tag
2. Build multi-platform Docker image (linux/amd64, linux/arm64)
3. Push images to Docker Hub with tags:
   - `oehrlis/pandoc:<version>`
   - `oehrlis/pandoc:latest`
   - `oehrlis/pandoc:texlive-slim`
4. Build sample documents (PDF, DOCX, PPTX, Mermaid example)
5. Create GitHub release with auto-generated notes and sample artifacts

## Creating a Release

There are two ways to create a release:

### Method 1: Using the Makefile (Recommended)

```bash
make release
```

This interactive command will:
1. Prompt for the new version number
2. Update the VERSION file
3. Create a git commit and tag
4. Optionally push the tag to trigger the release workflow

### Method 2: Manual Process

```bash
# Update VERSION file
echo "1.0.1" > VERSION

# Commit and tag
git add VERSION
git commit -m "Bump version to 1.0.1"
git tag 1.0.1

# Push to trigger release
git push
git push --tags
```

## Verifying the Setup

After configuring secrets:

1. Create a test tag:
   ```bash
   git tag 0.0.1-test
   git push --tags
   ```

2. Check the Actions tab in GitHub to see if the release workflow runs
3. Verify that the Docker image is pushed to Docker Hub
4. Check that a GitHub release is created

If everything works, you can delete the test tag and release:
```bash
git tag -d 0.0.1-test
git push origin :refs/tags/0.0.1-test
```

## Troubleshooting

### Release workflow fails with authentication error
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are correctly set
- Ensure the Docker Hub token has not expired
- Check that the token has appropriate permissions (Read, Write, Delete)

### CI workflow fails on specific linters
- Run linters locally using `make lint`
- Fix any issues before pushing
- Some linters can be installed with: `make lint-<tool>` will show installation instructions

### Multi-platform build is slow
- The first build may be slow as it needs to set up QEMU and Buildx
- Subsequent builds use GitHub Actions cache for better performance
- The `cache-from` and `cache-to` settings in the workflow enable this caching

## Maintenance

### Updating Workflow Dependencies

The workflows use specific versions of GitHub Actions. Periodically update them:

```yaml
# Check for updates at:
# - actions/checkout: https://github.com/actions/checkout/releases
# - docker/setup-buildx-action: https://github.com/docker/setup-buildx-action/releases
# - docker/build-push-action: https://github.com/docker/build-push-action/releases
```

### Monitoring Builds

- Check the **Actions** tab regularly for failed workflows
- Set up notifications for workflow failures in repository settings
- Review the generated releases to ensure sample documents are correct

## Support

For issues with the CI/CD setup:
1. Check workflow logs in the Actions tab
2. Consult GitHub Actions documentation: https://docs.github.com/actions
3. File an issue: https://github.com/oehrlis/docker-pandoc/issues

For Docker Hub issues:
- Docker Hub documentation: https://docs.docker.com/docker-hub/
- Check repository settings: https://hub.docker.com/r/oehrlis/pandoc
