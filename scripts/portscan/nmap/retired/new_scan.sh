#!/bin/bash

TARGET_IP=$1

# Check if target IP is provided
if [ -z "$TARGET_IP" ]; then
    echo "Usage: $0 <target_ip>"
    exit 1
fi


echo "[+] Starting initial quick scan for top 20 ports..."
nmap -T4 -v -p- --top-ports 20 $TARGET_IP -oX scannyscan1.xml

echo "[+] Starting scan in batches..."
nmap -sS -p 1-1000 -T4 -oX scannyscan2.xml -v $TARGET_IP
# nmap -sS -p 1001-10000 -T4 -oA tcp_scan_1001-10000 -v $TARGET_IP
# nmap -sS -p 10001-65535 -T4 -oA tcp_scan_10001-65535 -v $TARGET_IP

for file in scannyscan1.xml scannyscan2.xml; do
    echo "[+] Parsing $file..."
    python3 -c 'import sys, xml.etree.ElementTree as ET
tree = ET.parse("scannyscan2.xml")
root = tree.getroot()
for port in root.findall(".//port"):
    state = port.find("state").get("state")
    if state == "open":
        portid = port.get("portid")
        protocol = port.get("protocol")
        service_elem = port.find("service")
        if service_elem is not None:
            service_name = service_elem.get("name", "unknown")
            product = service_elem.get("product", "")
            version = service_elem.get("version", "")
            extrainfo = service_elem.get("extrainfo", "")
            
            service_details = service_name
            if product:
                service_details += f" ({product}"
                if version:
                    service_details += f" {version}"
                if extrainfo:
                    service_details += f", {extrainfo}"
                service_details += ")"
        else:
            service_details = "unknown"
            
        print(f"Port {portid}/{protocol} - {service_details} is open")'
    
    done