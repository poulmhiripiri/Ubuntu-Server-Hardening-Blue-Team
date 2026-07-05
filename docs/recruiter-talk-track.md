# Recruiter Talk Track

## 30-second summary

This project demonstrates a practical Ubuntu Server hardening workflow designed from real infrastructure experience. It installs Lynis, captures pre-hardening evidence, applies blue-team hardening controls and generates post-hardening audit evidence. It reflects my background in ISP, DNS, mail, web hosting, banking infrastructure and my current focus on cybersecurity defensive operations.

## 60-second summary

I built this project to show how my network and infrastructure background translates into hands-on cybersecurity engineering. In the ISP sector, I worked with Linux servers supporting client domains, authoritative DNS, BIND, MX servers, mail routing, spam filtering, proxy services and hosted web servers. In banking infrastructure, I worked in environments where uptime, security, patching, audit evidence, access control and resilience were critical.

The toolkit uses Lynis to baseline and validate the server posture, then applies controls such as SSH hardening, UFW firewall policy, Fail2Ban, Auditd, sysctl tuning, password policy, idle session timeout and root account protection. It also produces before-and-after evidence, which is important for operational security, audit reviews and blue-team validation.

## Interview points

- I understand Linux hardening from both operational and security perspectives.
- I designed the script safely to avoid SSH lockout on remote servers.
- I included evidence generation because security changes must be measurable.
- I handled Ubuntu-specific service naming issues, especially `ssh.service` versus `sshd.service`.
- I linked the project to real ISP hosting, DNS, mail and banking infrastructure experience.
- I can extend this into Wazuh, Splunk or Microsoft Sentinel for SIEM visibility.
