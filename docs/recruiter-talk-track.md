# Recruiter Talk Track

## 30-second summary

This project demonstrates my ability to harden a freshly installed Ubuntu server using a blue-team mindset. It starts with a Lynis baseline audit, applies practical security controls across SSH, firewalling, Fail2Ban, kernel settings, audit logging, permissions, and legal banners, and then produces a post-hardening report for evidence. It reflects my hands-on background in ISP, DNS, mail, web hosting and banking infrastructure where secure access, uptime, audit evidence, and operational discipline were critical.

## 60-second summary

I created this Ubuntu hardening toolkit to show how I translate infrastructure experience into cybersecurity practice. The workflow does not just apply commands blindly. It captures a pre-hardening baseline, backs up configuration files, applies controlled hardening, validates SSH configuration, enables firewall and intrusion prevention controls, strengthens the network stack, enables audit logging, and runs a post-hardening Lynis audit. This gives both technical controls and evidence, which is important in enterprise environments.

My background includes hands-on network and infrastructure management in ISP and banking environments. In the ISP space, I worked with Linux servers supporting client domains, authoritative DNS, BIND, MX services, mail routing, spam filtering, proxy services and hosted web servers. I understand the importance of availability, secure remote administration, change control, firewall policy, logging, and audit readiness. I am now building on that experience as I pursue blue-team cybersecurity roles.

## Interview talking points

- I understand that hardening must be measurable, so the script runs Lynis before and after changes.
- I avoided risky defaults that could lock administrators out, such as disabling SSH password authentication without explicit approval.
- I used backup and validation steps before restarting SSH.
- I implemented layered controls: patching, SSH, firewall, Fail2Ban, sysctl, auditd, permissions, and reporting.
- I treated evidence as part of the deliverable, not an afterthought.
- This project connects my infrastructure background to blue-team outcomes such as prevention, detection, audit readiness, and incident response support.
- I can link Linux hardening to real hosted-service operations, including DNS, mail, web, proxy and customer-facing ISP platforms.
- I understand that server hardening must protect availability as well as confidentiality and integrity, especially for DNS, MX and web services.

## How this links to my experience

In ISP and banking environments, I worked with infrastructure where downtime, weak access control, poor visibility, DNS issues, mail-flow problems, hosted web-service failures and misconfiguration could create major business risk. My ISP experience included setting up customer domains on authoritative name servers, supporting Linux DNS using BIND, maintaining MX servers with spam filtering, and supporting hosted web servers for client domains. This project demonstrates that I can approach Linux hardening in the same structured way: assess, implement, validate, document, and improve.

## Suggested LinkedIn/GitHub description

Day-0 Ubuntu Server Hardening Toolkit using Bash, Lynis, UFW, Fail2Ban, auditd, sysctl, SSH controls, and evidence reporting. Built from hands-on ISP, DNS, MX, web hosting, banking infrastructure and blue-team security experience.
