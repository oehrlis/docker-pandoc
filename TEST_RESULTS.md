# Docker Image Optimization Test Results

## Build Command
```bash
docker build -t oehrlis/pandoc:optimized .
```

## Size Comparison

### Before Optimization
- `oehrlis/pandoc:test` - 808MB (Mermaid, no TeX)
- `oehrlis/pandoc:test-chromium` - 1.42GB (with Chromium)
- `oehrlis/pandoc:4.0.0` - 2.83GB (full TeX Live)

### After Optimization
- `oehrlis/pandoc:optimized` - **TBD**

## Expected Savings
- TeX Live: ~200-300MB (latex-extra → latex-recommended, removed docs)
- Node.js: ~50-100MB (cleaned node_modules, removed unnecessary files)
- Total: ~250-400MB

## Functionality Tests

### 1. Basic Pandoc Conversion
```bash
# Test Markdown to HTML
echo "# Test" | docker run --rm -i oehrlis/pandoc:optimized -f markdown -t html
```
**Expected:** HTML output with `<h1>Test</h1>`

### 2. PDF Generation with TeX Live
```bash
# Test PDF generation
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc:optimized \
  sample.md -o test-output.pdf --pdf-engine=xelatex
```
**Expected:** PDF file created successfully

### 3. Font Rendering
```bash
# Test with custom fonts
docker run --rm -v $PWD/sample:/workdir:z oehrlis/pandoc:optimized \
  sample.md -o test-fonts.pdf \
  --pdf-engine=xelatex \
  --template=oradba
```
**Expected:** PDF with proper font rendering (Open Sans, etc.)

### 4. Mermaid Rendering (if Chromium installed)
```bash
cd examples
docker run --rm --cap-add=SYS_ADMIN -v $PWD:/workdir:z oehrlis/pandoc:optimized \
  test-mermaid.md -o test-optimized.html \
  --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
  --standalone
```
**Expected:** HTML with rendered Mermaid diagrams

## Verification Checklist

- [ ] Image builds successfully without errors
- [ ] Image size reduced compared to previous versions
- [ ] Pandoc version is correct
- [ ] Can convert Markdown to HTML
- [ ] Can generate PDF with XeLaTeX
- [ ] Templates work (oradba.tex)
- [ ] Fonts render correctly
- [ ] Mermaid rendering works (if applicable)
- [ ] No functionality regressions

## Test Results

### Build Output
```
[Results will be added after build completes]
```

### Size Comparison
```
[Will add docker images output]
```

### Functionality Tests
```
[Results will be added after testing]
```

## Conclusion

**Optimization Success:** TBD  
**Size Reduction:** TBD  
**Functionality Status:** TBD

## Next Steps

Based on results:
- [ ] If successful: Tag as oehrlis/pandoc:latest
- [ ] Update CHANGELOG with actual size reduction
- [ ] Proceed with Phase 2 (image variants)
- [ ] If issues: Debug and adjust optimization strategy
