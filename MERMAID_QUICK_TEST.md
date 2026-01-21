# Quick Mermaid Test

## ✅ Working Configuration (Updated)

**Requirements:**
- Docker with `--cap-add=SYS_ADMIN` capability  
- Image: `oehrlis/pandoc:latest` (with Chromium + TeX Live)

## 1. Build Image (Choose One)

```bash
# Option A: Use make
cd /Users/stefan.oehrli/Development/github/oehrlis/docker-pandoc
make build

# Option B: Direct Docker build
docker build -t oehrlis/pandoc:test .
```

**Build time:** ~15-20 minutes (Node.js + TeX Live packages)

## 2. Verify Installations

```bash
# Check mermaid-cli
docker run --rm --entrypoint mmdc oehrlis/pandoc:test --version
# Expected: 11.12.0

# Check Chromium
docker run --rm --entrypoint chromium oehrlis/pandoc:test --version
# Expected: Chromium 144.0.7559.59

# Check XeLaTeX
docker run --rm --entrypoint xelatex oehrlis/pandoc:test --version
# Expected: XeTeX 3.141592653...
```

## 3. Test Mermaid Rendering

### HTML Output (Fast Test)
```bash
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:test \
  test-mermaid.md -o test-mermaid.html \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone

open test-mermaid.html
```

### PDF Output (Full Test)
```bash
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:test \
  test-mermaid.md -o test-mermaid.pdf \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --pdf-engine=xelatex

open test-mermaid.pdf
```

## Expected Results

✅ **Success**: 
- Two PNG diagrams generated in `build/mermaid/`
- Console shows: "Rendering Mermaid diagram: 0a346e94...png"
- PDF/HTML contains embedded diagram images

## Common Issues

### ❌ "Failed to move to new namespace: Operation not permitted"
→ **Fix**: Add `--cap-add=SYS_ADMIN` to docker run command

### ❌ "Chromium not found"
→ **Fix**: Rebuild image (Chromium installation may have failed)

### ❌ "xelatex not found"  
→ **Fix**: Ensure TeX Live installed (texlive-xetex package)

### ⚠️ Build hangs at Node.js
→ Normal: 387 packages take 10-15 minutes
→ **Fix**: Wait or check network connection

## Full Test Guide

See [MERMAID_TEST_GUIDE.md](MERMAID_TEST_GUIDE.md) for comprehensive troubleshooting.
