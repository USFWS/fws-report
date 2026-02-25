# FWS Report Template (PDF) — Quarto extension

This Quarto **PDF format** extension provides an unofficial U.S. Fish and Wildlife Service (FWS) report layout.

Highlights:

- **Cover**: top banner (agency lines + logo), report number line, multi-line title, author list, cover image + right-justified credit, “How to cite this report” page, optional “On the Cover” page.
- **Body**: conservative, Word-like heading and caption defaults.
- **Tables/Figures**: `booktabs` tables; table captions above; figure captions below.

## Use

In your QMD front matter:

```yaml
format:
  fws-report-pdf: default
```

## Metadata fields

### Required (for a complete cover/citation)
- `title` — main report title. Supports multi-line titles (e.g., YAML `|` blocks).
- `author` — a single author string or a list of authors (entered as **First Last**).
- `year` — publication year (e.g., `2026`).
- `report-number` — report number (e.g., `"01"`).
- `cover-image` — path to the cover image file (e.g., `images/cover.jpg`).

### Recommended
- `title-short` — short title for running headers (if omitted, header can be blank).
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
If you cite with `[@key]`, references will render under a `# References` heading.

- `bibliography` — one or more `.bib` files (e.g., `bib/bibliography.bib`).
- `csl` — CSL style file (e.g., `bib/the-journal-of-wildlife-management.csl`).
- `reference-section-title` — defaults to `References` (can be overridden per document).

## Example

```yaml
---
title: |
  Report title line 1
  Report title line 2
  Report title line 3
title-short: "Short title for headers"

author:
  - "Jane Biologist"
  - "Joe Botanist"
  - "Jeff Ecologist"

year: 2026
report-number: "01"

fws-program: "National Wildlife Refuge System"
fws-region: "Alaska"
fws-station: "Kodiak National Wildlife Refuge"
location: "Kodiak, Alaska"

cover-image: "images/cover.jpg"
cover-image-credit: "Photo Caption / FWS"
cover-caption: "Image caption goes here"

doi: "10.1234/unique-doi"

bibliography:
  - bib/bibliography.bib
  - bib/packages.bib
csl: bib/the-journal-of-wildlife-management.csl

format:
  fws-report-pdf: default
---
```
