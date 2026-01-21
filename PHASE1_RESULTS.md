# Phase 1 Optimization Results

## Summary

Attempted to optimize Docker image size by removing `texlive-latex-extra` package and enhancing cleanup procedures. Initial test showed 150MB savings but revealed critical dependency issues.

## Test Results (2026-01-21)

### Build Command
```bash
docker build --platform linux/arm64 -t oehrlis/pandoc:optimized . --load
```

### Size Comparison

| Image | Size | Difference | Notes |
|-------|------|------------|-------|
| oehrlis/pandoc:4.0.0 | 2.83GB | baseline | Full TeX Live with all extras |
| oehrlis/pandoc:test-chromium | 1.42GB | -1.41GB | Previous Mermaid test |
| **oehrlis/pandoc:optimized** | **1.27GB** | **-150MB** | Phase 1 (no texlive-latex-extra) |
| oehrlis/pandoc:test | 808MB | -2.02GB | Basic test image |
| oehrlis/pandoc:latest | 605MB | -2.23GB | Production without Mermaid |

**Initial Result: 1.27GB vs 1.42GB = 150MB savings (10.6% reduction)**

### Functionality Tests

#### ✅ Test 1: Basic Pandoc Conversion
```bash
echo "# Test Document" | docker run --rm -i oehrlis/pandoc:optimized -f markdown -t html
```

**Result:** PASSED

```html
<h1 id="test-document">Test Document</h1>
```

#### ❌ Test 2: PDF Generation with Template
```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:optimized sample.md -o test-opt.pdf --pdf-engine=xelatex
```

**Result:** FAILED

```
Error producing PDF.
! LaTeX Error: File `fontawesome5.sty' not found.

Type X to quit or <RETURN> to proceed,
or enter new name. (Default extension: sty)
```

## Issue Analysis

### Missing LaTeX Packages

The optimization removed `texlive-latex-extra` (~300MB) to reduce image size, but this package contains essential dependencies:

- `fontawesome5.sty` - Icon fonts used in templates
- `pdfcomment.sty` - PDF annotations (oradba template)
- `cprotect.sty` - Verbatim in command arguments
- `xifthen.sty` - Advanced conditionals
- `fancybox.sty` - Box styles
- `adjustbox.sty` - Box sizing and clipping
- Many other packages required by custom LaTeX templates

### Impact on Templates

All custom templates (`oradba.tex`, `techdoc.tex`, `trivadis.tex`) depend on packages from `texlive-latex-extra`:

```latex
% From oradba.tex
\usepackage{fontawesome5}     % MISSING
\usepackage{adjustbox}         % MISSING
\usepackage{pdfcomment}        % MISSING
```

### Conclusion

**Cannot remove texlive-latex-extra** - it's a hard requirement for template functionality.

## Revised Optimization Strategy

### What Works
1. ✅ `.dockerignore` - Reduces build context, faster builds
2. ✅ Enhanced Mermaid cleanup - Removes npm cache, test files, docs
3. ✅ TeX Live documentation cleanup - Removes /usr/share/doc, man pages
4. ✅ Aggressive temp file cleanup

### What Doesn't Work
1. ❌ Removing `texlive-latex-extra` - Breaks templates
2. ❌ Removing `texlive-fonts-extra` - May break some font-dependent templates

### Alternative Approach

Keep `texlive-latex-extra` but optimize more aggressively:

```dockerfile
RUN apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    fontconfig \
    lmodern; \
  # Aggressive cleanup
  rm -rf /var/lib/apt/lists/* \
         /var/cache/apt/archives/* \
         /usr/share/doc/* \
         /usr/share/man/* \
         /usr/share/info/* \
         /usr/share/texlive/texmf-dist/doc/* \
         /usr/share/texlive/texmf-dist/source/* \
         /tmp/* \
         /var/tmp/*
```

**Expected savings: 100-150MB** (from cleanup only, not package removal)

## Next Steps

1. ✅ Re-add `texlive-latex-extra` to Dockerfile
2. ⏳ Rebuild with enhanced cleanup
3. ⏳ Test all template functionality
4. ⏳ Measure actual size difference
5. ⏳ Consider Phase 2: Multi-variant images
   - `pandoc:minimal` - No TeX Live (~250MB)
   - `pandoc:standard` - Core TeX (~600-800MB)
   - `pandoc:full` - Everything (~1.3-1.5GB)

## Lessons Learned

1. **Template dependencies are complex** - Cannot blindly remove TeX Live packages
2. **Documentation cleanup is safe** - `/usr/share/doc`, man pages can be removed
3. **Node.js cleanup is effective** - Removing test files, *.md, *.ts helps
4. **Image variants are the way forward** - Different use cases need different sizes
5. **Test early** - Always verify functionality after optimization

## Recommendations

- Accept that a full-featured image will be ~1.3-1.5GB
- Focus on creating smaller variants for specific use cases
- Document which variant to use for which purpose
- Optimize CI/CD to cache layers effectively
- Consider multi-stage builds for better separation
