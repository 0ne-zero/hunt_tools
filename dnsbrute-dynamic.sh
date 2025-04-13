#!/bin/bash

# --- Functions ---

# Show help message
usage() {
    echo "Usage: $0 -s <subdomains_file> -w <wordlist> [-o <output_dir>] [-n]"
    echo
    echo "Options:"
    echo "  -s <subdomains_file>    File containing subdomains to brute-force."
    echo "  -w <wordlist>           Wordlist for DNS brute-forcing."
    echo "  -o <output_dir>         Output directory (default: dnsb-dynamic)."
    echo "  -n                      Skip DNS resolution step with dnsx."
    echo "  -h                      Display this help message."
    exit 0
}

# Parse input arguments
parse_args() {
    OUTPUT_DIR="dnsb-dynamic"
    RESOLVE=true

    while getopts "s:w:o:nh" opt; do
        case $opt in
            s) SUBDOMAINS_FILE=$(realpath "$OPTARG") ;;  # Resolve realpath for subdomains file
            w) WORDLIST=$(realpath "$OPTARG") ;;         # Resolve realpath for wordlist
            o) OUTPUT_DIR=$OPTARG ;;
            n) RESOLVE=false ;;
            h) usage ;;
            *) echo "[!] Invalid option: -$OPTARG"; usage ;;
        esac
    done

    if [ -z "$SUBDOMAINS_FILE" ] || [ -z "$WORDLIST" ]; then
        usage
        exit 1
    fi
}

# Sanitize subdomains: remove http(s):// prefixes
sanitize_subdomains_file() {
    echo "[*] Sanitizing subdomains file..."
    SANITIZED_FILE="sanitized_subdomains"
    sed -E 's~https?://~~g' "$SUBDOMAINS_FILE" | cut -d '/' -f1 | sort -u > "$SANITIZED_FILE"
}

# Prepare output directory
setup_environment() {
    mkdir -p "$OUTPUT_DIR"
    cd "$OUTPUT_DIR" || exit 1
}

# Run ripgen
run_ripgen() {
    echo "[*] Running ripgen on subdomains:"
    ripgen -d "$SANITIZED_FILE" -w "$WORDLIST" > ripgen.subs
    echo "[*] Count of ripgen generated subdomains: $(wc -l < ripgen.subs)"
}

# Run alterx
run_alterx() {
    echo "[*] Running alterx on subdomains..."
    alterx -pp word="$WORDLIST" -silent -en < "$SANITIZED_FILE"  > alterx.subs
    echo "[*] Count of alterx generated subdomains: $(wc -l < alterx.subs)"
}

# Merge and deduplicate
merge_results() {
    cat ripgen.subs alterx.subs | sort -u > dynamic.subs
    echo "[*] Total generated subdomains: $(wc -l < dynamic.subs)"
}

# Resolve with dnsx
run_dnsx() {
    if [ "$RESOLVE" = true ]; then
        echo "[*] Resolving with dnsx..."
        dnsx -l dynamic.subs -t 200 -silent > dynamic.lives
        echo "[*] Number of live subdomains: $(wc -l < dynamic.lives)"
    else
        echo "[*] Skipping dnsx step (-n used)"
    fi
}

# --- Main ---

main() {
    parse_args "$@"
    setup_environment
    sanitize_subdomains_file
    if [ -s $SANITIZED_FILE ]; then
        run_alterx
        run_ripgen
        merge_results
        run_dnsx
    else
        echo "There is no subdomains"
    fi
}

main "$@"

