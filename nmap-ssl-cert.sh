#!/usr/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <CIDR>"
    exit 1
fi

CIDR=$1
OUTPUT_FILE="$(echo $CIDR | tr '/' '_').xml"

nmap -p 443 --script ssl-cert "$CIDR" -oX "$OUTPUT_FILE"

