#!/bin/bash

# Default values
IP_FILE=""
WORDLIST=""
SCHEME="http"
STATUS_CODE="200"

# Help message
usage() {
  echo "Usage: $0 -i cidr.txt -w subdomains.txt [-s http|https] [-c status_code]"
  echo ""
  echo "  -i FILE      File containing list of IPs or CIDRs"
  echo "  -w FILE      Subdomain wordlist"
  echo "  -s SCHEME    Scheme (http or https), default: http"
  echo "  -c CODE      Match HTTP status code, default: 200"
  exit 1
}

# Parse flags
while getopts ":i:w:s:c:" opt; do
  case ${opt} in
    i ) IP_FILE=$OPTARG ;;
    w ) WORDLIST=$OPTARG ;;
    s ) SCHEME=$OPTARG ;;
    c ) STATUS_CODE=$OPTARG ;;
    * ) usage ;;
  esac
done

# Check required arguments
if [[ -z "$IP_FILE" || -z "$WORDLIST" ]]; then
  usage
fi

# Loop through IPs
while IFS= read -r ip; do
  echo "[*] Target: $ip"
  ffuf -w "$WORDLIST" \
       -u "$SCHEME://$ip" \
       -H "Host: FUZZ" \
       -s \
       -mc "$STATUS_CODE"
done < "$IP_FILE"

