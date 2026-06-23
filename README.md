# Ubuntu Server Hardening Blue Team Toolkit

A recruiter-friendly Linux security hardening project for newly installed Ubuntu servers.

**Suggested GitHub description:** Ubuntu Server hardening toolkit using Lynis, UFW, Fail2Ban, SSH security, sysctl tuning and audit evidence generation, built from hands-on ISP, DNS, mail, web hosting and blue-team infrastructure experience.

This repository demonstrates a practical **Day-0 Ubuntu Server hardening workflow**: baseline auditing with Lynis, controlled hardening, post-hardening validation, and evidence collection. It is designed to show hands-on infrastructure experience, network security awareness, and blue-team operational thinking.

## Why this project matters

Newly installed Linux servers often ship with default services, permissive login settings, incomplete audit evidence, weak visibility, and no baseline security report. In ISP, banking, and enterprise environments, those gaps can quickly become operational and audit risks.

This toolkit helps turn a fresh Ubuntu server into a more defensible baseline by applying controls across:

- Patch management
- Secure administration
- SSH hardening
- Firewall policy
- Intrusion prevention
- Kernel/network stack hardening
- Logging and audit readiness
- File permission hygiene
- Legal warning banners
- Security posture reporting with Lynis

## Professional context

I built this as part of my transition from hands-on IT Networks and Infrastructure Management into cybersecurity, with a focus on blue-team skills. My background includes supporting ISP, hosting, banking and enterprise infrastructure environments where uptime, secure access, DNS reliability, mail flow, web availability, change control, audit evidence, firewalling, segmentation and operational resilience were critical.

This project reflects that experience by combining infrastructure hardening with security operations practices such as baseline assessment, control implementation, post-change validation and reporting.

## Author background

This project was developed by **Poul Mhiripiri**, an IT Networks and Infrastructure professional with over 15 years of hands-on experience across ISP, banking, enterprise infrastructure and cybersecurity environments.

My Linux server experience began in the ISP sector, where I worked on production systems supporting customer-facing internet services. This included setting up client domains on ISP authoritative name servers, configuring and maintaining Linux-based DNS services using BIND, and supporting hosted customer domains.

I also worked with Linux-based mail and proxy services deployed at client sites, including environments where DNS, mail routing, internet access and perimeter services were critical to business operations. As part of ISP hosting operations, I maintained MX servers and hosted web servers used by customer domains, including spam filtering, mail relay, DNS records, web hosting support and service availability checks.

In banking and enterprise infrastructure roles, I extended this experience into highly available, security-focused environments where uptime, patching, access control, audit evidence, firewall policy, logging and infrastructure resilience were essential. This project brings together that background with my current focus on cybersecurity and blue-team defensive operations.

The purpose of this repository is to demonstrate practical Linux server hardening skills, security posture assessment, attack surface reduction and evidence-based infrastructure security using tools such as Lynis, UFW, Fail2Ban, SSH hardening, sysctl tuning and security logging.

## Repository structure

```text
ubuntu-server-hardening-blue-team/
├── scripts/
│   └── ubuntu-hardening.sh
├── docs/
│   ├── author-background.md
│   ├── hardening-controls.md
│   ├── recruiter-talk-track.md
│   └── rollback-and-testing.md
├── .github/
│   └── workflows/
│       └── shellcheck.yml
├── .gitignore
├── LICENSE
└── README.md
```

## What the script does

The main script:

1. Checks it is running on Ubuntu.
2. Creates a timestamped evidence directory under `/var/log/server-hardening/`.
3. Installs core security packages:
   - `lynis`
   - `ufw`
   - `fail2ban`
   - `auditd`
   - `audispd-plugins`
   - `rkhunter`
   - `acl`
   - `lsof`
   - `nethogs`
   - `libpam-pwquality`
4. Runs a **pre-hardening Lynis audit**.
5. Applies Ubuntu hardening controls.
6. Runs a **post-hardening Lynis audit**.
7. Saves reports, configuration backups, command outputs, and a summary file.

## Quick start

Clone the repository:

```bash
git clone https://github.com/poulmhiripiri/Ubuntu-Server-Hardening-Blue-Team.git
cd Ubuntu-Server-Hardening-Blue-Team
```

Review the script before running it:

```bash
less scripts/ubuntu-hardening.sh
```

Make it executable:

```bash
chmod +x scripts/ubuntu-hardening.sh
```

Run in audit-only mode first:

```bash
sudo ./scripts/ubuntu-hardening.sh --audit-only
```

Run the hardening workflow:

```bash
sudo ./scripts/ubuntu-hardening.sh
```


## Pull latest updates on the Linux server

After the repository has already been cloned on the Ubuntu server, update it with:

```bash
cd ~/Ubuntu-Server-Hardening-Blue-Team
git status
git pull origin main
```

Then review and run the script again:

```bash
less scripts/ubuntu-hardening.sh
chmod +x scripts/ubuntu-hardening.sh
sudo ./scripts/ubuntu-hardening.sh --audit-only
sudo ./scripts/ubuntu-hardening.sh
```

## Ubuntu SSH service compatibility fix

Ubuntu normally uses `ssh.service`, while some Linux distributions use `sshd.service`. The script now validates the SSH configuration with `sshd -t` and restarts the correct service automatically. This prevents the previous Ubuntu error:

```text
Failed to restart sshd.service: Unit sshd.service not found.
```

## Safer SSH rollout

By default, the script **does not** change the SSH port and **does not** disable password authentication unless explicitly requested. This avoids locking administrators out of remote servers.

To change SSH to port `2222`:

```bash
sudo ./scripts/ubuntu-hardening.sh --ssh-port 2222
```

To disable SSH password authentication after confirming SSH keys work:

```bash
sudo ./scripts/ubuntu-hardening.sh --disable-ssh-password
```

To do both:

```bash
sudo ./scripts/ubuntu-hardening.sh --ssh-port 2222 --disable-ssh-password
```

## Evidence and reports

Reports are stored here:

```text
/var/log/server-hardening/<timestamp>/
```

The script also creates a shortcut to the latest run:

```text
/var/log/server-hardening/latest/
```

Because this folder is root-protected, use `sudo` to read reports, for example:

```bash
sudo cat /var/log/server-hardening/latest/hardening-summary.txt
sudo less /var/log/server-hardening/latest/lynis-post-hardening.log
sudo find /var/log/server-hardening -maxdepth 2 -type f | sort
```

Typical files include:

```text
lynis-pre-hardening.log
lynis-post-hardening.log
lynis-report-pre.dat
lynis-report-post.dat
enabled-services-before.txt
enabled-services-after.txt
listening-ports-before.txt
listening-ports-after.txt
hardening-summary.txt
```

These files are useful for audit evidence, recruiter demonstrations, portfolio screenshots, and interview discussions.

## Key controls implemented

| Area | Control |
|---|---|
| Patching | Runs package update and upgrade |
| Access control | Locks direct root password login, applies password aging, and adds idle shell timeout |
| SSH | Disables root SSH login, empty passwords, limits attempts, disables X11/agent/TCP forwarding, optional SSH port change, optional password-auth disable |
| Firewall | Enables UFW deny-inbound/allow-outbound baseline |
| Intrusion prevention | Installs and configures Fail2Ban for SSH |
| Kernel hardening | Adds sysctl controls for spoofing protection, redirects, source routing, SYN cookies |
| Logging | Enables auditd and persistent journald |
| Legal banner | Configures `/etc/issue.net` and SSH banner |
| Permissions | Secures SSH server config and root SSH directory |
| Resource limits | Adds baseline process and core dump limits |
| Security assessment | Runs Lynis before and after hardening |

## Important operational note

Do not run hardening scripts blindly on production servers. Test first in a lab, VM, or maintenance window. Confirm application ports, backup access, SSH keys, monitoring, and operational requirements before applying changes.

## Suggested portfolio use

Add screenshots of:

- Lynis pre-hardening score
- Lynis post-hardening score
- UFW status
- Fail2Ban status
- SSH configuration checks
- `/var/log/server-hardening/<timestamp>/hardening-summary.txt`

Then explain the project as a Day-0 baseline hardening workflow that combines infrastructure engineering discipline with blue-team security controls.

## Disclaimer

This toolkit provides a secure baseline, not a one-size-fits-all compliance guarantee. Production environments should align controls with business requirements, CIS Benchmarks, NIST CSF, ISO 27001, PCI DSS, and internal change management policies where applicable.
