# Add Mermaid Diagram Support

## Summary

Implement Mermaid diagram rendering support in the Docker image. The previous implementation using `mermaid-cli` (Chromium-based) was removed due to incompatibility with Docker's security model when running as a non-root user.

## Problem

Chromium-based rendering fails in Docker containers with non-root users due to sandbox namespace restrictions:
```
Error: Failed to launch the browser process!
Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted
```

This is a fundamental Docker security limitation, not a configuration issue.

## Proposed Solutions

### Option 1: Kroki Integration (Recommended)

**Approach**: Replace `mermaid-filter` with Kroki-based pandoc filter

**Advantages**:
- ✅ No browser/Chromium needed
- ✅ Works in container without security compromises
- ✅ Supports multiple diagram types (Mermaid, PlantUML, GraphViz, etc.)
- ✅ Can be self-hosted or use public service
- ✅ CI/CD friendly

**Implementation**:
1. Install `pandoc-kroki-filter` or create custom filter
2. Add Kroki server URL configuration (environment variable)
3. Provide docker-compose example for self-hosted Kroki
4. Update documentation with usage examples

**Self-hosted Setup**:
```yaml
services:
  kroki:
    image: yuzutech/kroki
    ports:
      - "8000:8000"
  pandoc:
    image: oehrlis/pandoc
    environment:
      - KROKI_URL=http://kroki:8000
```

### Option 2: Playwright with Alternative Backend

**Approach**: Replace Puppeteer with Playwright using non-Chromium backend

**Advantages**:
- ✅ Maintains mermaid-cli compatibility
- ✅ Might have better container support

**Disadvantages**:
- ❌ Still requires browser
- ❌ May face similar namespace restrictions
- ❌ Larger image size

### Option 3: Pre-rendering Workflow

**Approach**: Provide scripts for pre-rendering diagrams outside the container

**Advantages**:
- ✅ No container changes needed
- ✅ Works for CI/CD pipelines

**Disadvantages**:
- ❌ Requires two-step process
- ❌ Complicates workflow
- ❌ Users need mermaid-cli on host

### Option 4: PlantUML/Graphviz as Alternative

**Approach**: Promote alternative diagram tools that work in containers

**Advantages**:
- ✅ Proven to work in containers
- ✅ Java/C based (no browser needed)

**Disadvantages**:
- ❌ Different syntax from Mermaid
- ❌ Users need to migrate diagrams

## Recommended Approach

**Primary**: Implement Kroki integration (Option 1)
- Best balance of functionality and security
- Supports multiple diagram formats
- Self-hostable for offline/private use

**Secondary**: Document alternative tools (Option 4)
- Provide migration guides from Mermaid to PlantUML
- Include examples in documentation

## Implementation Checklist

- [ ] Research and test `pandoc-kroki-filter` compatibility
- [ ] Add Kroki filter installation to Dockerfile
- [ ] Create docker-compose example with Kroki service
- [ ] Update README with Kroki usage examples
- [ ] Add DEVELOPMENT.md section on diagram rendering
- [ ] Create sample diagrams in `examples/` directory
- [ ] Test in CI/CD environment (GitHub Actions)
- [ ] Update CHANGELOG with new feature
- [ ] Remove deprecated Mermaid limitation warnings

## Related

- Issue created after removing mermaid-cli in commit: [commit hash]
- Documentation: [DEVELOPMENT.md](../DEVELOPMENT.md#chromiummermaid-crashes)
- Kroki project: https://kroki.io
- Kroki GitHub: https://github.com/yuzutech/kroki

## Testing Plan

1. **Local development**: Test with docker-compose setup
2. **CI/CD**: Add GitHub Actions workflow with Kroki service
3. **Self-hosted**: Verify private Kroki server setup
4. **Public service**: Test with kroki.io (with fallback for network failures)

## Breaking Changes

None - this adds new functionality. Users currently cannot render Mermaid diagrams, so this is purely additive.

## Documentation Updates

- [ ] README.md - Add Kroki usage section
- [ ] DEVELOPMENT.md - Document Kroki setup for local development
- [ ] .github/workflows/ - Add example workflow with Kroki
- [ ] examples/ - Add sample documents with various diagram types

## Alternative Resources

- Kroki documentation: https://docs.kroki.io
- PlantUML syntax: https://plantuml.com
- Graphviz documentation: https://graphviz.org
- TikZ examples: https://texample.net/tikz/
