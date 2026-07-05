# Ubuntu Server Hardening Blue-Team Toolkit

A practical Ubuntu Server hardening project that installs Lynis, captures a pre-hardening security posture, applies safe post-install hardening controls, and generates evidence-ready reports for blue-team, infrastructure, and audit review.

This project is built from hands-on ISP, DNS, mail, proxy, web hosting, banking infrastructure, and cybersecurity experience.

## Repository Description

Ubuntu Server hardening toolkit using Lynis, UFW, Fail2Ban, SSH security, sysctl tuning, Auditd and evidence generation, built from hands-on ISP, DNS, mail, web hosting and blue-team infrastructure experience.

## Author Background

This project was developed by **Poul Mhiripiri**, an IT Networks and Infrastructure professional with over 15 years of hands-on experience across ISP, banking, enterprise infrastructure and cybersecurity environments.

My Linux server experience began in the ISP sector, where I worked on production systems supporting customer-facing internet services. This included setting up client domains on ISP authoritative name servers, configuring and maintaining Linux-based DNS services using BIND, and supporting hosted customer domains.

I also worked with Linux-based mail and proxy services deployed at client sites, including environments where DNS, mail routing, internet access and perimeter services were critical to business operations. As part of ISP hosting operations, I maintained MX servers and hosted web servers used by customer domains, including spam filtering, mail relay, DNS records, web hosting support and service availability checks.

In banking and enterprise infrastructure roles, I extended this experience into highly available, security-focused environments where uptime, patching, access control, audit evidence, firewalling, logging and infrastructure resilience were essential. This project brings together that background with my current focus on cybersecurity and blue-team defensive operations.

## What This Toolkit Does

The script performs the following workflow:

1. Creates a timestamped evidence directory under `/var/log/server-hardening/`.
2. Captures pre-hardening evidence, including listening ports, enabled services, active sessions, recent logins and failed logins.
3. Installs security and audit tools including Lynis, UFW, Fail2Ban, Auditd, ACL tools, RKHunter and supporting utilities.
4. Runs a Lynis pre-hardening audit.
5. Applies safe Ubuntu hardening controls.
6. Runs a Lynis post-hardening audit.
7. Generates a final `hardening-summary.txt` report.
8. Creates `/var/log/server-hardening/latest` as a shortcut to the latest run.

## Key Controls Applied

- Lynis pre-hardening and post-hardening audit
- Root account password lock
- Legal SSH warning banner
- SSH hardening
- Optional SSH port change
- Optional SSH password authentication disablement
- UFW default deny inbound policy
- Fail2Ban SSH protection
- Password aging baseline
- Password quality baseline
- Idle shell timeout using `TMOUT=900`
- Kernel and network sysctl hardening
- Auditd baseline rules
- RKHunter update and baseline
- Before and after evidence capture

## Safe Design Decisions

The script is designed to avoid locking you out of a newly installed Ubuntu server.

By default, it does **not**:

- Change the SSH port
- Disable SSH password authentication
- Open web ports
- Disable IPv6

You must explicitly request those options.

## Quick Start on a New Ubuntu Server

Install Git:

```bash
sudo apt update
sudo apt install -y git
```

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

Run audit-only mode first:

```bash
sudo ./scripts/ubuntu-hardening.sh --audit-only
```

Run the default safe hardening workflow:

```bash
sudo ./scripts/ubuntu-hardening.sh
```

## Optional Advanced Runs

Change SSH port to 2222:

```bash
sudo ./scripts/ubuntu-hardening.sh --ssh-port 2222
```

Allow web traffic:

```bash
sudo ./scripts/ubuntu-hardening.sh --allow-web
```

Create/configure an admin user:

```bash
sudo ./scripts/ubuntu-hardening.sh --admin-user deployadmin
```

Disable SSH password authentication only after confirming SSH key access:

```bash
sudo ./scripts/ubuntu-hardening.sh --disable-ssh-password
```

Combined example:

```bash
sudo ./scripts/ubuntu-hardening.sh --ssh-port 2222 --allow-web --admin-user deployadmin
```

## Viewing Reports

View the latest summary:

```bash
sudo cat /var/log/server-hardening/latest/hardening-summary.txt
```

List generated evidence:

```bash
sudo find /var/log/server-hardening -maxdepth 2 -type f | sort
```

View the latest Lynis post-hardening log:

```bash
sudo less /var/log/server-hardening/latest/lynis-post-hardening.log
```

Check the Lynis hardening index:

```bash
sudo grep -i "hardening index" /var/log/server-hardening/latest/lynis-post-hardening.log
```

Check Lynis warnings:

```bash
sudo grep -i "warning" /var/log/server-hardening/latest/lynis-post-hardening.log
```

Check Lynis suggestions:

```bash
sudo grep -i "suggestion" /var/log/server-hardening/latest/lynis-post-hardening.log | head -50
```

## SSH Timeout Validation

Check SSH keepalive hardening:

```bash
sudo sshd -T | grep -iE 'clientalive|tcpkeepalive'
```

Expected hardened output:

```text
clientaliveinterval 300
clientalivecountmax 2
tcpkeepalive no
```

This allows the SSH server to close dead or unresponsive sessions after approximately 10 minutes.

Check shell idle timeout:

```bash
echo $TMOUT
cat /etc/profile.d/session-timeout.sh
```

Expected value:

```text
900
```

This means idle interactive shell sessions are logged out after 15 minutes.

## Pull Latest Updates on the Server

After the repository has already been cloned:

```bash
cd ~/Ubuntu-Server-Hardening-Blue-Team
git status
git pull origin main
```

## Files Generated by the Script

Example evidence files:

```text
/var/log/server-hardening/latest/hardening-summary.txt
/var/log/server-hardening/latest/lynis-pre-hardening.log
/var/log/server-hardening/latest/lynis-post-hardening.log
/var/log/server-hardening/latest/ufw-status-final.txt
/var/log/server-hardening/latest/fail2ban-sshd-status.txt
/var/log/server-hardening/latest/sshd-effective-config.txt
/var/log/server-hardening/latest/ssh-service-status.txt
/var/log/server-hardening/latest/listening-ports-before.txt
/var/log/server-hardening/latest/listening-ports-after.txt
/var/log/server-hardening/latest/enabled-services-before.txt
/var/log/server-hardening/latest/enabled-services-after.txt
/var/log/server-hardening/latest/auditd-status.txt
```

## GitHub Evidence Warning

Do not upload raw logs if they include usernames, hostnames, IP addresses, internal paths, SSH details or service information. Use sanitized screenshots or summarized evidence.

A safe sample evidence template is included under:

```text
evidence/sample-hardening-evidence.md
```

## Recruiter Value

This repository demonstrates:

- Linux server administration
- Ubuntu post-install hardening
- Bash scripting
- Security posture assessment
- Lynis auditing
- Firewall configuration
- SSH hardening
- Fail2Ban intrusion prevention
- Auditd evidence collection
- Blue-team operational thinking
- Before and after security validation
- Infrastructure security experience from ISP, hosting and banking environments

## Disclaimer

Test this script in a lab before running it on production systems. Confirm application-specific ports and services before applying firewall or SSH changes.
