#!/bin/bash

# Usage: ./script.sh -d <domain> [-g] [-r] [-l] [-f] [--no-httpx]

run_gospider=false
run_robofinder=false
run_linkfinder=false
run_fallparams=false
no_httpx=false

# Parse options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -d) domain="$2"; shift ;;
    -g) run_gospider=true ;;
    -r) run_robofinder=true ;;
    -l) run_linkfinder=true ;;
    -f) run_fallparams=true ;;
    --no-httpx) no_httpx=true ;;
    *) echo "Unknown parameter passed: $1" >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$domain" ]; then
  echo "❌ Domain is required. Usage: $0 -d <domain> [-g] [-r] [-l] [-f] [--no-httpx]"
  exit 1
fi

mkdir n-recon > /dev/null 2>&1
cd n-recon
mkdir -p gospider robofinder linkfinder fallparams

# ---------- Gospider ----------
if [ "$run_gospider" = true ]; then
  echo "🕷️ Running Gospider..."
  gospider -s "$domain" --sitemap --robots --subs --other-source --include-subs --include-other-source --quiet --output gospider
  cat gospider/* | uniq -u > gospider/gospider-out
  gf urls-js gospider/gospider-out > gospider/gospider-jss
  gf urls gospider/gospider-out | grep -vE "\.js$" > gospider/gospider-urls
  gf urls-rel gospider/gospider-out > gospider/gospider-rels
fi

# ---------- Robofinder ----------
if [ "$run_robofinder" = true ]; then
  echo "🤖 Running Robofinder..."
  robofinder -s -c -u "$domain" --debug --threads 500 | uniq -u > robofinder/robofinder-out
  gf urls-js robofinder/robofinder-out > robofinder/robofinder-jss
  gf urls robofinder/robofinder-out > robofinder/robofinder-urls
  gf urls-rel robofinder/robofinder-out > robofinder/robofinder-rels
fi

# ---------- Merge ----------
echo "🔀 Merging JS/Normal/Rel URLs..."
cat gospider/gospider-jss robofinder/robofinder-jss 2>/dev/null | sort | uniq -u > all-jss
cat gospider/gospider-urls robofinder/robofinder-urls 2>/dev/null | sort | uniq -u > all-urls
cat gospider/gospider-rels robofinder/robofinder-rels 2>/dev/null | sort | uniq -u > all-rels

if [ "$no_httpx" = false ]; then
  echo "🌐 Verifying URLs with httpx..."
  httpx -silent -nc -t 200 < all-jss > all-jss.tmp && mv all-jss.tmp all-jss
  httpx -silent -nc -t 200 < all-urls > all-urls.tmp && mv all-urls.tmp all-urls
  httpx -silent -nc -t 200 < all-rels > all-rels.tmp && mv all-rels.tmp all-rels
else
  echo "🚫 Skipping httpx (as requested via --no-httpx)"
fi

# ---------- Linkfinder ----------
# Function to convert relative or protocol-relative URLs to full URLs
convert_to_full_url() {
    local base_url="$1"
    local url="$2"
    
    # If the URL is already full (contains http:// or https://)
    if [[ "$url" =~ ^https?:// ]]; then
        echo "$url"
    # If the URL is protocol-relative (starts with //)
    elif [[ "$url" =~ ^// ]]; then
        # Prepend the base URL's protocol (assuming https here)
        echo "https:$url"
    # If the URL is relative (starts with /)
    elif [[ "$url" =~ ^/ ]]; then
        # Prepend the base URL to the relative URL
        echo "$base_url$url"
    else
        # If it's a complete URL (not relative), return it as is
        echo "$base_url/$url"
    fi
}

if [ "$run_linkfinder" = true ]; then
  echo "🔍 Running Linkfinder..."
  while read -r url; do 

      base_url=$(echo "$url" | awk -F/ '{print $1 "//" $2}')

      linkfinder -i "$url" -o cli > linkfinder/tmp-res

      while read -r result_url; do
          full_url=$(convert_to_full_url "$base_url" "$result_url")
          echo "$full_url" >> linkfinder/tmp-res-pruned
      done < linkfinder/tmp-res

      cat linkfinder/tmp-res-pruned | anew linkfinder/linkfinder-out > /dev/null

      rm linkfinder/tmp-res linkfinder/temp-linkfinder-out-pruned
  done < all-jss

  gf urls-js linkfinder/linkfinder-out > linkfinder/linkfinder-jss
  gf urls linkfinder/linkfinder-out > linkfinder/linkfinder-urls
  gf urls-rel linkfinder/linkfinder-out > linkfinder/linkfinder-rels

  cat linkfinder/linkfinder-jss | anew all-jss > /dev/null
  cat linkfinder/linkfinder-urls | anew all-urls > /dev/null
  cat linkfinder/linkfinder-rels | anew all-rels > /dev/null
fi

cat all-jss all-urls all-rels | unfurl -u keys > fallparams/urls-params

# ---------- Fallparams ----------
if [ "$run_fallparams" = true ]; then
  echo "🎯 Running Fallparams..."
  cat all-jss all-urls > fallparams/fallparams-input
  fallparams -u fallparams/fallparams-input -silent -o params 
  cat urls-params | anew fallparams/params
fi

# ---------- Rel2Full ----------
/hunt/tools/rel2full.sh -b $domain -f all-rels > full-rels

httpx -silent -nc -t 200 -l full-rels | anew all-urls > /dev/null

echo "✅ Done."

