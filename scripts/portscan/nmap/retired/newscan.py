#!/usr/bin/env python3

import sys
import subprocess
import xml.etree.ElementTree as ET

def run_command(command):
    """
    Executes a shell command and returns the output and exit code.
    """
    try:
        result = subprocess.run(command, capture_output=True, text=True, shell=True)
        return result.stdout, result.stderr, result.returncode
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)

def parse_xml(xml_file):
    """
    Parses an Nmap XML file and prints open ports and service details.
    """
    retval = []
    try:
        tree = ET.parse(xml_file)
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

                retval += [[portid, protocol, service_details]]
        
        return retval
    except FileNotFoundError:
        print(f"Error: XML file not found: {xml_file}")
        sys.exit(1)
    except ET.ParseError as e:
        print(f"Error parsing XML file {xml_file}: {e}")
        sys.exit(1)


def portscan(target_ip):
    print("[+] Starting initial quick scan for top 20 ports...")
    quick_scan_file = "/tmp/quick_scan.xml"
    run_command(f"nmap -T4 -v --top-ports 20 {target_ip} -oX {quick_scan_file}")

    print("[+] Starting detailed scan for ports 1-1000...")
    detailed_scan_file1 = "/tmp/detailed_scan1.xml"
    run_command(f"nmap -sS -sC -sV -A -T5 -p 1-1000 -oX {detailed_scan_file1} -v {target_ip}")

    print("[+] Starting detailed scan for ports 1001-10000...")
    detailed_scan_file2 = "/tmp/detailed_scan2.xml"
    run_command(f"nmap -sS -sC -sV -A -T5 -p 1001-2000 -T4 -oX {detailed_scan_file2} -v {target_ip}")
    # run_command(f"nmap -sS -p 1001-10000 -T4 -oX {detailed_scan_file2} -v {target_ip}")

    # print("[+] Starting detailed scan for ports 10001-65535...")
    # detailed_scan_file3 = "detailed_scan3.xml"
    # run_command(f"nmap -sS -sC -sV -A -T5 -p 10001-65535 -T4 -oX {detailed_scan_file3} -v {target_ip}")

    #scan_files = [quick_scan_file, detailed_scan_file1, detailed_scan_file2, detailed_scan_file3]
    scan_files = [quick_scan_file, detailed_scan_file1, detailed_scan_file2]
    openports = {}
    for scan_file in scan_files:
        print(f"[+] Parsing {scan_file}...")
        retval = parse_xml(scan_file)
        for portset in retval:
            openports[portset[0]] = portset[1:]
    print(openports)
    return openports


def runwpscan(target_url):
    print("[+] Running wpscan...")
    stdout, stderr, errno = run_command(f"wpscan --url {target_url} --enumerate ap,at,cb,dbe,u1-100,m,tt --plugins-detection aggressive")

    if errno != 0:
        print(f"Error running wpscan: {errno}")
    print(stdout)
    print(stderr)
        

def scan_for_folders(target_url):
    # known_http_ports = ["80", "443", "8080", "8000", "8443", "8888"]
    
    # SCAN FOR FOLDERS
    cmd_folder = f"ffuf -u {target_url}/FUZZ -x http://localhost:8080 -w /usr/share/seclists/Discovery/Web-Content/directory-list-lowercase-2.3-medium.txt -c -t 200 -recursion -recursion-depth 2 -v -o ffuf_folders.txt"

    # # SCAN FOR FILES
    # cmd_file = f"ffuf -u {target_url}/FUZZ -w /usr/share/seclists/Discovery/Web-Content/ -e .php,.txt,.html,.bak,.old -c -t 200 -recursion -recursion-depth 2 -v"
    scans = [cmd_folder]
    for scan in scans:
        print(f"[+] Running ffuf scan: {scan}")
        stdout, stderr, errno = run_command(scan)

        if errno != 0:
            print(f"Error running ffuf: {errno}")
        print(stdout)
        print(stderr)
    



def main():
    if len(sys.argv) != 3:
        print("Usage: ./new_scan.py <target_ip> <target_url>")
        sys.exit(1)

    target_ip = sys.argv[1]
    target_url = sys.argv[2]
    known_http_ports = ["80", "443", "8080", "8000", "8443", "8888"]
    
    # openports = portscan(target_ip)
    # print(openports)
    print(f"Known HTTP ports: {known_http_ports}")
    additional_ports = input("Do you want to mark any additional ports as HTTP ports? (y/n): ")
    if additional_ports.lower() == "y":
        additional_ports = input("Enter the ports separated by commas: ")
        known_http_ports += additional_ports.split(",")
        print(f"Updated known HTTP ports: {known_http_ports}")  

    openports = ["80"]
    for port in openports:
        if port in known_http_ports:
            print(f"[+] Found HTTP port: {port}")
            # runwpscan(target_url + ":" + port)

            if port == "80":
                print(f"[+] Running ffuf scan on {target_url}:{port}")
                scan_for_folders(target_url)
            else:
                print(f"[+] Running ffuf scan on {target_url}:{port}")
                scan_for_folders(target_url + ":" + port)


            break
    else:
        print("[-] No HTTP ports found.")


    
    

if __name__ == "__main__":
    main()