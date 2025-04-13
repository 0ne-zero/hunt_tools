sort $1 | uniq -c | sort -nr | sed 's|^ *||g' | cut -d ' ' -f 2
