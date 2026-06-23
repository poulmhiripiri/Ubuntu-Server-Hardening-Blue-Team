# Rollback and Testing Guide

## Recommended test process

1. Test on a local VM or cloud test server.
2. Take a snapshot before running the script.
3. Run audit-only mode first:

```bash
sudo ./scripts/ubuntu-hardening.sh --audit-only
```

4. Review the pre-hardening Lynis report.
5. Run the full script.
6. Keep the current SSH session open.
7. Open a second terminal and test a new SSH connection.
8. Confirm application services and monitoring still work.

## Restoring SSH configuration

The script backs up `/etc/ssh/sshd_config` into:

```text
/var/log/server-hardening/<timestamp>/backups/etc/ssh/
```

To restore:

```bash
sudo cp /var/log/server-hardening/<timestamp>/backups/etc/ssh/sshd_config.<timestamp>.bak /etc/ssh/sshd_config
sudo sshd -t
sudo systemctl restart ssh
```

## Resetting UFW

```bash
sudo ufw status numbered
sudo ufw allow 22/tcp
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable
```

## Disabling Fail2Ban temporarily

```bash
sudo systemctl stop fail2ban
sudo systemctl disable fail2ban
```

## Removing custom sysctl settings

```bash
sudo rm /etc/sysctl.d/99-blue-team-hardening.conf
sudo sysctl --system
```

## Unlocking root password if required

Only do this if your organisation permits it and you understand the risk:

```bash
sudo passwd -u root
```

## Operational caution

Hardening should be adapted to the role of the server. A web server, database server, bastion host, SIEM node, and router-like Linux host will not all use the same security profile.
