#!/usr/bin/env bash
# Ubuntu Server Hardening Blue-Team Toolkit
# Author: Poul Mhiripiri
# Purpose: Run a Lynis baseline, apply safe Ubuntu hardening controls, then produce post-hardening evidence.

set -Eeuo pipefail

SCRIPT_VERSION="2.1.0-lab-evidence"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BASE_REPORT_DIR="/var/log/server-hardening"
REPORT_DIR="${BASE_REPORT_DIR}/${TIMESTAMP}"
BACKUP_DIR="${REPORT_DIR}/backups"
LOG_FILE="${REPORT_DIR}/hardening-run.log"
AUDIT_ONLY=false
SSH_PORT="22"
CHANGE_SSH_PORT=false
DISABLE_SSH_PASSWORD=false
ALLOW_WEB=false
ADMIN_USER=""
DISABLE_IPV6=false
RUN_RKHUNTER=true

usage() {
    cat <<USAGE
Ubuntu Server Hardening Blue-Team Toolkit v${SCRIPT_VERSION}

Usage:
  sudo ./scripts/ubuntu-hardening.sh [options]

Options:
  --audit-only               Run baseline audit and evidence collection only. No hardening changes applied.
  --ssh-port <port>          Change SSH port. Default keeps port 22.
  --disable-ssh-password     Disable SSH password authentication. Use only after testing SSH keys.
  --allow-web                Allow HTTP/HTTPS through UFW.
  --admin-user <username>    Create/configure a sudo admin user and set password aging.
  --disable-ipv6             Disable IPv6 using sysctl. Use only if IPv6 is not required.
  --no-rkhunter              Skip RKHunter update/baseline steps.
  -h, --help                 Show this help.

Safe default:
  The script does not change SSH port and does not disable SSH password login unless explicitly requested.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --audit-only) AUDIT_ONLY=true; shift ;;
        --ssh-port) SSH_PORT="${2:-}"; CHANGE_SSH_PORT=true; shift 2 ;;
        --disable-ssh-password) DISABLE_SSH_PASSWORD=true; shift ;;
        --allow-web) ALLOW_WEB=true; shift ;;
        --admin-user) ADMIN_USER="${2:-}"; shift 2 ;;
        --disable-ipv6) DISABLE_IPV6=true; shift ;;
        --no-rkhunter) RUN_RKHUNTER=false; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

mkdir -p "${REPORT_DIR}" "${BACKUP_DIR}"
touch "${LOG_FILE}"
chmod 750 "${BASE_REPORT_DIR}" "${REPORT_DIR}" || true

log() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" | tee -a "${LOG_FILE}"
}

backup_file() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        local dest_dir="${BACKUP_DIR}$(dirname "${file}")"
        mkdir -p "${dest_dir}"
        cp -a "${file}" "${dest_dir}/$(basename "${file}").${TIMESTAMP}.bak"
        log "Backed up ${file} to ${dest_dir}/$(basename "${file}").${TIMESTAMP}.bak"
    fi
}

set_kv_config() {
    local file="$1" key="$2" value="$3"
    backup_file "${file}"
    touch "${file}"
    if grep -qiE "^[#[:space:]]*${key}[[:space:]]+" "${file}"; then
        sed -i -E "s|^[#[:space:]]*${key}[[:space:]]+.*|${key} ${value}|I" "${file}"
    else
        printf '%s %s\n' "${key}" "${value}" >> "${file}"
    fi
}

validate_port() {
    if ! [[ "${SSH_PORT}" =~ ^[0-9]+$ ]] || [[ "${SSH_PORT}" -lt 1 || "${SSH_PORT}" -gt 65535 ]]; then
        log "ERROR: Invalid SSH port: ${SSH_PORT}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log "ERROR: /etc/os-release not found. This script targets Ubuntu."
        exit 1
    fi
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        log "ERROR: This script targets Ubuntu. Detected: ${PRETTY_NAME:-unknown}"
        exit 1
    fi
    log "Detected ${PRETTY_NAME:-Ubuntu}."
}

restart_ssh_service() {
    log "Validating SSH configuration before restart."
    if command -v sshd >/dev/null 2>&1; then
        sshd -t 2>&1 | tee -a "${REPORT_DIR}/ssh-config-validation.txt"
    else
        log "WARNING: sshd binary not found in PATH. Skipping sshd -t validation."
    fi

    log "Restarting SSH service using Ubuntu-compatible detection."
    if systemctl list-unit-files | grep -q '^ssh.service'; then
        systemctl restart ssh
        systemctl status ssh --no-pager > "${REPORT_DIR}/ssh-service-status.txt" 2>&1 || true
    elif systemctl list-unit-files | grep -q '^sshd.service'; then
        systemctl restart sshd
        systemctl status sshd --no-pager > "${REPORT_DIR}/ssh-service-status.txt" 2>&1 || true
    else
        log "ERROR: No ssh.service or sshd.service unit found. Install openssh-server and rerun."
        exit 1
    fi
}

run_cmd_capture() {
    local outfile="$1"; shift
    log "Capturing: $* -> ${outfile}"
    { "$@"; } > "${REPORT_DIR}/${outfile}" 2>&1 || true
}

capture_failed_logins() {
    local outfile="$1"
    if command -v lastb >/dev/null 2>&1; then
        run_cmd_capture "${outfile}" lastb -n 20
    else
        log "lastb command not found. Capturing explanatory note in ${outfile}."
        {
            echo "lastb command not found on this Ubuntu installation."
            echo "This does not stop the hardening workflow."
            echo "Failed SSH activity should also be reviewed using:"
            echo "  sudo journalctl -u ssh --since '24 hours ago'"
            echo "  sudo grep -i 'failed password' /var/log/auth.log"
        } > "${REPORT_DIR}/${outfile}"
    fi
}

collect_evidence_before() {
    log "Collecting pre-hardening evidence."
    run_cmd_capture system-info.txt bash -c 'hostnamectl; echo; uname -a; echo; lsb_release -a 2>/dev/null || cat /etc/os-release'
    run_cmd_capture listening-ports-before.txt ss -tulpn
    run_cmd_capture enabled-services-before.txt systemctl list-unit-files --state=enabled
    run_cmd_capture active-sessions-before.txt who
    run_cmd_capture recent-logins-before.txt last -n 20
    capture_failed_logins failed-logins-before.txt
}

collect_evidence_after() {
    log "Collecting post-hardening evidence."
    run_cmd_capture listening-ports-after.txt ss -tulpn
    run_cmd_capture enabled-services-after.txt systemctl list-unit-files --state=enabled
    run_cmd_capture active-sessions-after.txt who
    run_cmd_capture recent-logins-after.txt last -n 20
    capture_failed_logins failed-logins-after.txt
    run_cmd_capture ufw-status-final.txt ufw status verbose
    run_cmd_capture fail2ban-status.txt fail2ban-client status
    run_cmd_capture fail2ban-sshd-status.txt fail2ban-client status sshd
    run_cmd_capture auditd-status.txt systemctl status auditd --no-pager
    run_cmd_capture journal-errors-current-boot.txt journalctl -p err -b --no-pager
    run_cmd_capture sshd-effective-config.txt sshd -T
    run_cmd_capture login-defs-password-policy.txt grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE)' /etc/login.defs
}

install_packages() {
    log "Updating packages and installing hardening/audit tools."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    apt-get install -y --no-install-recommends \
        lynis ufw fail2ban auditd audispd-plugins acl lsof curl ca-certificates \
        libpam-pwquality rkhunter nethogs whois needrestart
}

run_lynis() {
    local phase="$1"
    log "Running Lynis ${phase} audit."
    lynis audit system --quiet \
        --log-file "${REPORT_DIR}/lynis-${phase}.log" \
        --report-file "${REPORT_DIR}/lynis-report-${phase}.dat" || true
}

configure_admin_user() {
    if [[ -z "${ADMIN_USER}" ]]; then
        log "No --admin-user provided. Skipping admin user creation."
        return
    fi
    if id "${ADMIN_USER}" >/dev/null 2>&1; then
        log "Admin user ${ADMIN_USER} already exists."
    else
        log "Creating admin user ${ADMIN_USER}."
        useradd -m -s /bin/bash "${ADMIN_USER}"
        passwd "${ADMIN_USER}"
    fi
    usermod -aG sudo "${ADMIN_USER}"
    chage -M 90 -m 1 -W 14 "${ADMIN_USER}"
}

lock_root_password() {
    log "Locking root password to prevent direct password login."
    passwd -l root || true
}

configure_banner() {
    log "Configuring legal warning banner."
    backup_file /etc/issue.net
    cat > /etc/issue.net <<'BANNER'
UNAUTHORIZED ACCESS PROHIBITED.
This system is for authorised users only. All activity may be monitored and logged.
BANNER
    chmod 644 /etc/issue.net
    set_kv_config /etc/ssh/sshd_config Banner /etc/issue.net
}

configure_ssh() {
    validate_port
    log "Applying SSH hardening controls."
    backup_file /etc/ssh/sshd_config

    set_kv_config /etc/ssh/sshd_config PermitRootLogin no
    set_kv_config /etc/ssh/sshd_config PermitEmptyPasswords no
    set_kv_config /etc/ssh/sshd_config MaxAuthTries 3
    set_kv_config /etc/ssh/sshd_config LoginGraceTime 60
    set_kv_config /etc/ssh/sshd_config ClientAliveInterval 300
    set_kv_config /etc/ssh/sshd_config ClientAliveCountMax 2
    set_kv_config /etc/ssh/sshd_config TCPKeepAlive no
    set_kv_config /etc/ssh/sshd_config X11Forwarding no
    set_kv_config /etc/ssh/sshd_config AllowTcpForwarding no
    set_kv_config /etc/ssh/sshd_config AllowAgentForwarding no
    set_kv_config /etc/ssh/sshd_config MaxSessions 2
    set_kv_config /etc/ssh/sshd_config LogLevel VERBOSE

    if [[ "${CHANGE_SSH_PORT}" == true ]]; then
        log "Changing SSH port to ${SSH_PORT}."
        set_kv_config /etc/ssh/sshd_config Port "${SSH_PORT}"
    else
        log "SSH port left unchanged. Use --ssh-port <port> if required."
    fi

    if [[ "${DISABLE_SSH_PASSWORD}" == true ]]; then
        log "Disabling SSH password authentication. Confirm SSH key access from a second terminal before ending this session."
        set_kv_config /etc/ssh/sshd_config PasswordAuthentication no
        set_kv_config /etc/ssh/sshd_config KbdInteractiveAuthentication no
        set_kv_config /etc/ssh/sshd_config PubkeyAuthentication yes
    else
        log "SSH password authentication left unchanged. Use --disable-ssh-password after testing SSH keys."
    fi

    restart_ssh_service
}

configure_firewall() {
    log "Configuring UFW firewall baseline."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow "${SSH_PORT}/tcp"
    if [[ "${ALLOW_WEB}" == true ]]; then
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    ufw --force enable
    ufw status verbose > "${REPORT_DIR}/ufw-status.txt" 2>&1 || true
}

configure_fail2ban() {
    log "Configuring Fail2Ban for SSH."
    mkdir -p /etc/fail2ban/jail.d
    cat > /etc/fail2ban/jail.d/sshd-hardening.local <<EOF_F2B
[sshd]
enabled = true
port = ${SSH_PORT}
logpath = %(sshd_log)s
backend = systemd
maxretry = 3
findtime = 10m
bantime = 1h
EOF_F2B
    systemctl enable fail2ban
    systemctl restart fail2ban
}

configure_password_policy() {
    log "Applying password aging and password quality baseline."
    backup_file /etc/login.defs
    sed -i -E 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
    sed -i -E 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
    sed -i -E 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

    backup_file /etc/security/pwquality.conf
    cat > /etc/security/pwquality.conf <<'EOF_PWQ'
# Ubuntu Server Hardening baseline
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
retry = 3
EOF_PWQ
}

configure_session_timeout() {
    log "Configuring idle shell session timeout."
    cat > /etc/profile.d/session-timeout.sh <<'EOF_TIMEOUT'
# Auto-logout idle interactive shell sessions after 15 minutes.
# Applied by Ubuntu Server Hardening Blue-Team Toolkit.
TMOUT=900
readonly TMOUT
export TMOUT
EOF_TIMEOUT
    chmod 644 /etc/profile.d/session-timeout.sh
}

configure_sysctl() {
    log "Applying kernel and network sysctl hardening baseline."
    cat > /etc/sysctl.d/99-server-hardening.conf <<EOF_SYSCTL
# Ubuntu Server Hardening Blue-Team Toolkit
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
kernel.sysrq = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
EOF_SYSCTL
    if [[ "${DISABLE_IPV6}" == true ]]; then
        cat >> /etc/sysctl.d/99-server-hardening.conf <<'EOF_IPV6'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF_IPV6
    fi
    sysctl --system > "${REPORT_DIR}/sysctl-apply.txt" 2>&1 || true
}

configure_auditd() {
    log "Configuring auditd baseline rules."
    mkdir -p /etc/audit/rules.d
    cat > /etc/audit/rules.d/99-server-hardening.rules <<'EOF_AUDIT'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege
-w /etc/sudoers.d/ -p wa -k privilege
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /var/log/auth.log -p wa -k auth_logs
EOF_AUDIT
    augenrules --load > "${REPORT_DIR}/audit-rules-load.txt" 2>&1 || true
    systemctl enable auditd || true
    systemctl restart auditd || true
}

run_rkhunter_steps() {
    if [[ "${RUN_RKHUNTER}" != true ]]; then
        log "Skipping RKHunter steps due to --no-rkhunter."
        return
    fi
    log "Updating RKHunter and refreshing baseline."
    rkhunter --update > "${REPORT_DIR}/rkhunter-update.txt" 2>&1 || true
    rkhunter --propupd > "${REPORT_DIR}/rkhunter-propupd.txt" 2>&1 || true
}

fix_permissions() {
    log "Applying selected file and directory permissions."
    chmod 600 /etc/ssh/sshd_config || true
    chmod 750 /etc/sudoers.d || true
    chmod 600 /etc/crontab || true
    chmod 700 /root || true
}

create_summary() {
    log "Creating hardening summary."
    ln -sfn "${REPORT_DIR}" "${BASE_REPORT_DIR}/latest"
    cat > "${REPORT_DIR}/hardening-summary.txt" <<EOF_SUMMARY
Ubuntu Server Hardening Summary
================================

Timestamp: ${TIMESTAMP}
Script version: ${SCRIPT_VERSION}
Hostname: $(hostname)
Report directory: ${REPORT_DIR}
Latest symlink: ${BASE_REPORT_DIR}/latest

Options:
- Audit only: ${AUDIT_ONLY}
- SSH port: ${SSH_PORT}
- SSH port changed: ${CHANGE_SSH_PORT}
- SSH password authentication disabled: ${DISABLE_SSH_PASSWORD}
- Web ports allowed: ${ALLOW_WEB}
- Admin user configured: ${ADMIN_USER:-none}
- Root password locked: true
- IPv6 disabled by script: ${DISABLE_IPV6}
- RKHunter enabled: ${RUN_RKHUNTER}

Key evidence:
- Pre-hardening Lynis log: ${REPORT_DIR}/lynis-pre-hardening.log
- Post-hardening Lynis log: ${REPORT_DIR}/lynis-post-hardening.log
- Pre-hardening Lynis report: ${REPORT_DIR}/lynis-report-pre-hardening.dat
- Post-hardening Lynis report: ${REPORT_DIR}/lynis-report-post-hardening.dat
- UFW status: ${REPORT_DIR}/ufw-status-final.txt
- Fail2Ban status: ${REPORT_DIR}/fail2ban-sshd-status.txt
- Effective SSH config: ${REPORT_DIR}/sshd-effective-config.txt
- SSH service status: ${REPORT_DIR}/ssh-service-status.txt
- Listening ports before/after: ${REPORT_DIR}/listening-ports-before.txt and ${REPORT_DIR}/listening-ports-after.txt

Useful commands:
- List reports: sudo find ${BASE_REPORT_DIR} -maxdepth 2 -type f | sort
- View latest summary: sudo cat ${BASE_REPORT_DIR}/latest/hardening-summary.txt
- View latest Lynis post-hardening log: sudo less ${BASE_REPORT_DIR}/latest/lynis-post-hardening.log
- Check Lynis hardening index: sudo grep -i "hardening index" ${BASE_REPORT_DIR}/latest/lynis-post-hardening.log
- Check Lynis warnings: sudo grep -i "warning" ${BASE_REPORT_DIR}/latest/lynis-post-hardening.log

Next actions:
1. Review Lynis warnings and suggestions.
2. Confirm application-specific ports and services.
3. Check SSH access from a second terminal before ending the current session.
4. Integrate logs with SIEM tooling such as Wazuh, Microsoft Sentinel, or Splunk.
5. Schedule regular patching, vulnerability scanning, and configuration reviews.
EOF_SUMMARY
}

grant_report_access() {
    local report_user="${SUDO_USER:-}"
    if [[ -n "${report_user}" && "${report_user}" != "root" ]] && command -v setfacl >/dev/null 2>&1; then
        log "Granting read/execute ACL on report directory to ${report_user}."
        setfacl -m "u:${report_user}:rx" "${BASE_REPORT_DIR}" || true
        setfacl -R -m "u:${report_user}:rX" "${REPORT_DIR}" || true
    fi
}

main() {
    log "Starting Ubuntu Server Hardening Blue-Team Toolkit v${SCRIPT_VERSION}."
    check_os
    collect_evidence_before
    install_packages
    run_lynis pre-hardening

    if [[ "${AUDIT_ONLY}" == true ]]; then
        log "Audit-only mode selected. Skipping hardening changes."
        create_summary
        grant_report_access
        log "Audit-only run complete. Summary: ${REPORT_DIR}/hardening-summary.txt"
        exit 0
    fi

    configure_admin_user
    lock_root_password
    configure_banner
    configure_ssh
    configure_firewall
    configure_fail2ban
    configure_password_policy
    configure_session_timeout
    configure_sysctl
    configure_auditd
    run_rkhunter_steps
    fix_permissions
    collect_evidence_after
    run_lynis post-hardening
    create_summary
    grant_report_access

    log "Hardening workflow complete. Summary: ${REPORT_DIR}/hardening-summary.txt"
    cat "${REPORT_DIR}/hardening-summary.txt"
}

main "$@"
