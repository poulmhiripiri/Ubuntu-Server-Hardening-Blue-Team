# Ubuntu Server Hardening Implementation Procedure

## Objective

The objective of this lab was to harden a newly installed Ubuntu Server, validate the security posture before and after hardening, and produce evidence suitable for a blue-team portfolio project.

## Environment

- Platform: Ubuntu Server lab VM
- Audit tool: Lynis
- Controls: UFW, Fail2Ban, SSH hardening, Auditd, RKHunter, password policy, sysctl hardening and shell idle timeout
- Evidence path: `/var/log/server-hardening/latest`

## Procedure

### 1. Clone the repository

```bash
git clone https://github.com/poulmhiripiri/Ubuntu-Server-Hardening-Blue-Team.git
cd Ubuntu-Server-Hardening-Blue-Team
```

### 2. Review the script

```bash
less scripts/ubuntu-hardening.sh
```

### 3. Make scripts executable

```bash
chmod +x scripts/*.sh
```

### 4. Run audit-only mode first

```bash
sudo ./scripts/ubuntu-hardening.sh --audit-only
```

### 5. Run the safe hardening workflow

```bash
sudo ./scripts/ubuntu-hardening.sh
```

### 6. Review the generated summary

```bash
sudo cat /var/log/server-hardening/latest/hardening-summary.txt
```

### 7. Review Lynis results

```bash
sudo grep -i "hardening index" /var/log/server-hardening/latest/lynis-pre-hardening.log
sudo grep -i "hardening index" /var/log/server-hardening/latest/lynis-post-hardening.log
sudo grep -i "warning" /var/log/server-hardening/latest/lynis-post-hardening.log
sudo grep -i "suggestion" /var/log/server-hardening/latest/lynis-post-hardening.log | head -50
```

### 8. Validate firewall, Fail2Ban, Auditd and SSH

```bash
sudo cat /var/log/server-hardening/latest/ufw-status-final.txt
sudo cat /var/log/server-hardening/latest/fail2ban-sshd-status.txt
sudo cat /var/log/server-hardening/latest/auditd-status.txt
sudo cat /var/log/server-hardening/latest/sshd-effective-config.txt
```

### 9. Generate a human-readable report

```bash
sudo ./scripts/generate-hardening-report.sh
./scripts/convert-hardening-report.sh --format html --install-deps
./scripts/convert-hardening-report.sh --format pdf --install-deps
```

### 10. Copy evidence to a review workstation

From Kali or another Linux machine:

```bash
mkdir -p ~/server-hardening-evidence
rsync -avz --rsync-path="sudo rsync" pmhiripiri@<UBUNTU-IP>:/var/log/server-hardening/latest/ ~/server-hardening-evidence/
```

## Outcome

The lab produced before-and-after evidence, Lynis pre/post audit logs, service validation output, a human-readable PDF report, and screenshots suitable for documenting the hardening workflow.
