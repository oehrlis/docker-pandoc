# Docker Image Variants
<!-- markdownlint-disable MD013 -->

This project publishes four Docker image variants optimised for different use
cases. All variants are built for `linux/amd64` and `linux/arm64`.

## Docker Hub Tags

| Tag | Variant | Description |
|-----|---------|-------------|
| `latest` | standard | Default — Pandoc + TeX Live + fonts + templates |
| `VERSION` | standard | Pinned release, same content as `latest` |
| `VERSION-minimal` | minimal | Pandoc only, no TeX, no Mermaid |
| `VERSION-standard` | standard | Pandoc + TeX Live + fonts + templates |
| `VERSION-mermaid` | mermaid | Pandoc + Mermaid/Chromium, no TeX |
| `VERSION-full` | full | All features: TeX + Mermaid + fonts + templates |

> `latest` and `VERSION` always point to the **standard** variant.

---

## Variant Details

### `minimal` (~250 MB)

**Includes:** Pandoc binary · basic system libraries

**Does not include:** TeX Live · Mermaid/Chromium · extra fonts · templates

**Use when:**
- Converting Markdown → HTML, JSON, or other text formats
- CI/CD pipelines where image size is critical
- No PDF or template requirements

```bash
docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-minimal \
  input.md -o output.html
```

---

### `standard` (~800 MB–1 GB) · **DEFAULT / `latest`**

**Includes:** Pandoc · TeX Live (XeLaTeX + packages) · MS Core Fonts, Open Sans,
Montserrat · OraDBA / TechDoc / Trivadis LaTeX templates · Pandoc Python filters
(`pandoc-latex-environment`, `pandoc-latex-color`, `pandoc-include`)

**Does not include:** Mermaid/Chromium

**Use when:**
- Generating PDFs from Markdown (most common use case)
- Using custom LaTeX templates
- Professional documents with custom fonts
- Production environments without diagram requirements

```bash
# PDF with custom template
docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-standard \
  input.md \
  --metadata-file metadata.yml \
  --pdf-engine=xelatex \
  --template=oradba \
  -o output.pdf

# Or simply use latest (points to standard)
docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:latest \
  input.md --pdf-engine=xelatex -o output.pdf
```

---

### `mermaid` (~900 MB–1 GB)

**Includes:** Pandoc · Node.js · mermaid-cli (`mmdc`) · Chromium · `mermaid.lua`
Lua filter

**Does not include:** TeX Live · custom templates

**Use when:**
- Rendering Mermaid diagrams in HTML output
- Diagram-to-PNG/SVG workflows
- Web-based documentation without PDF requirements

```bash
docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-mermaid \
  input.md \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone \
  -o output.html
```

> No `--cap-add=SYS_ADMIN` required — the Lua filter passes `--no-sandbox`
> flags to Chromium via a JSON puppeteer config.

---

### `full` (~1.3–1.5 GB)

**Includes:** Everything — Pandoc · TeX Live · Mermaid/Chromium · all fonts ·
all templates · Python filters

**Use when:**
- Documents need both **PDF output** and **Mermaid diagrams**
- Complete documentation pipelines
- Development and testing environments

```bash
docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-full \
  input.md \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --pdf-engine=xelatex \
  --template=oradba \
  -o output.pdf
```

---

## Feature Matrix

| Feature | minimal | standard | mermaid | full |
|---------|:-------:|:--------:|:-------:|:----:|
| **Approx. size** | ~250 MB | ~800 MB–1 GB | ~900 MB–1 GB | ~1.3–1.5 GB |
| Pandoc binary | ✅ | ✅ | ✅ | ✅ |
| TeX Live / XeLaTeX | ❌ | ✅ | ❌ | ✅ |
| PDF generation | ❌ | ✅ | ❌ | ✅ |
| LaTeX templates | ❌ | ✅ | ❌ | ✅ |
| MS Core / custom fonts | ❌ | ✅ | ❌ | ✅ |
| Python filters | ❌ | ✅ | ❌ | ✅ |
| Mermaid CLI (`mmdc`) | ❌ | ❌ | ✅ | ✅ |
| Chromium | ❌ | ❌ | ✅ | ✅ |
| Node.js | ❌ | ❌ | ✅ | ✅ |
| `mermaid.lua` filter | ✅ | ✅ | ✅ | ✅ |

> `mermaid.lua` is present in all variants. In `minimal` and `standard` it
> gracefully skips rendering when `mmdc` is absent (falls back to code block).

---

## Mermaid Filter Options

The `mermaid.lua` Lua filter accepts these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MERMAID_IMAGE_WIDTH` | `80%` | Image width as % of line width |
| `MERMAID_IMAGE_MAX_HEIGHT` | `75%` | Max height as % of page height (keepaspectratio) |
| `MERMAID_OUTPUT_DIR` | `build/mermaid` | Directory for rendered PNGs |
| `MERMAID_CLI_BIN` | `mmdc` | Path to mermaid-cli binary |
| `MERMAID_SKIP_RENDERING` | _(unset)_ | Set to `true` to skip rendering (pass-through) |

**Caption support** — add a `caption` attribute to the fenced code block:

````markdown
```{.mermaid caption="Figure 1: System Architecture"}
flowchart TD
    A[Client] --> B[API] --> C[Database]
```
````

In PDF output this becomes a `\figure` environment with `\caption{}` (included
in the list of figures if `lof: true` is set in metadata).

---

## Building Variants

### Local development (single platform, no push)

```bash
# Single variant
make build                  # default: standard
make build VARIANT=full

# All four variants
make build-all
```

### Release build (all variants, local, VERSION tags)

```bash
make build-release          # tags: 4.1.0-minimal/standard/mermaid/full
                            #       4.1.0 → standard
                            #       latest → standard
```

### Multi-platform push to registry

```bash
make build-multi            # builds linux/amd64 + linux/arm64, pushes all tags
```

### Via git tag (CI/CD release pipeline)

```bash
make tag                    # creates annotated tag v4.1.0
git push origin master && git push origin v4.1.0
# → triggers .github/workflows/release.yml automatically
```

---

## Choosing the Right Variant

```
Need PDF output?
├── Yes → Need Mermaid diagrams?
│         ├── Yes → full
│         └── No  → standard (or latest)
└── No  → Need Mermaid diagrams?
          ├── Yes → mermaid
          └── No  → minimal
```

---

## CI/CD Examples

### GitHub Actions

```yaml
# PDF generation — use standard (or latest)
- name: Build PDF
  run: |
    docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:latest \
      input.md --pdf-engine=xelatex -o output.pdf

# Mermaid + PDF — use full
- name: Build PDF with diagrams
  run: |
    docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-full \
      input.md \
      --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
      --pdf-engine=xelatex -o output.pdf

# HTML with diagrams — use mermaid
- name: Build HTML with diagrams
  run: |
    docker run --rm -v "$PWD:/workdir:z" oehrlis/pandoc:4.1.0-mermaid \
      input.md \
      --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
      --standalone -o output.html

# Skip Mermaid rendering in CI (no mmdc available)
- name: Build HTML (skip diagrams)
  run: |
    docker run --rm \
      -e MERMAID_SKIP_RENDERING=true \
      -v "$PWD:/workdir:z" oehrlis/pandoc:latest \
      input.md --standalone -o output.html
```

### Docker Compose

```yaml
services:
  pandoc-standard:
    image: oehrlis/pandoc:latest
    volumes:
      - ./docs:/workdir

  pandoc-full:
    image: oehrlis/pandoc:4.1.0-full
    # No cap_add needed — mermaid.lua uses --no-sandbox via puppeteer JSON config
    volumes:
      - ./docs:/workdir
    environment:
      MERMAID_IMAGE_WIDTH: "80%"
      MERMAID_IMAGE_MAX_HEIGHT: "75%"
```

---

## Support

Open an issue at <https://github.com/oehrlis/docker-pandoc/issues> and include:

- Variant name and version tag
- Full `docker run` command
- Expected vs. actual behaviour
- Error output
