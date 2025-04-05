#!/bin/bash

# Initialize color codes first since they're used by logging
declare -A COLORS
COLORS=(
    ["RED"]="\033[0;31m"
    ["GREEN"]="\033[0;32m"
    ["YELLOW"]="\033[1;33m"
    ["BLUE"]="\033[0;34m"
    ["PURPLE"]="\033[0;35m"
    ["CYAN"]="\033[0;36m"
    ["NC"]="\033[0m"  # No Color
    ["INFO"]="\033[0;34m"      # Blue
    ["SUCCESS"]="\033[0;32m"   # Green
    ["WARNING"]="\033[1;33m"   # Yellow
    ["ERROR"]="\033[0;31m"     # Red
    ["RUNNING"]="\033[0;36m"   # Cyan
    ["SKIPPED"]="\033[0;35m"   # Purple
)

# Initialize icons
declare -A ICONS
ICONS=(
    ["INFO"]="ℹ"
    ["SUCCESS"]="✓"
    ["WARNING"]="⚠"
    ["ERROR"]="✗"
    ["RUNNING"]="⟳"
    ["SKIPPED"]="⏭"
)

# Intensity level definitions
declare -A INTENSITY_LEVELS
INTENSITY_LEVELS=(
    ["1"]="Low"
    ["2"]="Normal"
    ["3"]="High"
)

# Tool configurations for different intensity levels
declare -A TOOL_CONFIGS
TOOL_CONFIGS=(
    # WhatWeb configurations
    ["whatweb:1"]="-v -a 1"
    ["whatweb:2"]="-v -a 2"
    ["whatweb:3"]="-v -a 4"

    # WPScan configurations
    ["wpscan:1"]="--enumerate"
    ["wpscan:2"]="--enumerate p,u1-20"
    ["wpscan:3"]="--enumerate ap,at,cb,dbe,u1-100,m,tt --plugins-detection aggressive"

    # Nmap configurations
    ["nmap:1"]="-sV -T2 -Pn"
    ["nmap:2"]="-sV -T3 -Pn"
    ["nmap:3"]="-sV -T4 -Pn --script=vuln,http-enum,http-headers,http-methods,http-title"

    # Gobuster configurations
    ["gobuster:1"]="--threads 5"
    ["gobuster:2"]="--threads 10"
    ["gobuster:3"]="--threads 20"

    # FFuf configurations
    ["ffuf:1"]="-t 20"
    ["ffuf:2"]="-t 50"
    ["ffuf:3"]="-t 100"
)

# Default wordlists and configurations
DIRECTORY_WORDLIST="/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt"
FILE_WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-large-files.txt"
VHOST_WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
CUSTOM_EXTENSIONS="php,txt,html,js,env,bak,old,backup,sql,zip,tar.gz"
HTTP_STATUS_CODES="200,201,301,302,307,401,403,405,500"

# Default timeout values (in seconds)
COMMAND_TIMEOUT=300
CONNECTION_TIMEOUT=5
SCAN_TIMEOUT=3600  # 1 hour
