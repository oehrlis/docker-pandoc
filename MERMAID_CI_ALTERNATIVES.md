# Mermaid in CI/CD - Alternatives to --cap-add=SYS_ADMIN

## The Problem

Mermaid diagram rendering requires Chromium, which needs `--cap-add=SYS_ADMIN` for namespace creation. This poses security concerns in CI/CD environments:

- **Security Risk**: SYS_ADMIN grants extensive privileges
- **GitHub Actions**: While technically possible, not recommended
- **Enterprise CI**: Often blocked by security policies
- **Audit Compliance**: May violate security requirements

## Solution 1: Pre-render Diagrams in CI (Recommended)

Instead of rendering during document generation, pre-render diagrams as a separate CI step.

### Implementation

```yaml
# .github/workflows/ci.yml
jobs:
  render-diagrams:
    name: Pre-render Mermaid Diagrams
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install mermaid-cli
        run: npm install -g @mermaid-js/mermaid-cli
      
      - name: Install Chromium
        run: |
          sudo apt-get update
          sudo apt-get install -y chromium-browser
      
      - name: Pre-render all Mermaid diagrams
        run: |
          mkdir -p build/mermaid
          find . -name "*.md" -exec grep -l "```mermaid" {} \; | while read file; do
            # Extract mermaid blocks and render
            awk '/```mermaid/,/```/' "$file" | \
              mmdc -i - -o "build/mermaid/$(basename $file .md).png" \
                --puppeteerConfigFile puppeteer-config.json || true
          done
      
      - name: Upload diagram artifacts
        uses: actions/upload-artifact@v4
        with:
          name: mermaid-diagrams
          path: build/mermaid/*.png
      
      - name: Commit pre-rendered diagrams
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add build/mermaid/*.png
          git commit -m "chore: pre-render mermaid diagrams" || true
          git push || true
```

**Puppeteer config** (`puppeteer-config.json`):
```json
{
  "headless": "new",
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu"
  ]
}
```

## Solution 2: Use Kroki Service (No Chromium Needed)

Kroki is a unified API for diagram generation that runs as a service.

### Option A: Public Kroki Instance

```yaml
jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate PDF with Kroki
        run: |
          docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
            document.md -o output.pdf \
            --filter pandoc-kroki \
            --pdf-engine=xelatex
        env:
          KROKI_SERVER_URL: https://kroki.io
```

### Option B: Self-hosted Kroki (More Secure)

```yaml
services:
  kroki:
    image: yuzutech/kroki:latest
    ports:
      - 8000:8000

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    services:
      kroki:
        image: yuzutech/kroki:latest
        ports:
          - 8000:8000
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate PDF
        run: |
          docker run --rm --network host -v $PWD:/workdir:z oehrlis/pandoc \
            document.md -o output.pdf \
            --filter pandoc-kroki \
            --pdf-engine=xelatex
        env:
          KROKI_SERVER_URL: http://localhost:8000
```

## Solution 3: Use GitHub Actions with SYS_ADMIN (Not Recommended)

⚠️ **Use only for testing, not production**

```yaml
jobs:
  generate-docs-unsafe:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate PDF with Mermaid (UNSAFE)
        run: |
          docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc \
            document.md -o output.pdf \
            --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
            --pdf-engine=xelatex
```

**Why not recommended:**
- Security audit flags
- Violates principle of least privilege
- May be blocked by organization policies
- Creates security vulnerability if container is compromised

## Solution 4: Use Mermaid.ink (Simplest)

Mermaid.ink is a free service that renders diagrams via URL.

```markdown
<!-- In your markdown -->
![Flowchart](https://mermaid.ink/img/<base64-encoded-diagram>)
```

### Pandoc Filter for mermaid.ink

Create `mermaid-ink-filter.lua`:
```lua
function CodeBlock(block)
  if block.classes[1] == "mermaid" then
    local code = block.text
    local base64 = pandoc.pipe("base64", {"-w", "0"}, code)
    local url = "https://mermaid.ink/img/" .. base64
    return pandoc.Para{pandoc.Image("", url)}
  end
end
```

**Usage:**
```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --lua-filter mermaid-ink-filter.lua
```

No Chromium, no SYS_ADMIN needed!

## Solution 5: Conditional Rendering

Skip Mermaid rendering in CI, use static images in production.

### Implementation

```yaml
jobs:
  build-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate PDF (skip Mermaid in CI)
        run: |
          docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
            document.md -o output.pdf \
            --pdf-engine=xelatex
        # Note: No --lua-filter, diagrams won't render
      
      - name: Note about diagrams
        run: |
          echo "⚠️ Mermaid diagrams skipped in CI build"
          echo "📝 For full rendering, build locally with --cap-add=SYS_ADMIN"
```

## Comparison Matrix

| Solution | Security | Complexity | Diagram Quality | Offline Support |
|----------|----------|------------|-----------------|-----------------|
| **Pre-render in CI** | ✅ High | Medium | ✅ Excellent | ✅ Yes |
| **Kroki (self-hosted)** | ✅ High | High | ✅ Excellent | ✅ Yes |
| **Kroki (public)** | ⚠️ Medium | Low | ✅ Excellent | ❌ No |
| **mermaid.ink** | ⚠️ Medium | Low | ⚠️ Good | ❌ No |
| **SYS_ADMIN** | ❌ Low | Low | ✅ Excellent | ✅ Yes |
| **Skip in CI** | ✅ High | Low | ❌ None | ✅ Yes |

## Recommended Approach

### For Open Source Projects
**Use Pre-rendering** (Solution 1)
- Commit rendered PNGs to repository
- CI verifies diagrams are up-to-date
- No security concerns

### For Enterprise/Private Repos
**Use Self-hosted Kroki** (Solution 2B)
- No external dependencies
- No elevated privileges
- Scales well

### For Quick Testing
**Use mermaid.ink** (Solution 4)
- Simplest implementation
- Good for prototypes
- External dependency acceptable

## Implementation Steps

### 1. Update Lua Filter for Conditional Rendering

Modify `mermaid.lua` to support fallback:

```lua
-- At top of file
local USE_KROKI = os.getenv("MERMAID_USE_KROKI")
local KROKI_URL = os.getenv("KROKI_SERVER_URL") or "https://kroki.io"
local SKIP_RENDERING = os.getenv("MERMAID_SKIP_RENDERING")

function render_mermaid(code, output_path)
  if SKIP_RENDERING == "true" then
    io.stderr:write("⚠️ Skipping Mermaid rendering (MERMAID_SKIP_RENDERING=true)\n")
    return false
  end
  
  if USE_KROKI == "true" then
    return render_via_kroki(code, output_path)
  else
    return render_via_mmdc(code, output_path)
  end
end
```

### 2. Update Documentation

Add to README.md:

```markdown
## CI/CD Considerations

For security reasons, Mermaid rendering requires `--cap-add=SYS_ADMIN` which
may not be acceptable in CI/CD environments.

**Recommended alternatives:**
1. Pre-render diagrams in CI as a separate step
2. Use Kroki service (self-hosted or public)
3. Use mermaid.ink for simple diagrams

See [MERMAID_CI_ALTERNATIVES.md](MERMAID_CI_ALTERNATIVES.md) for details.
```

### 3. Add CI Workflow

Create `.github/workflows/mermaid-prerender.yml`:

```yaml
name: Pre-render Mermaid Diagrams

on:
  push:
    paths:
      - '**.md'
      - '**/mermaid/**'

jobs:
  render:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install mermaid-cli
        run: npm install -g @mermaid-js/mermaid-cli
      
      - name: Render diagrams
        run: |
          # Add your rendering script here
          
      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: "chore: update rendered mermaid diagrams"
          file_pattern: "build/mermaid/*.png"
```

## Conclusion

For production CI/CD pipelines, **avoid `--cap-add=SYS_ADMIN`**. Use:

1. **Pre-rendering** for committed diagrams
2. **Kroki** for on-demand rendering
3. **mermaid.ink** for simple use cases

Only use `--cap-add=SYS_ADMIN` for local development and testing.

---

**Related Documentation:**
- [MERMAID_STATUS.md](MERMAID_STATUS.md) - Current implementation
- [MERMAID_TEST_GUIDE.md](MERMAID_TEST_GUIDE.md) - Testing guide
- [README.md](README.md) - Main documentation
