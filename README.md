<!-- badges: start -->

<!-- For more info: https://usethis.r-lib.org/reference/badges.html -->

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

# fws-report

> Unofficial template; not an official FWS publication standard.

## Overview

A Quarto **PDF, DOCX, and HTML format** extension that provides an unofficial U.S. Fish and Wildlife Service (FWS) report layout.

What you get:

- Cover page with banner, title, authors, cover image + credit
- “How to cite this report” page
- Running headers and Word-like heading styles
- Citeproc bibliography under `# References`
- Support for rendering the same report as PDF, DOCX, or HTML

### Example output

Rendered PDF cover page:

<img src="images/cover_page.png" alt="Example fws-report PDF cover page showing the FWS banner, report number, multi-line title, authors, and cover photo with credit" width="800">

## Usage

### Installing the extension

Depending on your use case, here are some [Quarto CLI](https://quarto.org/)
commands to get started.

If you would like to add the fws-report extension to an existing directory:

```bash
# In the Terminal:

quarto add USFWS/fws-report
# or
quarto install extension USFWS/fws-report
```

Alternatively, you can use a [Quarto template](https://quarto.org/docs/extensions/starter-templates.html) that bundles the fws-report format plus a starter .qmd document. This is a better
option if you are starting a new project from scratch, since it will automatically
create a new directory with all of the necessary scaffolding in one go.

```bash
# In the Terminal:

quarto use template USFWS/fws-report
```

### Rendering to a PDF

```yaml
---
title: "My Report Title"
author:
  - "First Last"
year: 2026
report-number: "01"
cover-image: "images/cover.jpg"

format:
  fws-report-pdf: default
---
```

### Rendering to a DOCX

```yaml
---
title: "My Report Title"
author:
  - "First Last"
year: 2026
report-number: "01"
cover-image: "images/cover.jpg"

format:
  fws-report-docx: default
---
```

### Rendering to an HTML

```yaml
---
title: "My Report Title"
author:
  - "First Last"
year: 2026
report-number: "01"
cover-image: "images/cover.jpg"

format:
  fws-report-html: default
---
```

### Rendering to a PDF, DOCX, and HTML

```yaml
---
title: "My Report Title"
author:
  - "First Last"
year: 2026
report-number: "01"
cover-image: "images/cover.jpg"

format:
  fws-report-pdf: default
  fws-report-docx: default
  fws-report-html: default
---
```

Then, from the command line:

```bash
# Render all formats listed in YAML
quarto render template.qmd
```

To render only one format from the command line, use --to:

```bash
quarto render template.qmd --to fws-report-pdf
quarto render template.qmd --to fws-report-docx
quarto render template.qmd --to fws-report-html
```

The DOCX format uses the bundled Word reference document to control styles and layout. The HTML format uses the bundled stylesheet to provide a matching report structure and cover layout in the browser. The same report metadata can therefore be rendered to PDF, DOCX, or HTML with extension-provided formatting.

## Including references

Cite sources with `[@key]`. Provide `bibliography:` (and optionally `csl:`) in YAML.

Add a bibliography file in YAML:

```yaml
---
bibliography: references.bib
format:
  fws-report-pdf: default
  fws-report-docx: default
  fws-report-html: default
---
```

Then, cite sources with `@key` or `[@key]` in the main body of the document:

```r
This report follows standard wildlife monitoring methods [@usfws2024].

Narrative citation example: @smith2023 found that wetland occupancy increased
after habitat restoration.

## References
```

Example of how to format references in your references.bib:

```bibtex
@report{usfws2024,
  author       = {{U.S. Fish and Wildlife Service}},
  year         = {2024},
  title        = {Annual Waterfowl Habitat Status Report},
  institution  = {U.S. Fish and Wildlife Service},
  address      = {Washington, DC}
}

@article{smith2023,
  author       = {Smith, Jane A. and Lopez, Marco R.},
  year         = {2023},
  title        = {Wetland restoration effects on migratory bird occupancy},
  journal      = {Journal of Wildlife Management},
  volume       = {87},
  number       = {4},
  pages        = {455--468},
  doi          = {10.1002/jwmg.12345}
}
```

Bibliographies are handled through citeproc in PDF, DOCX, and HTML output. Visit the Quarto website
 for more information about using citations.

## Getting help

Contact the [project maintainer](mailto:mccrea_cobb@fws.gov) for help with this repository. If you have general questions on creating repositories in the USFWS DGEC, reach out to a USFWS DGEC [owner](https://github.com/orgs/USFWS/people?query=role%3Aowner).

## Contribute

Contact the project maintainer for information about contributing to this repository. Submit a [GitHub Issue](https://github.com/USFWS/fws-report/issues) to report a bug or request a feature or enhancement.

-----

![](https://i.creativecommons.org/l/zero/1.0/88x31.png) This work is
licensed under a [Creative Commons Zero Universal v1.0
License](https://creativecommons.org/publicdomain/zero/1.0/).