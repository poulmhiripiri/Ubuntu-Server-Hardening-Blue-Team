# Hardening Controls

This document maps the script controls to operational security objectives.

## Baseline audit

The script installs Lynis and runs a pre-hardening audit before making changes. This creates an evidence baseline that can be compared against the post-hardening audit.

## System updates

The script runs:

```bash
apt-get update
apt-get upgrade -y
```

Security objective: reduce exposure to known vulnerabilities in installed packages.

## User and privilege management

Optional command:

```bash
--admin-user <username>
```

This creates or updates a sudo-capable administrative user and applies password aging controls:

- Maximum password age: 90 days
- Inactive lock period: 30 days

Security objective: avoid routine direct root usage and support named administrative accountability.

## Root account protection

By default, the script locks the root password:

```bash
passwd -l root
```

Security objective: prevent direct password-based use of the root account.

## SSH hardening

Controls applied:

- `PermitRootLogin no`
- `PermitEmptyPasswords no`
- `MaxAuthTries 3`
- `LoginGraceTime 60`
- `PubkeyAuthentication yes`
- SSH legal banner
- Optional custom SSH port
- Optional disabling of SSH password authentication

Security objective: reduce brute-force exposure and prevent direct root SSH login.

## Firewall baseline

The script resets and enables UFW:

- Deny incoming by default
- Allow outgoing by default
- Allow SSH
- Optionally allow HTTP/HTTPS

Security objective: close unused network access paths and explicitly permit required services.

## Fail2Ban

The script configures Fail2Ban for SSH:

- `maxretry = 3`
- `findtime = 10m`
- `bantime = 1h`
- `backend = systemd`

Security objective: slow down brute-force attacks and repeated authentication abuse.

## Kernel and network stack hardening

The script writes `/etc/sysctl.d/99-blue-team-hardening.conf` with controls for:

- Disabling IP forwarding
- Rejecting source routing
- Rejecting ICMP redirects
- Reverse-path filtering
- Logging suspicious packets
- SYN flood protection
- Kernel pointer and dmesg restrictions
- ptrace restriction

Security objective: reduce spoofing, man-in-the-middle, local information disclosure, and network abuse opportunities.

## Logging and audit readiness

The script enables:

- `auditd`
- persistent `journald`
- current boot error log capture

Security objective: improve investigation and forensic readiness.

## Resource limits

The script creates `/etc/security/limits.d/99-blue-team-hardening.conf` to restrict core dumps and set baseline process limits.

Security objective: reduce accidental exposure through core dumps and limit process abuse.

## Banner

The script writes `/etc/issue.net` and links it to SSH.

Security objective: provide an authorised-use warning and support acceptable-use enforcement.

## Permission hygiene

The script tightens permissions on:

- `/etc/ssh/sshd_config`
- `/root`
- `/root/.ssh`
- `/root/.ssh/authorized_keys`

Security objective: prevent accidental exposure of sensitive administration files.

## Evidence generated

The script saves before/after outputs for:

- Lynis audit
- enabled services
- listening ports
- active sessions
- recent logins
- failed logins
- UFW status
- Fail2Ban status
- effective SSH configuration
- auditd status
- journal errors
