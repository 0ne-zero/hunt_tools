#!/usr/bin/bash

script_dir=$(dirname "$0")

while IFS=' - ' read start_range end_range; do
    python3 "${script_dir}/ipv4_range_to_cidr.py" -s $start_range -e $end_range
done

