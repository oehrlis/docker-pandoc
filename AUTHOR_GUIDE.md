# Author and User Guide
<!-- markdownlint-configure-file { "MD013": { "tables": false } } -->
<!-- markdownlint-configure-file { "MD024": { "allow_different_nesting": true } } -->

> **Note**: This guide incorporates advanced template documentation and best practices from the [oehrlis/pandoc_template](https://github.com/oehrlis/pandoc_template) repository. See the [References](#references) section for specific source citations.

This comprehensive guide covers authoring documents with the docker-pandoc image, including advanced template options, metadata configuration, formatting examples, and troubleshooting.

## Table of Contents

- [Quick Start](#quick-start)
- [Document Structure](#document-structure)
- [Markdown Syntax](#markdown-syntax)
- [Advanced Template Options](#advanced-template-options)
- [Document Metadata Configuration](#document-metadata-configuration)
- [Formatting and Extended Syntax](#formatting-and-extended-syntax)
- [Box Types and Custom Environments](#box-types-and-custom-environments)
- [Using Filters](#using-filters)
- [Output Formats](#output-formats)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Quick Start

The docker-pandoc image provides a complete Pandoc environment with LaTeX, custom templates, and fonts. Basic usage:

```bash
# Pull the image
docker pull oehrlis/pandoc

# Convert Markdown to PDF with default template
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf --toc --listings

# Use custom OraDBA template with XeLaTeX
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --template oradba \
  --pdf-engine=xelatex \
  --toc --listings
```

## Document Structure

### Recommended Folder Layout

This repository contains a couple of default folders. The language specific
folders are only a suggestion and have to be adapted or deleted accordingly.

- [sample](sample) - Sample documentation files and examples
- [images](images) - Images and logo files
- [templates](templates) - Custom Pandoc templates
- [themes](themes) - Presentation themes

The following Markdown files are generic files describing the repository,
authoring, contributing etc:

- [AUTHOR_GUIDE](AUTHOR_GUIDE.md) - This author's and user's guide
- [CHANGELOG](CHANGELOG.md) - Change log for docker-pandoc
- [LICENSE](LICENSE) - License information
- [VERSION](VERSION) - Current version number

### Multi-File Documents

> *Source: [pandoc_template/AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md)*

For larger documents, you can organize content across multiple Markdown files using a naming pattern `NxMM-Title.md`:

- **N** - Digit for the main chapter number
- **MM** - Two digits for sorting files within a main chapter
- **Title** - Descriptive name for the file content

**Important**: The prefix is crucial for proper file ordering during document build. Files without this prefix pattern will be ignored.

| Prefix | Chapter Purpose                                             |
|--------|-------------------------------------------------------------|
| `0x..` | Preface, Revision History and other general doc information |
| `1x..` | Introduction, management summary, scope, etc.               |
| `2x..` | Chapter 1 (will be TOC number 3)                            |
| `Nx..` | Good practice chapter N (will be TOC number N+2)            |
| `9x..` | Appendix files                                              |

Example file structure:

```
doc/
├── 0x01-Preface.md
├── 0x02-Revision_History.md
├── 1x01-Introduction.md
├── 2x01-Chapter_One.md
├── 2x02-Chapter_One_Part_Two.md
├── 3x01-Chapter_Two.md
├── 9x01-Appendix.md
└── metadata.yml
```

You can add as many files as you want. The prefix is used for sorting only; Pandoc creates the table of contents based on heading levels within the files (e.g., `#` creates a top-level heading).

## Markdown Syntax

> *Source: [pandoc_template/AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md) and [pandoc_template/examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md)*

### Basic Syntax

These are the core Markdown elements supported by all Pandoc templates:

#### Headings

```markdown
# This is an h1 heading
## This is an h2 heading
### This is an h3 heading
```

#### Emphasis

```markdown
*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_
```

#### Lists

Ordered lists:

```markdown
1. First item
2. Second item
3. Third item
```

Unordered lists:

```markdown
- First item
- Second item
- Third item
```

#### Links and Images

```markdown
[Link text](https://www.example.com)

![Image alt text](images/diagram.png)
```

#### Code

Inline code: `` `code` ``

Code blocks:

````markdown
```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc document.md -o output.pdf
```
````

#### Blockquotes

```markdown
> This is a blockquote
> It can span multiple lines
```

#### Horizontal Rules

```markdown
---
```

### Extended Syntax

> *Source: [pandoc_template/examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md)*

#### Tables

```markdown
| Syntax      | Description |
| ----------- | ----------- |
| Header      | Title       |
| Paragraph   | Text        |
```

#### Footnotes

```markdown
Here's a sentence with a footnote.[^1]

[^1]: This is the footnote text.
```

#### Definition Lists

```markdown
term
: definition text that can span
  multiple lines
```

#### Strikethrough

```markdown
~~This text is struck through~~
```

#### Task Lists

```markdown
- [x] Completed task
- [ ] Incomplete task
- [ ] Another task
```

### Markdownlint Configuration

> *Source: [pandoc_template/AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md)*

The Markdown syntax is validated using [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli). Any violation of the [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) will result in an error during CI/CD builds.

You can add exceptions either inline in files or in the global [.markdownlint.json](.markdownlint.json) configuration file.

#### Inline Exceptions

Ignore rule MD013 (line length) for tables:

```html
<!-- markdownlint-configure-file { "MD013": { "tables": false } } -->
```

Ignore rule MD013 completely in the current file:

```html
<!-- markdownlint-disable MD013 -->
```

Ignore rule MD024 (multiple headings with same content):

```html
<!-- markdownlint-configure-file { "MD024": { "allow_different_nesting": true } } -->
```

#### Global Configuration Example

Edit `.markdownlint.json`:

```json
{
  "default": true,
  "MD003": { "style": "atx_closed" },
  "MD007": { "indent": 4 },
  "MD013": { "tables": false },
  "no-hard-tabs": false,
  "whitespace": false
}
```

**Best Practice**: Install a Markdown linter in your editor (e.g., Markdownlint extension for Visual Studio Code) to catch issues before committing.

## Advanced Template Options

> *Source: [pandoc_template/README.md](https://github.com/oehrlis/pandoc_template/blob/master/README.md) and template source files*

The custom LaTeX templates (oradba, techdoc, trivadis) support extensive customization through metadata variables. These options extend Pandoc's [standard LaTeX variables](https://pandoc.org/MANUAL.html#variables-for-latex).

### Title Page Customization

Control the appearance of the title page:

```yaml
titlepage: true                           # Enable custom title page
titlepage-color: "D8DE2C"                 # Background color (HTML hex without #)
titlepage-text-color: "5F5F5F"            # Text color on title page
titlepage-rule-color: "435488"            # Color of top rule
titlepage-rule-height: 4                  # Height of top rule (in points)
title-color: "000000"                     # Document title color
subtitle-color: "A100FF"                  # Subtitle color
```

**Important**: Enclose color values in quotes to avoid YAML truncation (e.g., `000000` becoming `0`).

### Logo Configuration

> *Source: [pandoc_template/README.md - Logo section](https://github.com/oehrlis/pandoc_template/blob/master/README.md)*

The templates support company logos. Multiple options for specifying logos:

```yaml
# Single logo for all uses
logo: images/logo.eps
logo-width: 100                           # Logo width in points

# Specific logos for different purposes
titlepage-logo: images/logo-white.eps    # Logo on title page
footer-logo: images/logo-small.eps       # Logo in footer
```

**Via command line**:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --template oradba \
  -V logo=images/logo.eps
```

**Note**: The logo path is always relative to where Pandoc is executed. The `--resource-path` option has no effect on logo paths.

### Headers and Footers

Customize header and footer content:

```yaml
disable-header-and-footer: false          # Disable both header and footer
disable-header: false                     # Disable header only
disable-footer: false                     # Disable footer only

header-left: "Document Title"             # Left side of header (default: title)
header-center: "Section Name"             # Center of header
header-right: "2024-01-20"                # Right side of header (default: date)

footer-left: "Author Name"                # Left side of footer (default: author)
footer-center: "Confidential"             # Center of footer
footer-right: "Page \\thepage"            # Right side of footer (default: page number)
```

### Table of Contents

```yaml
toc: true                                 # Enable table of contents
toc-own-page: true                        # Start TOC on new page
toc-title: "Table of Contents"            # Custom TOC title
toc-depth: 2                              # Depth of headings to include (1-6)
```

### Lists of Figures and Tables

```yaml
lof: true                                 # List of figures
lof-own-page: false                       # Figures list on own page
lot: true                                 # List of tables
lot-own-page: true                        # Tables list on own page
```

### Code Listings

```yaml
listings: true                            # Enable listings package
listings-disable-line-numbers: true       # Disable line numbers
listings-no-page-break: true              # Prevent page breaks in code
code-block-font-size: \scriptsize         # Font size for code blocks
```

### Typography

```yaml
caption-justification: raggedright        # Caption alignment (uses caption package)
links-as-notes: false                     # Print links as footnotes
linkcolor: purple                         # Color for internal links
urlcolor: purple                          # Color for URLs
filecolor: purple                         # Color for file links
bulletcolor: black                        # Bullet point color
```

### Book Mode

> *Source: [pandoc_template/README.md - Typesetting a Book section](https://github.com/oehrlis/pandoc_template/blob/master/README.md)*

Typeset documents as books with chapter-level organization:

```yaml
book: true                                # Enable book mode
classoption: oneside                      # Use oneside (default: twoside with blank pages)
```

When using book mode:

1. Use `--top-level-division=chapter` to convert first-level headings to chapters
2. Default is two-sided (blank pages before chapters); use `oneside` for PDF-only

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o book.pdf \
  --template oradba \
  --top-level-division=chapter \
  -V book=true
```

### Page Layout

```yaml
papersize: a4                             # Paper size (a4, letter, etc.)
geometry:
  - top=2.54cm
  - bottom=2.54cm
  - left=2.54cm
  - right=2.54cm
```

### Language

> *Source: [pandoc_template/README.md - Changing Document Language](https://github.com/oehrlis/pandoc_template/blob/master/README.md)*

```yaml
lang: en-US                               # Main document language (BCP 47 code)
```

Supported languages include `en`, `en-GB`, `de`, `fr`, etc. See [hyph-utf8 documentation](http://mirrors.ctan.org/language/hyph-utf8/doc/generic/hyph-utf8/hyph-utf8.pdf) for the full list.

## Document Metadata Configuration

> *Sources: [pandoc_template/AUTHOR_GUIDE.md - Document Metadata](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md) and [pandoc_template/examples/complex/metadata.yml](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/metadata.yml)*

### Document Metadata

Pandoc document conversion can be configured using metadata in two ways:

1. **YAML metadata block** at the top of your Markdown file
2. **Separate YAML file** specified with `--metadata-file=metadata.yml`

Using a separate metadata file is recommended for complex documents or when using multiple source files.

### Complete Metadata Example

Here's a comprehensive metadata.yml example incorporating all advanced options:

```yaml
# ------------------------------------------------------------------------------
# Basic Document Information
# ------------------------------------------------------------------------------
title: "Complete Guide to Docker and Kubernetes"
subtitle: A comprehensive technical reference
author:
  - John Doe
  - Jane Smith
# date is set by pandoc automatically, uncomment to override
# date: 2024-01-20
version: 1.0.0
lang: en-US

# ------------------------------------------------------------------------------
# Organization/Company Information
# ------------------------------------------------------------------------------
# These variables can be customized per template
organization: "Acme Corporation"
department: "Cloud Infrastructure Team"
contact: "cloud-team@acme.com"
phone: "+1 555-123-4567"

# ------------------------------------------------------------------------------
# Book Settings
# ------------------------------------------------------------------------------
# book: true
# classoption: oneside                    # Use oneside for PDF (default is twoside)

# ------------------------------------------------------------------------------
# Page Settings
# ------------------------------------------------------------------------------
papersize: a4
geometry:
  - top=2.54cm
  - bottom=2.54cm
  - left=2.54cm
  - right=2.54cm

# ------------------------------------------------------------------------------
# Page Headers and Footers
# ------------------------------------------------------------------------------
disable-header: false
disable-footer: false
header-left: "Docker & Kubernetes Guide"
header-right: "Version 1.0.0"
footer-left: "Copyright © 2024 Acme Corp. All rights reserved."
footer-center: ""
footer-right: "Page \\thepage"

# ------------------------------------------------------------------------------
# Title Page
# ------------------------------------------------------------------------------
titlepage: true
titlepage-rule-height: 4
titlepage-rule-color: "435488"
titlepage-text-color: "000000"
titlepage-color: "FFFFFF"
title-color: "000000"
subtitle-color: "A100FF"

# ------------------------------------------------------------------------------
# Table of Contents
# ------------------------------------------------------------------------------
toc: true
toc-own-page: true
toc-title: "Table of Contents"
toc-depth: 3

# ------------------------------------------------------------------------------
# Lists of Tables and Figures
# ------------------------------------------------------------------------------
lof: true
lof-own-page: false
lot: true
lot-own-page: true

# ------------------------------------------------------------------------------
# Numbering and Links
# ------------------------------------------------------------------------------
numbersections: true
links-as-notes: false
linkcolor: purple
urlcolor: purple
filecolor: purple
bulletcolor: black

# ------------------------------------------------------------------------------
# Code Listings
# ------------------------------------------------------------------------------
listings: true
listings-disable-line-numbers: false
listings-no-page-break: true
code-block-font-size: \scriptsize

# ------------------------------------------------------------------------------
# Custom LaTeX Headers
# ------------------------------------------------------------------------------
header-includes: |
  \definecolor{purple}{HTML}{A100FF}
  \definecolor{lightgray}{HTML}{F5F5F5}

# ------------------------------------------------------------------------------
# Pandoc Filters and Extensions
# ------------------------------------------------------------------------------
# Define box environments for pandoc-latex-environment filter
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]

# ------------------------------------------------------------------------------
# Font Settings
# ------------------------------------------------------------------------------
# Generic fonts (works with most systems)
mainfont: Arial
sansfont: Arial
monofont: Courier New

# Custom fonts with paths (uncomment and adjust if needed)
# mainfont: Graphik-Regular.ttf
# mainfontoptions:
#   - Path=fonts/
#   - BoldFont=Graphik-Bold.ttf
#   - ItalicFont=Graphik-Regular-Italic.ttf
#   - BoldItalicFont=Graphik-Bold-Italic.ttf

# ------------------------------------------------------------------------------
# Logo Settings
# ------------------------------------------------------------------------------
# Path is relative to Pandoc execution directory
logo: images/company-logo.eps
logo-width: 100
titlepage-logo: images/logo-white.eps
footer-logo: images/logo-small.eps
```

### Minimal Metadata Example

For simple documents, a minimal metadata block is sufficient:

```yaml
---
title: "My Document"
author: "Your Name"
date: "2024-01-20"
toc: true
numbersections: true
---
```

### Using Metadata Files with Docker

```bash
# Using metadata file
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --listings --pdf-engine=xelatex \
  --resource-path=images \
  --output=document.pdf \
  *.md

# Using inline metadata block
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --template oradba \
  --toc --listings
```

## Formatting and Extended Syntax

This section is based on comprehensive examples from the pandoc_template repository.

## Box Types and Custom Environments

> *Source: [pandoc_template/examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md)*

The templates support colored boxes for highlighting important information using the [awesomebox](https://ctan.org/pkg/awesomebox) LaTeX package via the `pandoc-latex-environment` filter.

### Available Box Types

#### Note Box

```markdown
::: note
**Note** This is important information that readers should be aware of.
:::
```

::: note
**Note** The docker-pandoc image includes all necessary components for document
conversion. You can specify custom templates using the `--template` option, and
resources are resolved using the `--resource-path` parameter.
:::

#### Tip Box

```markdown
::: tip
**Tip** This is a helpful suggestion or best practice.
:::
```

::: tip
**Tip** Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam aliquet libero quis lectus elementum fermentum.
:::

#### Warning Box

```markdown
::: warning
**Warning** This is a warning about potential issues or risks.
:::
```

::: warning
**Warning** Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam aliquet libero quis lectus elementum fermentum.
:::

#### Caution Box

```markdown
::: caution
**Caution** This requires special attention or care.
:::
```

::: caution
**Caution** Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam aliquet libero quis lectus elementum fermentum.
:::

#### Important Box

```markdown
::: important
**Important** This is critical information that must not be missed.
:::
```

::: important
**Important** Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam aliquet libero quis lectus elementum fermentum.
:::

### Markdown Support in Boxes

Full Markdown formatting is supported inside boxes:

```markdown
::: important
**Lorem ipsum dolor** sit amet, `consectetur adipiscing` elit.

```java
if(args.length < 2) {
    System.out.println("Lorem ipsum dolor sit amet");
}
```

*Nam aliquet libero quis lectus elementum fermentum.*
:::
```

### Using Boxes with Pandoc

Boxes require the `pandoc-latex-environment` filter. Enable it in your metadata:

```yaml
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
  cautionblock: [caution]
  importantblock: [important]
```

And use the filter when building:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --listings --pdf-engine=xelatex \
  --resource-path=images \
  --filter pandoc-latex-environment \
  --output=document.pdf \
  doc/*.md
```

**Note**: Boxes are rendered in PDF/LaTeX output. In HTML/DOCX output, they appear as regular blockquotes or div elements.

## Using Filters

> *Sources: [pandoc_template/AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md) and [pandoc_template/examples/complex/README.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/README.md)*

Pandoc filters transform documents during conversion. The docker-pandoc image includes several pre-installed filters.

### Pandoc-LaTeX-Environment Filter

Enables custom LaTeX environments like colored boxes:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --filter pandoc-latex-environment \
  --metadata-file=metadata.yml
```

### Multiple Filters

Filters are applied in the order specified:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --filter pandoc-crossref \
  --filter pandoc-latex-environment \
  --template oradba
```

## Output Formats

> *Source: [pandoc_template/AUTHOR_GUIDE.md - Build Documentation](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md)*

The docker-pandoc image supports multiple output formats.

### PDF with Custom Template

Using the OraDBA template with XeLaTeX engine (recommended for custom fonts):

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --template oradba \
  --listings --pdf-engine=xelatex \
  --resource-path=images \
  --filter pandoc-latex-environment \
  --output=document.pdf \
  doc/?x??-*.md
```

**Options explained**:
- `--template oradba` - Use custom OraDBA LaTeX template
- `--pdf-engine=xelatex` - Use XeLaTeX (supports TrueType/OpenType fonts)
- `--resource-path=images` - Path for resolving images and resources
- `--filter pandoc-latex-environment` - Enable custom box environments
- `doc/?x??-*.md` - Process all files matching the pattern

### PDF with Standard Template

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --toc --listings -N
```

### DOCX (Microsoft Word)

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --reference-doc=templates/oradba.docx \
  --listings \
  --resource-path=images \
  --output=document.docx \
  doc/?x??-*.md
```

**Note**: Use `--reference-doc` to specify a custom DOCX template with your styles.

### PPTX (PowerPoint)

Generate presentations from selected chapters:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --reference-doc=templates/pandoc_reference.pptx \
  --listings \
  --resource-path=images \
  --output=presentation.pptx \
  doc/[1-8]x??-*.md
```

### HTML

Standalone HTML document:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  -s --toc \
  --template=GitHub.html5 \
  --resource-path=images \
  --output=document.html \
  doc/?x??-*.md
```

### EPUB (eBook)

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --resource-path=images \
  --output=document.epub \
  doc/?x??-*.md
```

### LaTeX Source

Generate standalone LaTeX for further editing:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  --metadata-file=metadata.yml \
  --template oradba \
  --listings \
  --resource-path=images \
  --output=document.tex \
  document.md
```

## Troubleshooting

> *Sources: Multiple sections from [pandoc_template](https://github.com/oehrlis/pandoc_template) repository*

### Common Issues and Solutions

#### Resource Path and Images

**Problem**: Images not found during PDF generation

**Solution**: Always specify `--resource-path` to tell Pandoc where to find images:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --resource-path=images \
  --resource-path=doc/images
```

You can specify multiple resource paths. Pandoc searches them in order.

**Container Context**: When using Docker, ensure your images are within the mounted volume (`/workdir`). Images outside the mounted directory cannot be accessed.

#### Missing Logos

**Problem**: LaTeX compilation fails with "File `logo.eps` not found"

**Solutions**:

1. **Provide logo in expected location**:
   ```bash
   mkdir -p images
   cp /path/to/logo.eps images/
   ```

2. **Specify logo in metadata**:
   ```yaml
   logo: images/company-logo.eps
   ```

3. **Use command-line variable**:
   ```bash
   docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
     document.md -o output.pdf \
     --template oradba \
     -V logo=images/logo.eps
   ```

#### Font Issues

**Problem**: Font warnings or incorrect fonts in PDF

**Root Cause**: Missing fonts or incorrect font names in metadata

**Solutions**:

1. **Use standard fonts**:
   ```yaml
   mainfont: Arial
   sansfont: Arial
   monofont: Courier New
   ```

2. **Verify font availability** in container:
   ```bash
   docker run --rm oehrlis/pandoc fc-list | grep Arial
   ```

3. **Use custom fonts with correct paths**:
   ```yaml
   mainfont: CustomFont-Regular.ttf
   mainfontoptions:
     - Path=fonts/
     - BoldFont=CustomFont-Bold.ttf
   ```

   Ensure fonts are in the mounted volume.

#### Template Not Found

**Problem**: "Template not found: custom_template"

**Solutions**:

1. **Use built-in templates** by name:
   ```bash
   --template oradba
   --template techdoc
   --template trivadis
   ```

2. **Provide template path explicitly**:
   ```bash
   --template=/workdir/templates/custom.tex
   ```

3. **Verify template exists** in container:
   ```bash
   docker run --rm oehrlis/pandoc ls -la /oradba/templates/
   ```

#### Mounting Issues with Docker

**Problem**: Permission denied when writing output files

**Root Cause**: Container runs as uid/gid 1000, but host files have different ownership

**Solutions**:

1. **Fix file ownership** on host:
   ```bash
   sudo chown -R 1000:1000 /path/to/documents
   ```

2. **Use SELinux-compatible mount** (`:z` flag):
   ```bash
   docker run --rm -v $PWD:/workdir:z oehrlis/pandoc [...]
   ```

3. **Run as root** (not recommended for security):
   ```bash
   docker run --rm --user root -v $PWD:/workdir:z oehrlis/pandoc [...]
   ```

#### Box Environments Not Rendering

**Problem**: Box syntax (`::: note`) appears as plain text in PDF

**Root Cause**: Missing `pandoc-latex-environment` filter

**Solution**: Add the filter and metadata configuration:

```yaml
# In metadata.yml
pandoc-latex-environment:
  noteblock: [note]
  tipblock: [tip]
  warningblock: [warning]
```

```bash
# In command line
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --filter pandoc-latex-environment \
  --metadata-file=metadata.yml
```

#### LaTeX Compilation Errors

**Problem**: LaTeX errors during PDF generation

**Common Causes and Solutions**:

1. **Special characters**: Escape LaTeX special characters (`#`, `$`, `%`, `&`, `_`, `{`, `}`)
2. **Long lines**: Use `--wrap=auto` or break long URLs
3. **Complex tables**: Simplify table structure or use `longtable`
4. **Missing packages**: Rebuild Docker image if custom LaTeX packages are needed

**Debug mode**: Add `--verbose` to see detailed LaTeX errors:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf \
  --verbose
```

#### Multiple Source Files Order

**Problem**: Chapters appear in wrong order

**Solution**: Use file naming pattern `NxMM-Title.md` and wildcard expansion:

```bash
# Correct: sorts files alphanumerically
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  doc/?x??-*.md -o output.pdf

# Files will be processed in order: 0x01, 0x02, 1x01, 1x02, 2x01, etc.
```

#### Syntax Highlighting Not Working

**Problem**: Code blocks appear without syntax highlighting

**Solutions**:

1. **Enable listings**:
   ```bash
   --listings
   ```
   Or in metadata:
   ```yaml
   listings: true
   ```

2. **Specify language** in code blocks:
   ````markdown
   ```python
   def hello():
       print("Hello, World!")
   ```
   ````

3. **Use Pandoc's highlighting**:
   ```bash
   --highlight-style=pygments
   ```

### Getting Help

If you encounter issues not covered here:

1. **Check Pandoc documentation**: <https://pandoc.org/MANUAL.html>
2. **Review template source**: [oehrlis/docker-pandoc templates](https://github.com/oehrlis/docker-pandoc/tree/main/templates)
3. **Consult LaTeX documentation**: <https://www.latex-project.org/help/documentation/>
4. **File an issue**: <https://github.com/oehrlis/docker-pandoc/issues>

## References

This guide incorporates content and best practices from multiple sources:

### Primary Sources

- **oehrlis/pandoc_template Repository**: <https://github.com/oehrlis/pandoc_template>
  - [README.md](https://github.com/oehrlis/pandoc_template/blob/master/README.md) - Template usage and configuration
  - [AUTHOR_GUIDE.md](https://github.com/oehrlis/pandoc_template/blob/master/AUTHOR_GUIDE.md) - Document structure and authoring
  - [examples/complex/README.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/README.md) - Complex document examples
  - [examples/complex/doc/3x00-Author_Guide.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/3x00-Author_Guide.md) - Extended authoring guide
  - [examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md) - Comprehensive formatting examples
  - [examples/complex/metadata.yml](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/metadata.yml) - Complete metadata example

### LaTeX Templates

- [templates/oradba.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/oradba.tex) - OraDBA template
- [templates/techdoc.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/techdoc.tex) - Technical documentation template
- [templates/trivadis.tex](https://github.com/oehrlis/pandoc_template/blob/master/templates/trivadis.tex) - Trivadis corporate template

### External Documentation

- [Pandoc User's Guide](https://pandoc.org/MANUAL.html)
- [Pandoc LaTeX Variables](https://pandoc.org/MANUAL.html#variables-for-latex)
- [Markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Awesomebox Package](https://ctan.org/pkg/awesomebox)
- [Pandoc-LaTeX-Environment Filter](https://github.com/chdemko/pandoc-latex-environment)

---

*Last updated: 2024-01-20*
