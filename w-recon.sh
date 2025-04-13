#!/bin/bash

# === Defaults ===
STATIC=false
DYNAMIC=false
OUTPUT_DIR="w-recon"

# === Helper: Show usage ===
usage() {
    echo "Usage:"
    echo "$0 -d <domain> | -dL <domain_list> [-sb -sbw <static_wordlist>] [-db -dbw <dynamic_wordlist>] [-o <output_dir>]"
    exit 1
}

# === Clean domain (strip URL scheme etc.) ===
clean_domain() {
    echo "$1" | sed -E 's~https?://~~' | cut -d'/' -f1
}

# === Resolve absolute path ===
resolve_path() {
    echo "$(realpath -m "$1")"
}

# === Parse args ===
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) DOMAIN="$2"; shift 2 ;;
            -dL) DOMAINS_FILE=$(resolve_path "$2"); shift 2 ;;
            -sb) STATIC=true; shift ;;
            -sbw) STATIC_WORDLIST=$(resolve_path "$2"); shift 2 ;;
            -db) DYNAMIC=true; shift ;;
            -dbw) DYNAMIC_WORDLIST=$(resolve_path "$2"); shift 2 ;;
            -o) OUTPUT_DIR=$(resolve_path "$2"); shift 2 ;;
            -h|--help) usage ;;
            *) echo "[!] Invalid option: $1"; usage ;;
        esac
    done

    if [[ -z "$DOMAIN" && -z "$DOMAINS_FILE" ]]; then
        usage
    fi

    if $STATIC && [[ -z "$STATIC_WORDLIST" ]]; then
        echo "[!] Static brute-force enabled but no wordlist (-sbw) provided."
        exit 1
    fi

    if $DYNAMIC; then
        if ! $STATIC; then
            echo "[!] Dynamic brute-force requires static brute-force (-sb)."
            exit 1
        fi
        if [[ -z "$DYNAMIC_WORDLIST" ]]; then
            echo "[!] Dynamic brute-force enabled but no wordlist (-dbw) provided."
            exit 1
        fi
    fi
}

# === Recon logic ===
recon_domain() {
    local input="$1"
    local domain=$(clean_domain "$input")
    local domain_output_dir="${OUTPUT_DIR}/${domain}"

    echo -e "\n---- Wide recon on: $domain ----"

    # Create domain-specific output directory
    mkdir -p "${domain_output_dir}/subfinder"
    mkdir -p "${domain_output_dir}/dnsb-static"
    mkdir -p "${domain_output_dir}/dnsb-dynamic"

    # Subfinder
    domain_subs_file="${domain_output_dir}/subfinder/${domain}.subs"
    if [[ ! -f "$domain_subs_file" ]]; then
        echo "[*] Running subfinder on $domain..."
        subfinder -d "$domain" -silent -all > "$domain_subs_file"
        echo "[*] Found: $(wc -l < "$domain_subs_file") subdomains"
    fi

    # DNS resolution
    domain_subs_live_file="${domain_output_dir}/subfinder/${domain}.lives"
    dnsx -l "$domain_subs_file" -t 250 -silent > "$domain_subs_live_file" < /dev/null
    echo "[*] Live: $(wc -l < "$domain_subs_live_file") subdomains"

    # Static brute-force
    if $STATIC; then
        static_dnsb_file="${domain_output_dir}/dnsb-static/static.lives"
        if [[ ! -f "$static_dnsb_file" ]]; then
            echo "[*] Static brute-force on $domain..."
            /hunt/tools/dnsbrute-static.sh -d "$domain" -w "$STATIC_WORDLIST" -o "${domain_output_dir}/dnsb-static/" > /dev/null
        fi

        if [[ -f "$static_dnsb_file" ]]; then
            echo "[*] Static live: $(wc -l < "$static_dnsb_file")"
            
            # Dynamic brute-force
            if $DYNAMIC; then
                if [[ ! -s "$domain_subs_file" && ! -s "$static_dnsb_file" ]]; then
                    echo "[!] No base subs for dynamic brute-force"
                else
                    dynamic_dnsb_file="${domain_output_dir}/dnsb-dynamic/dynamic.lives"
                    if [[ ! -f "$dynamic_dnsb_file" ]]; then
                        dynamic_dnsb_input_file="${domain_output_dir}/dnsb-dynamic/input_file"
                        cat "$domain_subs_file" "$static_dnsb_file" > "$dynamic_dnsb_input_file"

                        echo "[*] Dynamic brute-force on $domain..."
                        /hunt/tools/dnsbrute-dynamic.sh -s "$dynamic_dnsb_input_file" -w "$DYNAMIC_WORDLIST" -o "${domain_output_dir}/dnsb-dynamic/" > /dev/null
                    fi

                    if [[ -f "$dynamic_dnsb_file" ]]; then
                        echo "[*] Dynamic live: $(wc -l < "$dynamic_dnsb_file")"
                    fi
                fi
            fi
        fi
    fi

    # Merge all lives
    all_lives="${domain_output_dir}/${domain}.lives"
    touch "$all_lives"
    cat "$domain_subs_live_file" >> "$all_lives"
    [[ -s "${domain_output_dir}/dnsb-static/static.lives" ]] && cat "${domain_output_dir}/dnsb-static/static.lives" >> "$all_lives"
    [[ -s "${domain_output_dir}/dnsb-dynamic/dynamic.lives" ]] && cat "${domain_output_dir}/dnsb-dynamic/dynamic.lives" >> "$all_lives"
    sort -u "$all_lives" -o "$all_lives"
    echo "[*] Total live subs for $domain: $(wc -l < "$all_lives")"
}

# === Main ===
main() {
    parse_args "$@"
    mkdir -p "$OUTPUT_DIR"

    if [[ -n "$DOMAIN" ]]; then
        recon_domain "$DOMAIN"
    elif [[ -n "$DOMAINS_FILE" ]]; then
        while IFS= read -r domain || [[ -n "$domain" ]]; do
            [[ -n "$domain" ]] && recon_domain "$domain"
        done < "$DOMAINS_FILE"
    fi
}

main "$@"
