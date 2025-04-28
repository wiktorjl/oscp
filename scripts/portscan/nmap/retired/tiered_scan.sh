#!/bin/bash

# Check if an IP address is provided
if [ "$#" -ne 1 ]; then
    echo -e "\033[31mUsage: $0 <target_host>\033[0m"
    exit 1
fi

target_host=$1

# Banner
echo -e "\033[36mStarting Nmap Scans against: $target_host\033[0m"

# Basic Scan
echo -e "\033[32mStarting Basic Scan (Most common ports, super fast)\033[0m"
nmap --top-ports 1000 --open -T5 $target_host -oN "${target_host}_basic_scan.txt"
echo -e "\033[34mBasic scan results saved to ${target_host}_basic_scan.txt\033[0m"
sudo nmap -sU -top-ports=100 $target_host -oN "${target_host}_most_detailed_scan_udp_low.txt"
echo -e "\033[34mTop 100 UDP scan results saved to ${target_host}_most_detailed_scan_udp_low.txt\033[0m"

# Detailed Scan
echo -e "\033[32mStarting Detailed Scan\033[0m"
nmap -sC -sV $target_host -oN "${target_host}_detailed_scan.txt"
echo -e "\033[34mDetailed scan results saved to ${target_host}_detailed_scan.txt\033[0m"

# Most Detailed Scan including UDP
echo -e "\033[32mStarting Most Detailed Scan including UDP\033[0m"
nmap -sC -sV -p- $target_host -oN "${target_host}_most_detailed_scan.txt"
echo -e "\033[34mMost detailed scan results saved to ${target_host}_most_detailed_scan.txt\033[0m"
sudo nmap -sU -p1000-65000 $target_host -oN "${target_host}_most_detailed_scan_udp_high.txt"
echo -e "\033[34mAll port UDP scan results saved to ${target_host}_most_detailed_scan_udp_high.txt\033[0m"
