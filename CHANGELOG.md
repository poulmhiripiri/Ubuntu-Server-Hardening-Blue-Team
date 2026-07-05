# Changelog

## 2.1.0 - Human-readable report generation

- Added `scripts/generate-hardening-report.sh` to convert raw hardening evidence into a readable Markdown report.
- Added `scripts/convert-hardening-report.sh` to convert the Markdown report into HTML or PDF using Pandoc.
- Updated README with report-generation steps for Markdown, HTML and PDF output.


## v2.0.0-final

- Added Ubuntu-compatible SSH restart detection.
- Validates SSH configuration before restart.
- Keeps SSH password authentication enabled by default to avoid lockout.
- Keeps SSH port 22 by default unless `--ssh-port` is passed.
- Adds `/var/log/server-hardening/latest` symlink.
- Grants report read access to the sudo user where ACL tools are available.
- Adds stronger SSH hardening controls.
- Adds password aging and password quality baseline.
- Adds shell idle timeout using `TMOUT=900`.
- Adds Auditd baseline rules.
- Adds improved evidence capture before and after hardening.
- Adds recruiter-focused documentation and troubleshooting notes.