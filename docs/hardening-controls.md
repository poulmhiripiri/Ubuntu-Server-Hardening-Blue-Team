# Hardening Controls

## Audit and Evidence

- Creates timestamped report directories under `/var/log/server-hardening/`
- Runs Lynis before and after hardening
- Captures listening ports, enabled services, logins, failed logins and active sessions
- Creates a `latest` symlink to simplify review

## SSH Security

- Disables root SSH login
- Blocks empty passwords
- Limits authentication attempts
- Sets login grace time
- Disables X11 forwarding
- Disables TCP forwarding
- Disables agent forwarding
- Limits maximum SSH sessions
- Sets verbose SSH logging
- Uses Ubuntu-compatible SSH service detection: `ssh.service` first, then `sshd.service`

## Firewall

- Resets UFW to a known baseline
- Denies inbound traffic by default
- Allows outbound traffic by default
- Allows SSH on the configured port
- Optionally allows HTTP and HTTPS

## Intrusion Prevention

- Enables Fail2Ban
- Configures SSH jail
- Uses 3 retries, 10-minute find time and 1-hour ban time

## Account Security

- Locks the root password
- Optionally creates/configures an admin user
- Enforces password aging baseline
- Adds password quality settings

## System Hardening

- Applies sysctl hardening for spoofing, redirects, martian logging, kernel pointer restriction and protected links
- Optionally disables IPv6
- Enables Auditd
- Adds audit rules for identity, privilege and SSH configuration files
- Updates RKHunter baseline

## Session Security

- Adds `/etc/profile.d/session-timeout.sh`
- Sets `TMOUT=900` for 15-minute idle shell logout
