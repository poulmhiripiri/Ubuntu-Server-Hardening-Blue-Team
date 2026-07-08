# Post-Hardening Report

This report summarizes the final lab run after the Ubuntu Server hardening script was executed.

## Lab Run Summary

- Script version: `2.0.0-final`
- Hostname: `blue-team`
- Root password locked: `true`
- SSH port: `22`
- SSH password authentication disabled: `false` by design, to avoid lockout during lab testing
- RKHunter enabled: `true`
- Evidence directory: `/var/log/server-hardening/latest`

## Lynis Hardening Index

| Stage | Hardening Index |
|---|---:|
| Pre-hardening | 65 |
| Post-hardening | 77 |

## Evidence Included

- `post-hardening-evidence-report.pdf`
- `hardening-summary.txt`
- `lynis-post-hardening.log`
- `lynis-report-post-hardening.dat`
- `lynis-pre-hardening.log`
- `../screenshots/` lab screenshots extracted from the Word evidence document

## Notes

The lab intentionally keeps SSH password authentication enabled by default until SSH key-based access is tested from a second terminal. This is safer for remote administration and avoids accidental lockout.
