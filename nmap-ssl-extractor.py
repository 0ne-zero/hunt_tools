#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import sys

def parse_nmap_ssl_certs(xml_file):
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"Error parsing XML file: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"File not found: {xml_file}", file=sys.stderr)
        sys.exit(1)

    domains = set()

    for host in root.findall('.//host'):
        for port in host.findall('.//port'):
            script = port.find('.//script[@id="ssl-cert"]')
            if script is not None:
                # Get Common Name
                subject = script.find('.//table[@key="subject"]')
                if subject is not None:
                    cn = subject.find('.//elem[@key="commonName"]')
                    if cn is not None and cn.text:
                        domains.add(cn.text.lower())

                # Get Subject Alternative Names
                extensions = script.find('.//table[@key="extensions"]')
                if extensions is not None:
                    for ext in extensions.findall('.//table'):
                        name = ext.find('.//elem[@key="name"]')
                        if name is not None and name.text == "X509v3 Subject Alternative Name":
                            value = ext.find('.//elem[@key="value"]')
                            if value is not None and value.text:
                                # Parse all DNS entries from SAN
                                san_parts = value.text.split(',')
                                for part in san_parts:
                                    if 'DNS:' in part:
                                        domain = part.split('DNS:')[-1].strip().lower()
                                        if domain:
                                            domains.add(domain)

    return sorted(domains)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} nmap_results.xml", file=sys.stderr)
        sys.exit(1)

    domains = parse_nmap_ssl_certs(sys.argv[1])
    
    for domain in domains:
        print(domain)
