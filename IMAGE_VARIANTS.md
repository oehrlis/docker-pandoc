# Docker Image Variants

This project provides multiple Docker image variants optimized for different use cases. Each variant includes different features and has different size characteristics.

## Available Variants

### `pandoc:VERSION-minimal` (~250MB)

**What's included:**
- Pandoc binary only
- Basic system libraries
- No TeX Live
- No Mermaid/Chromium
- No extra fonts

**Use cases:**
- Markdown to HTML conversion
- Markdown to JSON/other text formats
- Document structure manipulation
- Format conversions that don't require PDF or custom templates
- CI/CD pipelines with minimal size requirements

**Example:**
```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:4.0.0-minimal \
  input.md -o output.html
```

### `pandoc:VERSION-standard` (~800MB-1GB) **[DEFAULT]**

**What's included:**
- Pandoc binary
- Full TeX Live (XeLaTeX, LaTeX packages)
- MS Core Fonts, Open Sans, Montserrat
- Custom LaTeX templates (OraDBA, TechDoc, Trivadis)
- No Mermaid/Chromium

**Use cases:**
- PDF generation from Markdown
- Documents using custom LaTeX templates
- Professional documents with custom fonts
- Most common use cases
- Production environments without diagram requirements

**Example:**
```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:4.0.0-standard \
  input.md -o output.pdf --pdf-engine=xelatex --template=oradba
```

### `pandoc:VERSION-mermaid` (~900MB-1GB)

**What's included:**
- Pandoc binary
- Mermaid CLI + Chromium
- Node.js runtime
- Minimal fonts
- No TeX Live

**Use cases:**
- Markdown to HTML with Mermaid diagrams
- Diagram rendering to PNG/SVG
- Web-based documentation
- HTML reports with charts/diagrams
- When PDF generation is not needed

**Example:**
```bash
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z \
  oehrlis/pandoc:4.0.0-mermaid \
  input.md -o output.html --lua-filter=/usr/local/share/pandoc/filters/mermaid.lua --standalone
```

### `pandoc:VERSION-full` (~1.3-1.5GB)

**What's included:**
- Everything: Pandoc + TeX Live + Mermaid + Chromium
- All fonts and templates
- All features from other variants

**Use cases:**
- Complex documents with diagrams AND PDF output
- Complete documentation pipelines
- When you need both diagram rendering and PDF generation
- Development and testing environments
- Maximum flexibility

**Example:**
```bash
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z \
  oehrlis/pandoc:4.0.0-full \
  input.md -o output.pdf --pdf-engine=xelatex --template=oradba \
  --lua-filter=/usr/local/share/pandoc/filters/mermaid.lua
```

## Variant Comparison

| Feature | minimal | standard | mermaid | full |
|---------|---------|----------|---------|------|
| **Size** | ~250MB | ~800MB-1GB | ~900MB-1GB | ~1.3-1.5GB |
| Pandoc | ✅ | ✅ | ✅ | ✅ |
| TeX Live | ❌ | ✅ | ❌ | ✅ |
| PDF Generation | ❌ | ✅ | ❌ | ✅ |
| Custom Templates | ❌ | ✅ | ❌ | ✅ |
| MS Core Fonts | ❌ | ✅ | ❌ | ✅ |
| Custom Fonts | ❌ | ✅ | ❌ | ✅ |
| Mermaid Diagrams | ❌ | ❌ | ✅ | ✅ |
| Chromium | ❌ | ❌ | ✅ | ✅ |
| Node.js | ❌ | ❌ | ✅ | ✅ |

## Building Variants

### Build all variants locally
```bash
./scripts/build-variants.sh
```

### Build specific variant
```bash
docker build --build-arg IMAGE_VARIANT=minimal -t oehrlis/pandoc:dev-minimal .
```

### Build for multiple architectures
```bash
PLATFORM="linux/amd64,linux/arm64" PUSH=true ./scripts/build-variants.sh
```

## Choosing the Right Variant

**Choose `minimal` if:**
- You only need format conversions (MD → HTML, MD → JSON, etc.)
- Size is critical (CI/CD, edge devices)
- No PDF or template requirements

**Choose `standard` if:**
- You need PDF generation
- You use custom LaTeX templates
- You need professional fonts
- No diagram rendering required
- **This is the recommended default for most users**

**Choose `mermaid` if:**
- You need diagram rendering
- HTML output is sufficient
- You don't need PDF generation
- Working on web-based documentation

**Choose `full` if:**
- You need both PDFs and diagrams
- Maximum flexibility is required
- Development/testing environment
- Size is not a concern
- You want "everything included"

## CI/CD Recommendations

### GitHub Actions
```yaml
# Use minimal for simple conversions
- uses: docker://oehrlis/pandoc:4.0.0-minimal
  
# Use standard for PDF generation
- uses: docker://oehrlis/pandoc:4.0.0-standard
  
# Use mermaid with alternative rendering methods (avoid --cap-add)
- uses: docker://oehrlis/pandoc:4.0.0-mermaid
  env:
    MERMAID_SKIP_RENDERING: "true"  # Pre-render or use alternatives
```

### Docker Compose
```yaml
services:
  pandoc-standard:
    image: oehrlis/pandoc:4.0.0-standard
    volumes:
      - ./docs:/workdir
    
  pandoc-full:
    image: oehrlis/pandoc:4.0.0-full
    cap_add:
      - SYS_ADMIN  # Required for Chromium
    volumes:
      - ./docs:/workdir
```

## Migration Guide

### From `latest` to variants

If you're currently using `oehrlis/pandoc:latest`:

1. **Determine your needs:**
   - PDF only → use `standard`
   - Diagrams only → use `mermaid`
   - Both → use `full`
   - Neither → use `minimal`

2. **Update your references:**
   ```bash
   # Old
   docker run oehrlis/pandoc:latest ...
   
   # New
   docker run oehrlis/pandoc:4.0.0-standard ...
   ```

3. **Test your workflows:**
   - Verify all features work as expected
   - Check CI/CD pipelines
   - Validate output files

## Size Optimization Trade-offs

Each variant makes specific trade-offs:

**minimal:**
- ✅ Smallest size
- ✅ Fastest downloads
- ❌ Limited functionality

**standard:**
- ✅ Balanced size/features
- ✅ Most common use case
- ❌ No diagrams

**mermaid:**
- ✅ Diagram support
- ✅ Reasonable size
- ❌ No PDF

**full:**
- ✅ All features
- ✅ Maximum flexibility
- ❌ Largest size

## Support and Issues

If you encounter issues with specific variants, please open an issue on GitHub with:
- Variant name and version
- Command you're running
- Expected vs actual behavior
- Error messages (if any)
