#!/bin/bash

INPUT=""
OUTPUT=""

usage() {
  echo "Usage: $0 -i <CIDR | file_with_CIDRs> [-o <output_file>]"
  echo ""
  echo "Options:"
  echo "  -i   CIDR block or a file containing CIDRs"
  echo "  -o   (Optional) Output file to write results"
  echo "  -h   Show help"
  exit 1
}

# Parse arguments
while getopts ":i:o:h" opt; do
  case "$opt" in
    i) INPUT="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "[!] -i is required" >&2
  usage
fi

if ! command -v nmap &>/dev/null; then
  echo "[!] nmap is not installed" >&2
  exit 1
fi

expand_cidr() {
  local cidr=$1
  [[ -z "$cidr" || "$cidr" == \#* ]] && return

  nmap -n -sL "$cidr" | awk '/Nmap scan report/{print $NF}'
}

# Detect if INPUT is a file
if [[ -f "$INPUT" ]]; then
  while IFS= read -r cidr; do
    result=$(expand_cidr "$cidr")
    if [[ -n "$OUTPUT" ]]; then
      echo "$result" >> "$OUTPUT"
    else
      echo "$result"
    fi
  done < "$INPUT"
else
  result=$(expand_cidr "$INPUT")
  if [[ -n "$OUTPUT" ]]; then
    echo "$result" >> "$OUTPUT"
  else
    echo "$result"
  fi
fi

