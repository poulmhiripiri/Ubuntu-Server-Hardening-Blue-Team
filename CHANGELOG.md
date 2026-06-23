# Changelog

## 2026-06-23 - Ubuntu SSH restart compatibility fix

### Fixed
- Replaced direct `systemctl restart sshd` usage with a safer `restart_ssh_service()` helper.
- The script now detects and restarts `ssh.service` on Ubuntu, with `sshd.service` as fallback.
- Added SSH configuration validation before restarting the service.
- Fixed hardening summary report filenames to match generated Lynis report names.

### Added
- `/var/log/server-hardening/latest` symlink to make the newest report easier to find.
- Password aging baseline in `/etc/login.defs`.
- Inactive shell timeout under `/etc/profile.d/`.
- Additional SSH hardening controls: `AllowTcpForwarding no`, `X11Forwarding no`, `AllowAgentForwarding no`, `MaxSessions 2`, and `LogLevel VERBOSE`.
- Additional sysctl hardening values aligned to common Lynis recommendations.
- Root-protected report viewing commands in the README.

### Operational note
Keep your current SSH session open when running the script remotely. After the script completes, test a new SSH session before logging out.
