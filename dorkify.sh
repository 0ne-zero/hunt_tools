#!/bin/bash

GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

if [ -z "$1" ]; then
  echo -e "Usage: $0 <domain> [--open]"
  exit 1
fi

domain=$1
open_flag=$2

open_url() {
  if [[ "$open_flag" == "--open" ]]; then
    xdg-open "$1" >/dev/null 2>&1 &
    sleep 0.5
  fi
}

print_section() {
  echo -e "\n${BLUE}[$1]${RESET}"
}

generate_dorks() {
  local label=$1
  shift
  local dorks=("$@")

  print_section "$label"
  for dork in "${dorks[@]}"; do
    encoded=$(printf "%s" "$dork" | jq -s -R -r @uri)
    url="https://www.google.com/search?q=$encoded"
    echo "$url"
    open_url "$url"
  done
}

echo -e "${GREEN}[*] Generating categorized Google Dorks for: ${BLUE}$domain${RESET}"

generate_dorks "General" \
  "site:$domain" \
  "site:*.${domain} -www.${domain}" \
  "site:$domain -www.$domain" \
  "site:*.$domain"

generate_dorks "Login & Admin Panels" \
  "site:$domain inurl:login" \
  "site:$domain inurl:admin" \
  "site:$domain inurl:dashboard" \
  "site:$domain intitle:\"admin login\"" \
  "site:$domain inurl:signin | inurl:signup"

generate_dorks "Development & Testing" \
  "site:$domain inurl:test" \
  "site:$domain inurl:dev" \
  "site:$domain inurl:staging" \
  "site:$domain inurl:beta"

generate_dorks "File Leaks & Indexes" \
  "site:$domain ext:log | ext:bak | ext:old | ext:backup" \
  "site:$domain ext:env | ext:sql | ext:conf" \
  "site:$domain intitle:\"index of\" \"backup\"" \
  "site:$domain \"Index of /\" +log" \
  "site:$domain filetype:env" \
  "site:$domain ext:log"

generate_dorks "Secrets & Keys" \
  "site:$domain \"api_key\" OR \"secret_key\"" \
  "site:$domain \"Authorization: Bearer\"" \
  "site:$domain \"X-Api-Key\"" \
  "site:$domain password filetype:env"

generate_dorks "Sensitive Info & Disclosure" \
  "site:$domain \"confidential\"" \
  "site:$domain \"internal use only\"" \
  "site:$domain \"not for distribution\""

generate_dorks "JavaScript Recon" \
  "site:$domain ext:js" \
  "site:$domain filetype:js inurl:config" \
  "site:$domain filetype:js \"var api\""

generate_dorks "Public Buckets & External Leaks" \
  "site:drive.google.com \"$domain\"" \
  "site:docs.google.com \"$domain\"" \
  "site:trello.com \"$domain\"" \
  "site:pastebin.com \"$domain\"" \
  "site:github.com \"$domain\" password" \
  "site:github.com \"$domain\" api_key" \
  "site:gitlab.com \"$domain\""

generate_dorks "Miscellaneous & Interesting" \
  "site:$domain inurl:phpinfo" \
  "site:$domain \"X-Powered-By:\""

echo -e "\n${GREEN}[✓] Done. ${open_flag:+Opened in browser.}${RESET}"

