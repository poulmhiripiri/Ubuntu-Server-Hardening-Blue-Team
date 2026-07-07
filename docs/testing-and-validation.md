# Testing and Validation

## Validation Performed

The following checks were performed after running the hardening workflow:

- Confirmed hardening summary generation
- Confirmed Lynis pre-hardening and post-hardening logs
- Confirmed Fail2Ban SSH jail status
- Confirmed Auditd service status
- Confirmed password aging policy
- Compared listening ports before and after hardening
- Compared enabled services before and after hardening
- Generated a human-readable PDF report

## Key Validation Commands

```bash
sudo cat /var/log/server-hardening/latest/hardening-summary.txt
sudo grep -i "hardening index" /var/log/server-hardening/latest/lynis-post-hardening.log
sudo cat /var/log/server-hardening/latest/fail2ban-sshd-status.txt
sudo cat /var/log/server-hardening/latest/auditd-status.txt
sudo cat /var/log/server-hardening/latest/login-defs-password-policy.txt
sudo cat /var/log/server-hardening/latest/listening-ports-after.txt
```

## Evidence Highlights

- Lynis hardening index improved from 65 to 77 in the lab run.
- Fail2Ban had one active jail: `sshd`.
- Auditd was enabled and running.
- Password aging baseline was set to 90 maximum days, 1 minimum day and 14 warning days.
- The lab retained SSH password authentication and port 22 as a safe default to avoid lockout.

## Notes

The `lastb` command was not available on the lab installation, so the script version included in this repository handles that gracefully by writing an explanatory note instead of treating it as a hard failure.
