# Repository Package Manifest

This corrected package includes the `docs/` folder, the `evidence/` folder, extracted screenshots, and explicit post-hardening report files.

## Key Folders

- `docs/` - implementation, testing, troubleshooting, recruiter notes and screenshot gallery
- `evidence/` - lab evidence files, generated PDF report and Lynis logs
- `evidence/screenshots/` - extracted screenshots from the Word lab evidence document
- `evidence/reports/` - explicit post-hardening report files
- `scripts/` - hardening and report-generation scripts

## Screenshot Count

- Extracted screenshots: 24

## Post-Hardening Report Files

- `evidence/reports/POST-HARDENING-REPORT.md`
- `evidence/reports/post-hardening-evidence-report.pdf`
- `evidence/reports/lynis-post-hardening.log`
- `evidence/reports/lynis-report-post-hardening.dat`
- `evidence/reports/hardening-summary.txt`

## Verification Commands

After unzipping, run:

```bash
find Ubuntu-Server-Hardening-Blue-Team/evidence/screenshots -maxdepth 1 -type f | sort
find Ubuntu-Server-Hardening-Blue-Team/evidence/reports -maxdepth 1 -type f | sort
```
