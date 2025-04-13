#!/bin/bash

# --- Functions ---

# Show help message
usage() {
    echo "Usage: $0 -d <domain> -w <wordlist> [-r <resolvers>] [-o <output_dir>] [-h]"
    echo
    echo "Options:"
    echo "  -d <domain>              Domain for DNS brute-forcing (can include https://)."
    echo "  -w <wordlist>            Wordlist for DNS brute-forcing."
    echo "  -r <resolvers>           Comma-separated list of resolvers (default: 8.8.8.8,4.2.2.4)."
    echo "  -o <output_dir>          Directory to store output (default: dnsb-static)."
    echo "  -h                       Display this help message."
    exit 0
}

# Parse input arguments
parse_args() {
    RESOLVERS="8.8.8.8,4.2.2.4"
    OUTPUT_DIR="dnsb-static"

    while getopts "d:w:r:o:h" opt; do
        case $opt in
            d) DOMAIN=$OPTARG ;;
            w) WORDLIST=$(realpath "$OPTARG") ;;  # Resolve realpath for wordlist
            r) RESOLVERS=$OPTARG ;;
            o) OUTPUT_DIR=$OPTARG ;;
            h) usage ;;
            *) echo "Invalid option: $opt"; usage ;;
        esac
    done

    if [ -z "$DOMAIN" ] || [ -z "$WORDLIST" ]; then
        usage
        exit 1
    fi

    # Sanitize domain input
    DOMAIN_CLEAN=$(echo "$DOMAIN" | sed -E 's~https?://~~' | cut -d '/' -f1)
}

# Set up environment
setup_environment() {
    mkdir -p "$OUTPUT_DIR"
    cd "$OUTPUT_DIR" || exit 1
    echo "$RESOLVERS" | tr ',' '\n' > resolvers
}

# Run shuffledns
run_shuffledns() {
    echo "[*] Running shuffledns on $DOMAIN_CLEAN..."
    shuffledns -d "$DOMAIN_CLEAN" -w "$WORDLIST" -mode bruteforce -silent -r resolvers -o static.lives
    echo "[*] Number of live subdomains: $(wc -l < static.lives)"
}

# --- Main ---

main() {
    parse_args "$@"
    setup_environment
    run_shuffledns
}

main "$@"

