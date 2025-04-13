#!/bin/bash

# Default values
output=""

print_help() {
  echo "Usage: $0 -f <file> -b <base_url> [-o <output>]"
  echo
  echo "  -f FILE       File containing relative URLs"
  echo "  -b BASE_URL   Base URL to prepend"
  echo "  -o OUTPUT     (Optional) Output file to write full URLs to"
  echo "  -h            Show this help message"
  exit 1
}

# Parse flags
while getopts ":f:b:o:h" opt; do
  case $opt in
    f) file="$OPTARG" ;;
    b) base_url="$OPTARG" ;;
    o) output="$OPTARG" ;;
    h) print_help ;;
    \?) echo "❌ Invalid option: -$OPTARG" >&2; print_help ;;
    :) echo "❌ Option -$OPTARG requires an argument." >&2; print_help ;;
  esac
done

# Validate required inputs
if [[ -z "$file" || -z "$base_url" ]]; then
  echo "❌ Both -f and -b are required."
  print_help
fi

# Remove trailing slash from base_url
base_url="${base_url%/}"

# Output processing
process_url() {
  local url="$1"

  if [[ "$url" =~ ^https?:// ]]; then
    echo "$url"
  elif [[ "$url" =~ ^// ]]; then
    echo "https:$url"
  elif [[ "$url" =~ ^/ ]]; then
    echo "$base_url$url"
  else
    echo "$base_url/$url"
  fi
}

# Run conversion
while IFS= read -r url; do
  [ -z "$url" ] && continue
  result=$(process_url "$url")
  if [[ -n "$output" ]]; then
    echo "$result" >> "$output"
  else
    echo "$result"
  fi
done < "$file"

