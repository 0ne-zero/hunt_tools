#!/usr/bin/env python3

try:
    import sys
    import argparse
    from netaddr import iprange_to_cidrs
    
    parser = argparse.ArgumentParser(description="Convert IP range to CIDR")
    parser.add_argument("-s", "--start", required=True, help="Starting IP address")
    parser.add_argument("-e", "--end", required=True, help="Ending IP address")
    
    args = parser.parse_args()
    cidrs = iprange_to_cidrs(args.start, args.end)
    for cidr in cidrs:
        print(cidr)
except KeyboardInterrupt:
    sys.exit(1)
