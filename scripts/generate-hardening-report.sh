#!/usr/bin/env bash
# Generate a human-readable Markdown report from the latest Ubuntu hardening evidence.
# Run after scripts/ubuntu-hardening.sh has completed.

set -Eeuo pipefail

REPORT_DIR="/var/log/server-hardening/latest"
OUTPUT_DIR="${OUTPUT_DIR:-}"
OUTPUT_FILE="${OUTPUT_FILE:-}"

usage() {
    cat <<USAGE
Generate a human-readable Markdown hardening report.

Usage:
  sudo ./scripts/generate-hardening-report.sh [options]

Options:
  --report-dir <path>     Evidence directory. Default: /var/log/server-hardening/latest
  --output-dir <path>     Output directory. Default: repository/evidence if detected, else current directory/evidence
  --output-file <path>    Full output file path. Overrides --output-dir
  -h, --help              Show this help

Examples:
  sudo ./scripts/generate-hardening-report.sh
  sudo ./scripts/generate-hardening-report.sh --output-dir ./evidence
  sudo ./scripts/generate-hardening-report.sh --report-dir /var/log/server-hardening/20260623-193941
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --report-dir) REPORT_DIR="${2:-}"; shift 2 ;;
        --output-dir) OUTPUT_DIR="${2:-}"; shift 2 ;;
        --output-file) OUTPUT_FILE="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ ! -d "$REPORT_DIR" ]]; then
    echo "ERROR: Report directory not found: $REPORT_DIR" >&2
    echo "Run sudo ./scripts/ubuntu-hardening.sh first." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "$OUTPUT_FILE" ]]; then
    if [[ -z "$OUTPUT_DIR" ]]; then
        if [[ -d "${REPO_ROOT}/evidence" ]]; then
            OUTPUT_DIR="${REPO_ROOT}/evidence"
        else
            OUTPUT_DIR="$(pwd)/evidence"
        fi
    fi
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_FILE="${OUTPUT_DIR}/hardening-report.md"
else
    mkdir -p "$(dirname "$OUTPUT_FILE")"
fi

read_file_or_note() {
    local file="$1" note="$2"
    if [[ -r "$file" ]]; then
        cat "$file"
    else
        echo "$note"
    fi
}

section_from_file() {
    local title="$1" file="$2" note="$3"
    echo "## ${title}"
    echo
    echo '```text'
    read_file_or_note "$file" "$note"
    echo '```'
    echo
}

section_from_command() {
    local title="$1" fallback="$2"; shift 2
    echo "## ${title}"
    echo
    echo '```text'
    "$@" 2>/dev/null || echo "$fallback"
    echo '```'
    echo
}

{
    echo "# Ubuntu Server Hardening Evidence Report"
    echo
    echo "Generated on: $(date)"
    echo "Evidence source: ${REPORT_DIR}"
    echo
    echo "> This report is a human-readable summary generated from hardening evidence files. Review and sanitize before publishing screenshots or excerpts publicly."
    echo

    section_from_file "1. Hardening Summary" "${REPORT_DIR}/hardening-summary.txt" "hardening-summary.txt not found"

    section_from_command "2. Lynis Hardening Index" "Hardening index not found" \
        grep -i "hardening index" "${REPORT_DIR}/lynis-post-hardening.log"

    section_from_command "3. Lynis Warnings" "No Lynis warnings found or Lynis log unavailable" \
        bash -c "grep -i 'warning' '${REPORT_DIR}/lynis-post-hardening.log' | head -80"

    section_from_command "4. Lynis Suggestions" "No Lynis suggestions found or Lynis log unavailable" \
        bash -c "grep -i 'suggestion' '${REPORT_DIR}/lynis-post-hardening.log' | head -80"

    section_from_file "5. Firewall Status" "${REPORT_DIR}/ufw-status-final.txt" "ufw-status-final.txt not found"

    if [[ -r "${REPORT_DIR}/fail2ban-sshd-status.txt" ]]; then
        section_from_file "6. Fail2Ban SSH Jail Status" "${REPORT_DIR}/fail2ban-sshd-status.txt" "fail2ban-sshd-status.txt not found"
    else
        section_from_file "6. Fail2Ban Status" "${REPORT_DIR}/fail2ban-status.txt" "Fail2Ban status file not found"
    fi

    section_from_command "7. SSH Effective Configuration - Key Controls" "SSH effective configuration not found" \
        bash -c "grep -iE '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|clientalive|tcpkeepalive|x11forwarding|allowtcpforwarding|allowagentforwarding|maxauthtries|maxsessions|loglevel|banner)' '${REPORT_DIR}/sshd-effective-config.txt'"

    section_from_file "8. SSH Service Status" "${REPORT_DIR}/ssh-service-status.txt" "ssh-service-status.txt not found"
    section_from_file "9. Listening Ports After Hardening" "${REPORT_DIR}/listening-ports-after.txt" "listening-ports-after.txt not found"

    section_from_command "10. Enabled Services After Hardening - First 100 Lines" "enabled-services-after.txt not found" \
        bash -c "head -100 '${REPORT_DIR}/enabled-services-after.txt'"

    section_from_file "11. Auditd Status" "${REPORT_DIR}/auditd-status.txt" "auditd-status.txt not found"

    echo "## 12. Follow-up Actions"
    echo
    echo "- Review remaining Lynis warnings and suggestions."
    echo "- Confirm application-specific ports and services."
    echo "- Test SSH key access from a second terminal before disabling SSH password authentication."
    echo "- Integrate logs with Wazuh, Microsoft Sentinel, or Splunk."
    echo "- Schedule regular patching, vulnerability scanning and configuration reviews."
    echo
} > "$OUTPUT_FILE"

TARGET_USER="${SUDO_USER:-}"
if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]]; then
    chown "$TARGET_USER:$TARGET_USER" "$OUTPUT_FILE" 2>/dev/null || true
fi

chmod 644 "$OUTPUT_FILE" || true

echo "Markdown report created: $OUTPUT_FILE"
