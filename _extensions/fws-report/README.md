# FWS Report Template Quarto extension

This Quarto extension provides an *unofficial* U.S. Fish and Wildlife Service (FWS) report layout for **PDF**, **DOCX**, and **HTML** output.

Highlights:

- **Cover**: top banner (agency lines + logo), report number line, multi-line title, author list, cover image + right-justified credit, “How to cite this report” page, optional “On the Cover” page.
- **Body**: conservative, Word-like heading and caption defaults.
- **Tables/Figures**: table captions above; figure captions below.
- **References**: citeproc-supported citations and bibliography rendering in PDF, DOCX, and HTML.
- **DOCX styling**: Word output uses the bundled `docx/reference.docx` file for paragraph and table styles.
- **HTML styling**: HTML output uses the bundled stylesheet for a matching report structure and cover layout in the browser.

## Use

In your QMD front matter, choose one or more formats.

### PDF only

```yaml
format:
  fws-report-pdf: default
```

### DOCX only

```yaml
format:
  fws-report-docx: default
```

### HTML only

```yaml
format:
  fws-report-html: default
```

### PDF, DOCX, and HTML in the same document

```yaml
format:
  fws-report-pdf: default
  fws-report-docx: default
  fws-report-html: default
```

## Render from the command line

Render a PDF only:

```bash
quarto render report.qmd --to fws-report-pdf
```

Render a DOCX only:

```bash
quarto render report.qmd --to fws-report-docx
```

Render an HTML only:

```bash
quarto render report.qmd --to fws-report-html
```

Render both outputs in one call:

```bash
quarto render report.qmd
```

When both formats are listed in the document YAML, running `quarto render` without `--to` will render both outputs.

## Metadata fields

### Required (for a complete cover/citation)
- `title` — main report title. Supports multi-line titles (e.g., YAML `|` blocks).
- `author` — a single author string or a list of authors (entered as **First Last**).
- `year` — publication year (e.g., `2026`).
- `report-number` — report number (e.g., `"01"`).
- `cover-image` — path to the cover image file (e.g., `images/cover.jpg`).

### Recommended
- `title-short` — short title for running headers.
- `doi` — DOI suffix (e.g., `10.1234/unique-doi`); rendered as a `https://doi.org/...` URL.

### FWS program/station metadata (used in banner + citation)
- `fws-program` — program name used in the banner and citation.  
  Default: `National Wildlife Refuge System`
- `fws-region` — region name used in the banner/citation (e.g., `Alaska`).  
  Default: `Alaska`
- `fws-station` — station/unit name (e.g., `Kodiak National Wildlife Refuge`).
- `location` — location text (e.g., `Kodiak, Alaska`).

### Cover image text
- `cover-image-credit` — cover photo credit line (right-justified under the image).
- `cover-caption` — “On the Cover” text (shown on its own page if provided).

### References / citations (citeproc)
If you cite with `@key` or `[@key]`, references will render under a `# References` heading in both formats.

- `bibliography` — one or more `.bib` files (e.g., `bib/bibliography.bib`).
- `csl` — CSL style file (e.g., `bib/the-journal-of-wildlife-management.csl`).
- `reference-section-title` — defaults to `References` (can be overridden per document).

Example inline citations:

```markdown
This report follows standard wildlife monitoring methods [@usfws2024].

Narrative citation example: @smith2023 found that wetland occupancy increased
after habitat restoration.
```

## Example

```yaml
---
title: |
  | Report Title Line 1
  | Report Title Line 2
  | Report Title Line 3
title-short: "Short title for headers"
author:
  - "Jane Biologist"
  - "Joe Botanist"
  - "Jeff Ecologist"
year: 2026
report-number: "01"

fws-program: "National Wildlife Refuge System"  # Optional
fws-station: "Kodiak National Wildlife Refuge"  # Optional
fws-region: "Alaska"  # Optional; if omitted, defaults to Alaska
location: "Kodiak, Alaska"  # Optional

cover-image: "images/cover.jpg"
cover-image-credit: "Photo Caption / FWS"
cover-caption: "Image caption goes here"

doi: "10.1234/unique-doi"

format:
  fws-report-pdf: default
  fws-report-docx: default

bibliography: bib/bibliography.bib
csl: bib/the-journal-of-wildlife-management.csl
---
```
