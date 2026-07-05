#!/usr/bin/env bash
# Convert evidence/hardening-report.md into HTML or PDF using pandoc.

set -Eeuo pipefail

INPUT_FILE="evidence/hardening-report.md"
FORMAT="html"
OUTPUT_FILE=""
INSTALL_DEPS=false

usage() {
    cat <<USAGE
Convert the generated Markdown hardening report to HTML or PDF.

Usage:
  ./scripts/convert-hardening-report.sh [options]

Options:
  --input <file>        Markdown input file. Default: evidence/hardening-report.md
  --format <html|pdf>   Output format. Default: html
  --output <file>       Output file path. Default: evidence/hardening-report.<format>
  --install-deps        Install pandoc and PDF dependencies using apt. Requires sudo.
  -h, --help            Show this help

Examples:
  ./scripts/convert-hardening-report.sh --format html
  ./scripts/convert-hardening-report.sh --format pdf --install-deps
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input) INPUT_FILE="${2:-}"; shift 2 ;;
        --format) FORMAT="${2:-}"; shift 2 ;;
        --output) OUTPUT_FILE="${2:-}"; shift 2 ;;
        --install-deps) INSTALL_DEPS=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ "$FORMAT" != "html" && "$FORMAT" != "pdf" ]]; then
    echo "ERROR: --format must be html or pdf" >&2
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "ERROR: Input file not found: $INPUT_FILE" >&2
    echo "Run: sudo ./scripts/generate-hardening-report.sh" >&2
    exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="${INPUT_FILE%.md}.${FORMAT}"
fi

if [[ "$INSTALL_DEPS" == true ]]; then
    sudo apt-get update
    if [[ "$FORMAT" == "pdf" ]]; then
        sudo apt-get install -y pandoc texlive-xetex texlive-fonts-recommended
    else
        sudo apt-get install -y pandoc
    fi
fi

if ! command -v pandoc >/dev/null 2>&1; then
    echo "ERROR: pandoc is not installed." >&2
    echo "Install it with: sudo apt install -y pandoc" >&2
    echo "For PDF output also install: sudo apt install -y texlive-xetex texlive-fonts-recommended" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

if [[ "$FORMAT" == "html" ]]; then
    pandoc "$INPUT_FILE" \
        --standalone \
        --metadata title="Ubuntu Server Hardening Evidence Report" \
        -o "$OUTPUT_FILE"
else
    pandoc "$INPUT_FILE" \
        --pdf-engine=xelatex \
        --metadata title="Ubuntu Server Hardening Evidence Report" \
        -o "$OUTPUT_FILE"
fi

echo "Converted report created: $OUTPUT_FILE"
