# Docker Image Size Optimization - Issue #9

## Summary

✅ **Current Dockerfile already uses multi-stage builds**

The main opportunities for size reduction:

1. **Create specialized image variants** (recommended)
2. **Optimize TeX Live installation** (reduce ~200-400MB)
3. **Optimize Node.js/Chromium layers** (reduce ~100-200MB)
4. **Better layer combining and cleanup** (reduce ~50-100MB)

## Current State

### Image Sizes (from `docker images`)
- `oehrlis/pandoc:latest` - 605MB (older build)
- `oehrlis/pandoc:test` - 808MB (Mermaid, no TeX)
- `oehrlis/pandoc:test-chromium` - 1.42GB (Chromium + Mermaid)
- `oehrlis/pandoc:4.0.0` - 2.83GB (full TeX Live)

### Size Contributors
1. TeX Live: ~600MB (Debian packages) or ~220MB (custom minimal)
2. Pandoc binary: ~173MB (cannot reduce)
3. Chromium: ~300MB + ~300MB dependencies
4. Node.js + mermaid-cli: ~400MB
5. Python + filters: ~90MB
6. Fonts: ~20MB

## Recommended Strategy: Image Variants

Create specialized images for different use cases:

###  `pandoc:minimal` (~250MB)
- Pandoc binary only
- No TeX, no Mermaid, no extra fonts
- **Use case:** Markdown transformations, format conversions (HTML, JSON, DOCX without custom templates)

### `pandoc:standard` (~600-800MB) - **DEFAULT**
- Pandoc + optimized TeX Live
- Basic fonts
- **Use case:** Standard PDF generation, most users

### `pandoc:full` (~1.2-1.5GB)
- Everything: Pandoc + TeX Live + Chromium + Mermaid
- All fonts and filters
- **Use case:** Complex documents with diagrams

### `pandoc:mermaid` (~900MB-1GB)
- Pandoc + Chromium + Mermaid + Node.js
- No TeX Live (HTML/PNG output only)
- **Use case:** Diagram generation without PDF

## Quick Wins (Phase 1)

### 1. Add .dockerignore
```
.git/
.github/
examples/
build/
*.md
!README.md
!CHANGELOG.md
.vscode/
.DS_Store
*.log
node_modules/
```
**Savings:** Faster builds, smaller context

### 2. Optimize TeX Live
```dockerfile
# Instead of texlive-latex-extra (huge), use:
RUN apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-latex-base \
    texlive-latex-recommended \
    lmodern \
    && rm -rf /var/lib/apt/lists/* \
              /usr/share/doc/* \
              /usr/share/man/* \
              /usr/share/texlive/texmf-dist/doc/*
```
**Savings:** ~200-300MB

### 3. Clean Node.js more aggressively
```bash
npm cache clean --force
rm -rf /root/.npm /tmp/* /var/tmp/*
find /usr/local/lib/node_modules -name "*.md" -delete
find /usr/local/lib/node_modules -name "test" -type d -exec rm -rf {} + 2>/dev/null || true
```
**Savings:** ~50-100MB

### 4. Combine RUN commands
- Merge TeX Live installation with cleanup
- Merge Mermaid installation with cleanup
- Remove intermediate layers

**Savings:** ~50MB

## Implementation Steps

1. Create `.dockerignore`
2. Create `Dockerfile.minimal` (Pandoc only)
3. Optimize current `Dockerfile` (becomes "standard")
4. Create `Dockerfile.full` (everything)
5. Create `Dockerfile.mermaid` (diagrams only)
6. Update build scripts and GitHub Actions
7. Update documentation with variant descriptions

## Testing Plan

For each variant:
- ✅ Build succeeds
- ✅ Pandoc version correct
- ✅ Can convert Markdown to HTML
- ✅ (standard/full) Can generate PDF
- ✅ (full/mermaid) Mermaid rendering works
- ✅ (standard/full) Fonts render correctly
- ✅ Image size meets target

## Next Steps

1. Start with Phase 1 quick wins on current Dockerfile
2. Measure size reduction
3. Create minimal and mermaid variants
4. Update CI/CD to build all variants
5. Update documentation

**Target completion:** After validating Phase 1 optimizations work
