# Pandoc Docker Images

[![CI](https://github.com/oehrlis/docker-pandoc/actions/workflows/ci.yml/badge.svg)](https://github.com/oehrlis/docker-pandoc/actions/workflows/ci.yml)
[![Release](https://github.com/oehrlis/docker-pandoc/actions/workflows/release.yml/badge.svg)](https://github.com/oehrlis/docker-pandoc/actions/workflows/release.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/oehrlis/pandoc)](https://hub.docker.com/r/oehrlis/pandoc)
[![Docker Image Version](https://img.shields.io/docker/v/oehrlis/pandoc?sort=semver)](https://hub.docker.com/r/oehrlis/pandoc)
[![License](https://img.shields.io/github/license/oehrlis/docker-pandoc)](LICENSE)

<!-- markdownlint-disable MD013 -->
Docker scripts to build an image to run the universal document converter [pandoc](https://pandoc.org) including support to convert PDF files. The image includes a reduced [TexLive 2022](https://www.tug.org/texlive/) installation to support simple PDF transformations and Mermaid diagram rendering support for generating diagrams in PDFs. Additional TexLive packages have to be installed by extending this images. Source can be found in GitHub [oehrlis/docker-pandoc](https://github.com/oehrlis/docker-pandoc).
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-enable MD013 -->

## Run

<!-- markdownlint-disable MD013 -->
The pre build image is available via [Dockerhub](https://hub.docker.com/r/oehrlis/pandoc/). The installation and use is straightforward. Install [Docker](https://www.docker.com/get-started) and pull the image.
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-enable MD013 -->

```bash
docker pull oehrlis/pandoc
```

<!-- markdownlint-disable MD013 -->
Either you copy the files into the container, which is obviously not really handy, or you mount your local document folder as volume and run it.
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-enable MD013 -->

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc <OPTIONS>
```

Conversion of the sample Markdown file into a PDF using the default LaTeX template.

```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc sample.md \
    -o sample.pdf --toc -N --listings
```

Conversion of the sample Markdown file into a PDF using the OraDBA LaTeX template and XeLaTeX for include custom TTF fonts.

```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc --pdf-engine=xelatex sample.md \
    -o sample_oradba.pdf --template oradba --toc -N --listings
```

```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc sample.md \
    -o sample_oradba.pdf --template oradba --toc -N --listings
```

Alternatively you can open a shell in the container and use the miscellanies pandoc and tex tools interactively.

```bash
docker run -it --rm -v $PWD:/workdir:z --entrypoint sh oehrlis/pandoc
```

## Mermaid Diagram Support

This image includes support for rendering Mermaid diagrams in PDF output.

### Usage with Mermaid

To convert Markdown files containing Mermaid diagrams to PDF:

```bash
docker run --rm \
    -v $(pwd):/workdir \
    oehrlis/pandoc:latest \
    input.md \
    -o output.pdf \
    --filter mermaid-filter \
    --pdf-engine=xelatex
```

### Mermaid Example

Include Mermaid diagrams in your Markdown using code blocks:

```mermaid
graph TD
    A[Start] --> B[End]
```

The diagrams will be automatically rendered as images in the PDF output.

### Installed Components

- **mermaid-cli**: Latest version from npm
- **mermaid-filter**: Latest version from npm
- **Chromium**: System chromium browser for rendering

## Build and add new packages

<!-- markdownlint-disable MD013 -->
If you plan to alter or extend this Docker image you could get the corresponding files from [GitHub](https://github.com/oehrlis/docker-pandoc) and build the image manually.
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-enable MD013 -->

```bash
git clone git@github.com:oehrlis/docker-pandoc.git
$ cd docker-pandoc
$ docker build -t oehrlis/pandoc .
```

Optionally you can add additional texlive package to the `tlmgr` command in the Dockerfile.

Alternatively you can use the `build.sh` script.

```bash
git clone git@github.com:oehrlis/docker-pandoc.git
$ cd docker-pandoc
$ build.sh
```

## Development

This project uses automated CI/CD pipelines for building, testing, and releasing Docker images.

### Using Makefile

The project includes a comprehensive Makefile for common development tasks:

```bash
# Display all available targets
make help

# Build the Docker image locally
make build

# Build multi-platform image
make build-multi

# Run all linting checks
make lint

# Build sample documents to test
make test-samples

# Open an interactive shell in the container
make shell

# Clean up build artifacts
make clean
```

### Linting Locally

Run linters before submitting pull requests:

```bash
# Run all linters
make lint

# Run individual linters
make lint-shell          # shellcheck
make lint-shell-format   # shfmt
make lint-markdown       # markdownlint
make lint-docker         # hadolint
```

**Installing linting tools**:

```bash
# Shellcheck
apt-get install shellcheck  # Ubuntu/Debian
brew install shellcheck     # macOS

# shfmt
curl -L "https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64" -o shfmt
chmod +x shfmt && sudo mv shfmt /usr/local/bin/

# markdownlint-cli
npm install -g markdownlint-cli

# hadolint
wget https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64 && sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint
```

### Creating a New Release

To create a new release:

```bash
# Interactive release process
make release
```

This will:

1. Prompt for a new version number
2. Update the VERSION file
3. Create a git commit and tag
4. Optionally push the tag to trigger the automated release workflow

The release workflow will:

- Build multi-platform Docker images (linux/amd64, linux/arm64)
- Push images to Docker Hub with version and `latest` tags
- Build sample documents to verify functionality
- Create a GitHub release with auto-generated notes

### Setting Up Docker Hub Credentials for GitHub Actions

Repository maintainers need to configure Docker Hub credentials in GitHub secrets:

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token (create at hub.docker.com/settings/security)

See [`.github/SETUP.md`](.github/SETUP.md) for detailed setup instructions.

### Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- Development setup
- CI/CD pipeline
- Release process
- Linting requirements
- Pull request process

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

- [Existing issues](https://github.com/oehrlis/docker-pandoc/issues)
- [submit new issue](https://github.com/oehrlis/docker-pandoc/issues/new)

## References

- GitHub Project [oehrlis/docker-pandoc](https://github.com/oehrlis/docker-pandoc) related to this container.
- [pandoc](https://pandoc.org)
- [TexLive 2022](https://www.tug.org/texlive/)
- GitHub [google/fonts](https://github.com/google/fonts)
- GitHub [danstoner/pandoc_samples](https://github.com/danstoner/pandoc_samples)
- GitHub [Wandmalfarbe/pandoc-latex-template](https://github.com/Wandmalfarbe/pandoc-latex-template)
- [Google Fonts](https://fonts.google.com/) Montserrat and Open Sans Light
- Get Microsoft's Core Fonts for the Web and ClearType Fonts (<http://mscorefonts2.sourceforge.net/>)
- [Mermaid CLI Documentation](https://github.com/mermaid-js/mermaid-cli)
- [Pandoc Filters Documentation](https://pandoc.org/filters.html)
- [mermaid-filter npm package](https://www.npmjs.com/package/mermaid-filter)
