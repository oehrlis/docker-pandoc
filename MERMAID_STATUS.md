# Mermaid Support - Implementation Status

**Date:** 2026-01-21  
**Status:** ✅ **WORKING** (with limitations documented)

## Summary

Mermaid diagram rendering is now functional in the docker-pandoc image. Diagrams are automatically converted to PNG images during document generation.

## ✅ What Works

### HTML Generation (Fully Functional)
```bash
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:test-chromium \
  test-mermaid.md -o output.html \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone
```

**Features:**
- ✅ Chromium 144.0.7559.59 installed
- ✅ mermaid-cli 11.12.0 installed  
- ✅ Automatic PNG rendering (transparent backgrounds)
- ✅ Hash-based caching (only re-renders if diagram changes)
- ✅ All Mermaid diagram types supported
- ✅ Output directory: `build/mermaid/`

**Test Results:**
- Generated 2 PNG images successfully:
  - Flowchart: 28KB
  - Sequence diagram: 44KB
- HTML file: 4.1KB with embedded image references

## ⚠️ Known Limitations

### 1. Docker Capability Required: `--cap-add=SYS_ADMIN`

**Why:**  
Chromium requires the ability to create user namespaces for its sandbox, even when running with `--no-sandbox` flags.

**Security Notes:**
- Container runs as non-root user (`pandoc`, uid 1000)
- Only Chromium process needs this capability
- Standard requirement for Puppeteer/Chromium in containers
- Alternative: `--security-opt seccomp=unconfined` (not recommended)

### 2. PDF Generation Not Available (Yet)

**Current Status:**  
The `test-chromium` image has Chromium and mermaid-cli but **not TeX Live**.

**Workaround:**  
A build is currently in progress (`oehrlis/pandoc:test-full`) that includes:
- Chromium (for Mermaid)
- TeX Live (for PDF generation)  
- Expected size: ~1.4GB+ (vs 808MB without TeX)

**Once available:**
```bash
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:test-full \
  document.md -o output.pdf \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --pdf-engine=xelatex
```

## Technical Details

### Architecture

**Mermaid Rendering Flow:**
1. Pandoc processes Markdown with `mermaid.lua` filter
2. Filter detects code blocks with `mermaid` class
3. Creates `.puppeteerrc.cjs` with Chromium config (`--no-sandbox`, etc.)
4. Calls `mmdc` (mermaid-cli) to render diagram to PNG
5. Uses SHA256 hash for filename (caching)
6. Replaces code block with image reference in output

**Key Components:**
- **Node.js:** 18.20.4 (from Debian repos)
- **mermaid-cli:** 11.12.0 (npm global install)
- **Chromium:** 144.0.7559.59 (Debian package)
- **Lua Filter:** `/usr/local/share/pandoc/filters/mermaid.lua`

### Files and Locations

```
/usr/bin/chromium                                  # Browser executable
/usr/local/bin/mmdc                                # Mermaid CLI
/usr/local/share/pandoc/filters/mermaid.lua        # Pandoc Lua filter
/workdir/build/mermaid/                            # Output directory (created automatically)
/workdir/.puppeteerrc.cjs                          # Chromium config (created by filter)
```

### Dockerfile Changes

**Added TeX Live Installation** (in progress):
```dockerfile
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    fontconfig \
    lmodern; \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
```

**Added Chromium Installation** (via Dockerfile.fix):
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        chromium chromium-sandbox \
        fonts-liberation fonts-noto-color-emoji \
        libnss3 libxss1 libasound2 \
        [... other Chromium dependencies ...]; \
    rm -rf /var/lib/apt/lists/*
```

## Documentation Updates

Updated files:
- ✅ [README.md](README.md) - Added Mermaid usage with `--cap-add=SYS_ADMIN`
- ✅ [MERMAID_CHROMIUM_FIX.md](MERMAID_CHROMIUM_FIX.md) - Complete working solution
- ✅ [MERMAID_QUICK_TEST.md](MERMAID_QUICK_TEST.md) - Quick reference commands
- ✅ [MERMAID_TEST_GUIDE.md](MERMAID_TEST_GUIDE.md) - Comprehensive testing guide

## Next Steps

### Immediate (In Progress)
- [x] Enable TeX Live in Dockerfile
- [x] Document `--cap-add=SYS_ADMIN` requirement  
- [ ] Wait for `test-full` build to complete
- [ ] Test full PDF generation with Mermaid
- [ ] Update Makefile with Mermaid test target

### Future Enhancements
- [ ] Investigate alternative to `--cap-add=SYS_ADMIN` (security)
- [ ] Add Mermaid examples to sample documents
- [ ] Consider pre-rendering diagrams in CI/CD for security-sensitive environments
- [ ] Add support for alternative diagram tools (PlantUML, Graphviz)
- [ ] Optimize image size (TeX Live adds ~1GB)

## Testing

### Verification Commands
```bash
# Check installations
docker run --rm --entrypoint chromium oehrlis/pandoc:test-chromium --version
docker run --rm --entrypoint mmdc oehrlis/pandoc:test-chromium --version

# Quick test (HTML)
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:test-chromium \
  test-mermaid.md -o test.html \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone
  
# Verify output
ls -lh test.html build/mermaid/*.png
open test.html
```

### Test Files
- [examples/test-mermaid.md](examples/test-mermaid.md) - Sample with flowchart and sequence diagram
- `build/mermaid/*.png` - Generated PNG diagrams

## Known Issues

### Resolved
- ✅ ~~Chromium not installed~~ - Fixed with Dockerfile.fix
- ✅ ~~Wrong Lua filter path~~ - Corrected to `/usr/local/share/pandoc/filters/mermaid.lua`
- ✅ ~~Namespace permission errors~~ - Fixed with `--cap-add=SYS_ADMIN`

### Pending
- ⚠️ PDF generation requires TeX Live (build in progress)
- ⚠️ `--cap-add=SYS_ADMIN` may not be acceptable in some security policies

## References

- **Mermaid Documentation:** https://mermaid.js.org/
- **mermaid-cli:** https://github.com/mermaid-js/mermaid-cli
- **Puppeteer in Docker:** https://pptr.dev/troubleshooting#running-puppeteer-in-docker
- **PR #23:** Added Mermaid support (merged 2026-01-21)

---

**Maintainer:** Stefan Oehrli (stefan.oehrli@oradba.ch)  
**Last Updated:** 2026-01-21
