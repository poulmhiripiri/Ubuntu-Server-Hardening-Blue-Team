# Troubleshooting

## Permission denied when opening `/var/log/server-hardening`

The report directory is created under `/var/log` and is owned by root. Use:

```bash
sudo cat /var/log/server-hardening/latest/hardening-summary.txt
```

or open a root shell:

```bash
sudo -i
cd /var/log/server-hardening/latest
ls -la
exit
```

The final script also attempts to grant read/execute ACL access to the sudo user that launched it.

## `sudo cd` does not work

`cd` is a shell built-in, not a standalone command. Use:

```bash
sudo -i
cd /var/log/server-hardening/latest
```

## SSH restart fails on Ubuntu

Ubuntu normally uses `ssh.service`, not `sshd.service`. The final script detects both:

1. `ssh.service`
2. `sshd.service`

It validates SSH configuration before restarting.

## Hardening summary missing

If `hardening-summary.txt` is missing, the script likely stopped before completion. Check:

```bash
sudo find /var/log/server-hardening -maxdepth 2 -type f | sort
sudo less /var/log/server-hardening/latest/hardening-run.log
```

## Check Lynis score

```bash
sudo grep -i "hardening index" /var/log/server-hardening/latest/lynis-post-hardening.log
```

## Check SSH timeout

```bash
sudo sshd -T | grep -iE 'clientalive|tcpkeepalive'
echo $TMOUT
```
