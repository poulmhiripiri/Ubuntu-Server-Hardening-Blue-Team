#!/usr/bin/env bash
# Ubuntu Server Hardening Blue Team Toolkit
# Author: Poul Mhiripiri
# Purpose: Day-0 Ubuntu server hardening with Lynis pre/post assessment and evidence collection.
#
# Tested target: Ubuntu Server 22.04/24.04 LTS
#
# Safety defaults:
# - Does not change SSH port unless --ssh-port is provided.
# - Does not disable SSH password authentication unless --disable-ssh-password is provided.
# - Backs up modified configuration files.

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_ROOT="/var/log/server-hardening"
REPORT_DIR="${REPORT_ROOT}/${TIMESTAMP}"
BACKUP_DIR="${REPORT_DIR}/backups"

SSH_PORT="22"
CHANGE_SSH_PORT="false"
DISABLE_SSH_PASSWORD="false"
AUDIT_ONLY="false"
ALLOW_WEB="false"
ADMIN_USER=""
LOCK_ROOT="true"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "${REPORT_DIR}/hardening-run.log"
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

usage() {
  cat <<USAGE
Usage:
  sudo ./${SCRIPT_NAME} [options]

Options:
  --audit-only                 Install Lynis and run audit only, no hardening changes.
  --ssh-port <port>            Change SSH listening port and allow it in UFW.
  --disable-ssh-password       Disable SSH password authentication. Use only after confirming SSH keys work.
  --allow-web                  Allow HTTP/HTTPS in UFW.
  --admin-user <username>      Create or update a sudo admin user with password aging controls.
  --no-lock-root               Do not lock the root password.
  -h, --help                   Show this help message.

Examples:
  sudo ./scripts/ubuntu-hardening.sh --audit-only
  sudo ./scripts/ubuntu-hardening.sh
  sudo ./scripts/ubuntu-hardening.sh --ssh-port 2222 --disable-ssh-password
  sudo ./scripts/ubuntu-hardening.sh --admin-user secadmin --allow-web
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --audit-only)
      AUDIT_ONLY="true"
      shift
      ;;
    --ssh-port)
      [[ $# -ge 2 ]] || die "--ssh-port requires a port number"
      SSH_PORT="$2"
      CHANGE_SSH_PORT="true"
      shift 2
      ;;
    --disable-ssh-password)
      DISABLE_SSH_PASSWORD="true"
      shift
      ;;
    --allow-web)
      ALLOW_WEB="true"
      shift
      ;;
    --admin-user)
      [[ $# -ge 2 ]] || die "--admin-user requires a username"
      ADMIN_USER="$2"
      shift 2
      ;;
    --no-lock-root)
      LOCK_ROOT="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Run this script as root or with sudo."
  fi
}

require_ubuntu() {
  if [[ ! -r /etc/os-release ]]; then
    die "Cannot determine operating system."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    die "This script is designed for Ubuntu. Detected: ${PRETTY_NAME:-unknown}"
  fi
}

validate_port() {
  if ! [[ "${SSH_PORT}" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
    die "Invalid SSH port: ${SSH_PORT}"
  fi
}

prepare_reports() {
  mkdir -p "${REPORT_DIR}" "${BACKUP_DIR}"
  chmod 700 "${REPORT_ROOT}" "${REPORT_DIR}" "${BACKUP_DIR}"
  touch "${REPORT_DIR}/hardening-run.log"
}

backup_file() {
  local file="$1"
  if [[ -f "${file}" ]]; then
    local dest="${BACKUP_DIR}${file}.${TIMESTAMP}.bak"
    mkdir -p "$(dirname "${dest}")"
    cp -a "${file}" "${dest}"
    log "Backed up ${file} to ${dest}"
  fi
}

capture_baseline() {
  log "Capturing baseline services, ports, sessions, and OS details."
  {
    hostnamectl || true
    echo
    lsb_release -a 2>/dev/null || true
    echo
    uname -a
  } > "${REPORT_DIR}/system-info.txt"

  systemctl list-unit-files --state=enabled > "${REPORT_DIR}/enabled-services-before.txt" || true
  ss -tulpn > "${REPORT_DIR}/listening-ports-before.txt" || true
  w > "${REPORT_DIR}/active-sessions-before.txt" || true
  last -n 20 > "${REPORT_DIR}/recent-logins-before.txt" || true
  lastb -n 20 > "${REPORT_DIR}/failed-logins-before.txt" 2>/dev/null || true
}

install_packages() {
  log "Updating package index and installing security tooling."
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get upgrade -y

  apt-get install -y \
    lynis \
    ufw \
    fail2ban \
    auditd \
    audispd-plugins \
    rkhunter \
    acl \
    lsof \
    nethogs \
    libpam-pwquality \
    curl \
    ca-certificates
}

run_lynis() {
  local phase="$1"
  local log_file="${REPORT_DIR}/lynis-${phase}.log"
  local report_file="${REPORT_DIR}/lynis-report-${phase}.dat"

  log "Running Lynis ${phase} audit."
  lynis audit system --quick --no-colors --log-file "${log_file}" --report-file "${report_file}" || true
}

configure_admin_user() {
  if [[ -z "${ADMIN_USER}" ]]; then
    log "No --admin-user provided. Skipping admin user creation."
    return
  fi

  if ! id "${ADMIN_USER}" >/dev/null 2>&1; then
    log "Creating admin user ${ADMIN_USER}."
    useradd -m -s /bin/bash "${ADMIN_USER}"
    passwd "${ADMIN_USER}"
  else
    log "Admin user ${ADMIN_USER} already exists."
  fi

  usermod -aG sudo "${ADMIN_USER}"
  chage -M 90 "${ADMIN_USER}"
  chage -I 30 "${ADMIN_USER}"
  chage -l "${ADMIN_USER}" > "${REPORT_DIR}/password-aging-${ADMIN_USER}.txt" || true
}

lock_root_account() {
  if [[ "${LOCK_ROOT}" == "true" ]]; then
    log "Locking root password to prevent direct password login."
    passwd -l root || true
  else
    log "Root password locking disabled by --no-lock-root."
  fi
}

set_sshd_option() {
  local key="$1"
  local value="$2"
  local file="/etc/ssh/sshd_config"

  if grep -qiE "^[#[:space:]]*${key}[[:space:]]+" "${file}"; then
    sed -i -E "s|^[#[:space:]]*${key}[[:space:]].*|${key} ${value}|I" "${file}"
  else
    printf '\n%s %s\n' "${key}" "${value}" >> "${file}"
  fi
}

configure_ssh() {
  local sshd_config="/etc/ssh/sshd_config"
  [[ -f "${sshd_config}" ]] || die "Cannot find ${sshd_config}"

  backup_file "${sshd_config}"

  log "Applying SSH hardening controls."
  set_sshd_option "PermitRootLogin" "no"
  set_sshd_option "PermitEmptyPasswords" "no"
  set_sshd_option "MaxAuthTries" "3"
  set_sshd_option "LoginGraceTime" "60"
  set_sshd_option "PubkeyAuthentication" "yes"
  set_sshd_option "Banner" "/etc/issue.net"

  if [[ "${CHANGE_SSH_PORT}" == "true" ]]; then
    set_sshd_option "Port" "${SSH_PORT}"
  fi

  if [[ "${DISABLE_SSH_PASSWORD}" == "true" ]]; then
    set_sshd_option "PasswordAuthentication" "no"
    # Ubuntu 22.04+ may use KbdInteractiveAuthentication rather than ChallengeResponseAuthentication.
    set_sshd_option "KbdInteractiveAuthentication" "no"
    set_sshd_option "ChallengeResponseAuthentication" "no"
  else
    log "SSH password authentication left unchanged. Use --disable-ssh-password after testing SSH keys."
  fi

  sshd -t || die "sshd_config validation failed. Restore from ${BACKUP_DIR} if needed."

  if systemctl list-unit-files | grep -q '^ssh\.service'; then
    systemctl restart ssh
  else
    systemctl restart sshd
  fi
}

configure_firewall() {
  log "Configuring UFW firewall baseline."
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow "${SSH_PORT}/tcp" comment "SSH administration"

  if [[ "${ALLOW_WEB}" == "true" ]]; then
    ufw allow 80/tcp comment "HTTP"
    ufw allow 443/tcp comment "HTTPS"
  fi

  ufw --force enable
  ufw status verbose > "${REPORT_DIR}/ufw-status.txt" || true
}

configure_fail2ban() {
  log "Configuring Fail2Ban for SSH brute-force protection."
  mkdir -p /etc/fail2ban/jail.d
  cat > /etc/fail2ban/jail.d/sshd-hardening.local <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 3
findtime = 10m
bantime = 1h
backend = systemd
EOF

  systemctl enable fail2ban
  systemctl restart fail2ban
  fail2ban-client status > "${REPORT_DIR}/fail2ban-status.txt" || true
  fail2ban-client status sshd > "${REPORT_DIR}/fail2ban-sshd-status.txt" || true
}

configure_sysctl() {
  local sysctl_file="/etc/sysctl.d/99-blue-team-hardening.conf"
  backup_file "${sysctl_file}"

  log "Applying kernel and network stack hardening."
  cat > "${sysctl_file}" <<'EOF'
# Blue Team Ubuntu hardening baseline

# Disable IP forwarding unless the host is intentionally routing traffic.
net.ipv4.ip_forward = 0

# Source route protection.
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# ICMP redirect protection.
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Anti-spoofing.
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log suspicious packets.
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# SYN flood protection.
net.ipv4.tcp_syncookies = 1

# Ignore bogus ICMP errors and broadcasts.
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Reduce information leakage.
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

# Restrict ptrace.
kernel.yama.ptrace_scope = 1
EOF

  sysctl --system > "${REPORT_DIR}/sysctl-apply.txt" || true
}

configure_audit_logging() {
  log "Enabling auditd and persistent journald."
  systemctl enable auditd
  systemctl restart auditd || true

  mkdir -p /var/log/journal
  backup_file "/etc/systemd/journald.conf"
  sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
  systemctl restart systemd-journald

  auditctl -s > "${REPORT_DIR}/auditd-status.txt" || true
  journalctl -p err -b > "${REPORT_DIR}/journal-errors-current-boot.txt" || true
}

configure_limits() {
  local limits_file="/etc/security/limits.d/99-blue-team-hardening.conf"
  backup_file "${limits_file}"

  log "Applying baseline resource limits."
  cat > "${limits_file}" <<'EOF'
# Blue Team baseline process and core dump limits.
* hard core 0
* soft nproc 4096
* hard nproc 8192
root soft nproc unlimited
root hard nproc unlimited
EOF
}

configure_banner() {
  log "Configuring legal warning banner."
  backup_file "/etc/issue.net"
  cat > /etc/issue.net <<'EOF'
UNAUTHORIZED ACCESS PROHIBITED.
This system is for authorised users only.
All activity may be monitored, logged, and reported.
EOF
  chmod 644 /etc/issue.net
}

configure_permissions() {
  log "Applying permission hygiene."
  chmod 600 /etc/ssh/sshd_config || true
  chmod 700 /root || true
  [[ -d /root/.ssh ]] && chmod 700 /root/.ssh
  [[ -f /root/.ssh/authorized_keys ]] && chmod 600 /root/.ssh/authorized_keys
}

capture_after() {
  log "Capturing post-hardening services, ports, sessions, and controls."
  systemctl list-unit-files --state=enabled > "${REPORT_DIR}/enabled-services-after.txt" || true
  ss -tulpn > "${REPORT_DIR}/listening-ports-after.txt" || true
  w > "${REPORT_DIR}/active-sessions-after.txt" || true
  last -n 20 > "${REPORT_DIR}/recent-logins-after.txt" || true
  lastb -n 20 > "${REPORT_DIR}/failed-logins-after.txt" 2>/dev/null || true
  sshd -T > "${REPORT_DIR}/sshd-effective-config.txt" || true
  ufw status verbose > "${REPORT_DIR}/ufw-status-final.txt" || true
}

rkhunter_baseline() {
  log "Updating rkhunter file properties baseline."
  rkhunter --update > "${REPORT_DIR}/rkhunter-update.txt" 2>&1 || true
  rkhunter --propupd > "${REPORT_DIR}/rkhunter-propupd.txt" 2>&1 || true
}

write_summary() {
  cat > "${REPORT_DIR}/hardening-summary.txt" <<EOF
Ubuntu Server Hardening Summary
================================

Timestamp: ${TIMESTAMP}
Hostname: $(hostname)
Report directory: ${REPORT_DIR}

Options:
- Audit only: ${AUDIT_ONLY}
- SSH port: ${SSH_PORT}
- SSH port changed: ${CHANGE_SSH_PORT}
- SSH password authentication disabled: ${DISABLE_SSH_PASSWORD}
- Web ports allowed: ${ALLOW_WEB}
- Admin user configured: ${ADMIN_USER:-none}
- Root password locked: ${LOCK_ROOT}

Key evidence:
- Pre-hardening Lynis log: ${REPORT_DIR}/lynis-pre-hardening.log
- Post-hardening Lynis log: ${REPORT_DIR}/lynis-post-hardening.log
- Pre-hardening Lynis report: ${REPORT_DIR}/lynis-report-pre.dat
- Post-hardening Lynis report: ${REPORT_DIR}/lynis-report-post.dat
- UFW status: ${REPORT_DIR}/ufw-status-final.txt
- Fail2Ban status: ${REPORT_DIR}/fail2ban-sshd-status.txt
- Effective SSH config: ${REPORT_DIR}/sshd-effective-config.txt
- Listening ports before/after: ${REPORT_DIR}/listening-ports-before.txt and listening-ports-after.txt

Next actions:
1. Review Lynis warnings and suggestions.
2. Confirm application-specific ports and services.
3. Check SSH access from a second terminal before ending the current session.
4. Integrate logs with SIEM tooling such as Wazuh, Microsoft Sentinel, or Splunk.
5. Schedule regular patching, vulnerability scanning, and configuration reviews.
EOF

  log "Hardening summary written to ${REPORT_DIR}/hardening-summary.txt"
}

main() {
  require_root
  require_ubuntu
  validate_port
  prepare_reports

  log "Starting Ubuntu Server Hardening Blue Team Toolkit."
  capture_baseline
  install_packages
  run_lynis "pre-hardening"

  if [[ "${AUDIT_ONLY}" == "true" ]]; then
    log "Audit-only mode selected. No hardening changes applied."
    write_summary
    exit 0
  fi

  configure_admin_user
  lock_root_account
  configure_banner
  configure_ssh
  configure_firewall
  configure_fail2ban
  configure_sysctl
  configure_audit_logging
  configure_limits
  configure_permissions
  rkhunter_baseline
  capture_after
  run_lynis "post-hardening"
  write_summary

  log "Completed. Review evidence in ${REPORT_DIR}"
  log "Important: keep your current SSH session open and test a new SSH session before logging out."
}

main "$@"
