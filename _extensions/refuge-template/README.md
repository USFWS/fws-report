# AKR Report Template (PDF) — Quarto extension

This format extension is tuned to the provided AKR Word/PDF template:
- Cover: Report Number (14pt), Title (20pt bold), Author (14pt), cover photo, ReportInfo (14pt bold right/bottom).
- Body: Heading 1 = 14pt bold; Heading 2 = 14pt bold condensed; Heading 3 = italic.
- Thin horizontal rule helper: `\\akrhr` (use via a raw LaTeX block).
- Minimal table ruling via `booktabs`; table captions above; figure captions below.

## Use

In your QMD front matter:

```yaml
format:
  akrreport-refuge-template-pdf: default
```

Metadata:
- `report-number`
- `cover-image`
- `report-info`
