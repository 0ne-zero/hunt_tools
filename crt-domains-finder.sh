#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 -d DOMAIN [-h]"
    echo
    echo "Finds unique domains from crt.sh for the specified organization."
    echo
    echo "Options:"
    echo "  -d DOMAIN  Specify the organization name to search for."
    echo "  -h         Show this help message."
    echo
    echo "Example:"
    echo "  $0 -d \"tesla.com\""
}

# Initialize variables
DOMAIN=""

# Check for options
while getopts ":d:h" option; do
    case $option in
        d)
            DOMAIN="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

# Check if DOMAIN is provided
if [ -z "$DOMAIN" ]; then
    echo "Error: Domain not specified." >&2
    show_help
    exit 1
fi

# Main command to find domains
curl -s "https://crt.sh/json?q=$DOMAIN" | jq -r '.[] | .common_name, .name_value' | sort -u | unfurl -u format %r.%t
