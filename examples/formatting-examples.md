# Formatting Examples
<!-- markdownlint-configure-file { "MD013": { "tables": false } } -->
<!-- markdownlint-configure-file { "MD024": { "allow_different_nesting": true } } -->

> **Source**: This document is based on [oehrlis/pandoc_template/examples/complex/doc/4x00-Formatting_Examples.md](https://github.com/oehrlis/pandoc_template/blob/master/examples/complex/doc/4x00-Formatting_Examples.md)

This document demonstrates the full range of Markdown formatting supported by the docker-pandoc templates.

## Basic Syntax

### Headings

Create headings using `#` symbols. The number of `#` determines the heading level:

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

### Emphasis

```markdown
*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_
```

Result:

*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_

### Lists

#### Ordered Lists

```markdown
1. First item
2. Second item
3. Third item
   1. Nested item
   2. Another nested item
```

Result:

1. First item
2. Second item
3. Third item
   1. Nested item
   2. Another nested item

#### Unordered Lists

```markdown
- First item
- Second item
- Third item
  - Nested item
  - Another nested item
```

Result:

- First item
- Second item
- Third item
  - Nested item
  - Another nested item

### Blockquotes

```markdown
> This is a blockquote.
> It can span multiple lines.
>
> And have multiple paragraphs.
```

Result:

> This is a blockquote.
> It can span multiple lines.
>
> And have multiple paragraphs.

### Code

Inline code: `` `code` ``

Result: `code`

Code blocks with syntax highlighting:

````markdown
```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf --toc
```
````

Result:

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  document.md -o output.pdf --toc
```

### Horizontal Rules

```markdown
---
```

Result:

---

### Links

```markdown
[Link text](https://www.example.com)
[Link with title](https://www.example.com "Title text")
```

Result:

[Link text](https://www.example.com)
[Link with title](https://www.example.com "Title text")

### Images

```markdown
![Alt text](path/to/image.png)
![Alt text with title](path/to/image.png "Image title")
```

## Extended Syntax

### Tables

```markdown
| Syntax      | Description | Test Text     |
| :---------- | :---------: | ------------: |
| Header      | Title       | Here's this   |
| Paragraph   | Text        | And more      |
| Left-align  | Center      | Right-align   |
```

Result:

| Syntax      | Description | Test Text     |
| :---------- | :---------: | ------------: |
| Header      | Title       | Here's this   |
| Paragraph   | Text        | And more      |
| Left-align  | Center      | Right-align   |

### Fenced Code Blocks with Language

````markdown
```python
def hello_world():
    print("Hello, World!")
    return 0

if __name__ == "__main__":
    hello_world()
```
````

Result:

```python
def hello_world():
    print("Hello, World!")
    return 0

if __name__ == "__main__":
    hello_world()
```

### Footnotes

```markdown
Here's a sentence with a footnote.[^1]

[^1]: This is the footnote text.
```

Result:

Here's a sentence with a footnote.[^1]

[^1]: This is the footnote text.

### Definition Lists

```markdown
Term 1
: Definition 1

Term 2
: Definition 2a
: Definition 2b
```

Result:

Term 1
: Definition 1

Term 2
: Definition 2a
: Definition 2b

### Strikethrough

```markdown
~~The world is flat.~~
```

Result:

~~The world is flat.~~

### Task Lists

```markdown
- [x] Write the documentation
- [x] Add examples
- [ ] Review and publish
- [ ] Get feedback
```

Result:

- [x] Write the documentation
- [x] Add examples
- [ ] Review and publish
- [ ] Get feedback

## Box Types (Requires pandoc-latex-environment filter)

> **Important**: These boxes require the `--filter pandoc-latex-environment` option and proper metadata configuration. See [AUTHOR_GUIDE.md](../AUTHOR_GUIDE.md#box-types-and-custom-environments) for details.

### Note Box

```markdown
::: note
**Note** This is important information that readers should be aware of.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::
```

::: note
**Note** This is important information that readers should be aware of.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::

### Tip Box

```markdown
::: tip
**Tip** This is a helpful suggestion or best practice.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::
```

::: tip
**Tip** This is a helpful suggestion or best practice.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::

### Warning Box

```markdown
::: warning
**Warning** This is a warning about potential issues or risks.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::
```

::: warning
**Warning** This is a warning about potential issues or risks.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::

### Caution Box

```markdown
::: caution
**Caution** This requires special attention or care.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::
```

::: caution
**Caution** This requires special attention or care.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::

### Important Box

```markdown
::: important
**Important** This is critical information that must not be missed.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::
```

::: important
**Important** This is critical information that must not be missed.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
:::

### Boxes with Rich Content

Markdown formatting is fully supported inside boxes:

```markdown
::: important
**Lorem ipsum dolor** sit amet, `consectetur adipiscing` elit.

```java
if(args.length < 2) {
    System.out.println("Important code example");
}
```

*Nam aliquet libero quis lectus elementum fermentum.*

- Item 1
- Item 2
:::
```

::: important
**Lorem ipsum dolor** sit amet, `consectetur adipiscing` elit.

```java
if(args.length < 2) {
    System.out.println("Important code example");
}
```

*Nam aliquet libero quis lectus elementum fermentum.*

- Item 1
- Item 2
:::

## Building This Document

### PDF with Boxes

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  examples/formatting-examples.md \
  -o formatting-examples.pdf \
  --template oradba \
  --pdf-engine=xelatex \
  --filter pandoc-latex-environment \
  --toc \
  --listings
```

### DOCX

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  examples/formatting-examples.md \
  -o formatting-examples.docx \
  --reference-doc=templates/oradba.docx \
  --toc
```

### HTML

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc \
  examples/formatting-examples.md \
  -o formatting-examples.html \
  --template=GitHub.html5 \
  --standalone \
  --toc
```

## References

- [Pandoc Manual](https://pandoc.org/MANUAL.html)
- [Markdown Guide](https://www.markdownguide.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)
- [Awesomebox Package](https://ctan.org/pkg/awesomebox)
- [pandoc-latex-environment](https://github.com/chdemko/pandoc-latex-environment)

---

*This document demonstrates formatting supported by docker-pandoc templates. For more information, see [AUTHOR_GUIDE.md](../AUTHOR_GUIDE.md).*
