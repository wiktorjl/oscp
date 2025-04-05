#!/bin/bash

# Function: Initial reconnaissance
run_initial_recon() {
    log "INFO" "RECON" "START" "Starting initial reconnaissance"

    # Ping check
    if run_command "ping -c 1 ${TARGET_IP}" "ICMP ping check"; then
        log "SUCCESS" "RECON" "PING" "Host is responding to ICMP"
    else
        log "WARNING" "RECON" "PING" "Host is not responding to ICMP, continuing anyway"
    fi

    # Basic port check
    if run_command "nc -zv -w ${CONNECTION_TIMEOUT} ${TARGET_IP} ${PORT}" "Port connectivity check"; then
        log "SUCCESS" "RECON" "PORT" "Port ${PORT} is open"
    else
        log "ERROR" "RECON" "PORT" "Port ${PORT} is not accessible"
        prompt_continue "Continue despite port being inaccessible?"
    fi
}

# Function: Service discovery
run_service_discovery() {
    log "INFO" "DISCOVERY" "START" "Starting service discovery"

    local nmap_intensity="${TOOL_CONFIGS[nmap:${INTENSITY}]:-${TOOL_CONFIGS[nmap:2]}}"
    local nmap_cmd="nmap ${nmap_intensity} -p${PORT} ${TARGET_IP}"

    if run_command "${nmap_cmd}" "Nmap service scan"; then
        local service_info
        service_info=$(grep -i "open" "${TEMP_DIR}/Nmap_service_scan.out" 2>/dev/null || echo "No service information found")
        log "INFO" "DISCOVERY" "SERVICE" "Detected services: ${service_info}"
    fi
}

# Function: Web fingerprinting
run_web_fingerprinting() {
    log "INFO" "FINGERPRINT" "START" "Starting web service fingerprinting"

    local whatweb_intensity="${TOOL_CONFIGS[whatweb:${INTENSITY}]:-${TOOL_CONFIGS[whatweb:2]}}"
    local whatweb_cmd="whatweb ${whatweb_intensity} http://${TARGET_IP}:${PORT}"

    if run_command "${whatweb_cmd}" "WhatWeb scan"; then
        cp "${TEMP_DIR}/WhatWeb_scan.out" "${RESULTS_DIR}/whatweb_results.txt"

        if grep -i "wordpress" "${TEMP_DIR}/WhatWeb_scan.out" >/dev/null 2>&1; then
            WORDPRESS_DETECTED=true
            log "INFO" "FINGERPRINT" "CMS" "WordPress detected"
        fi
    fi
}

# Function: WordPress specific scanning
run_wordpress_scan() {
    if [[ "${WORDPRESS_DETECTED:-false}" != true ]]; then
        log "INFO" "WORDPRESS" "SKIP" "WordPress not detected, skipping WPScan"
        return 0
    fi

    log "INFO" "WORDPRESS" "START" "Starting WordPress scan"

    local wpscan_intensity="${TOOL_CONFIGS[wpscan:${INTENSITY}]:-${TOOL_CONFIGS[wpscan:2]}}"
    local wpscan_cmd="wpscan --url http://${TARGET_IP}:${PORT} ${wpscan_intensity} --format cli-no-color"

    if run_command "${wpscan_cmd}" "WPScan analysis"; then
        cp "${TEMP_DIR}/WPScan_analysis.out" "${RESULTS_DIR}/wpscan_results.txt"
    fi
}

# Function: Vulnerability scanning
run_vulnerability_scan() {
    log "INFO" "VULN" "START" "Starting vulnerability scan"

    local nmap_vuln_cmd="nmap --script=vuln,http-vuln* -p${PORT} ${TARGET_IP}"

    if run_command "${nmap_vuln_cmd}" "Nmap vulnerability scan"; then
        cp "${TEMP_DIR}/Nmap_vulnerability_scan.out" "${RESULTS_DIR}/nmap_vuln_results.txt"
    fi
}

# Function: Directory fuzzing
run_directory_fuzzing() {
    log "INFO" "FUZZING" "DIR" "Starting directory fuzzing"

    local gobuster_intensity="${TOOL_CONFIGS[gobuster:${INTENSITY}]:-${TOOL_CONFIGS[gobuster:2]}}"
    local gobuster_cmd="gobuster dir -u http://${TARGET_IP}:${PORT} \
        -w ${DIRECTORY_WORDLIST} ${gobuster_intensity} \
        -o ${RESULTS_DIR}/gobuster_dirs.txt \
        -q"

    run_command "${gobuster_cmd}" "Gobuster directory scan"
}

# Function: File fuzzing
run_file_fuzzing() {
    log "INFO" "FUZZING" "FILE" "Starting file fuzzing"

    local gobuster_intensity="${TOOL_CONFIGS[gobuster:${INTENSITY}]:-${TOOL_CONFIGS[gobuster:2]}}"
    local gobuster_cmd="gobuster dir -u http://${TARGET_IP}:${PORT} \
        -w ${FILE_WORDLIST} ${gobuster_intensity} \
        -x ${CUSTOM_EXTENSIONS} \
        -o ${RESULTS_DIR}/gobuster_files.txt \
        -q"

    run_command "${gobuster_cmd}" "Gobuster file scan"
}

# Function: Virtual host fuzzing
run_vhost_fuzzing() {
    if [[ -z "${HOSTNAME:-}" ]]; then
        log "INFO" "FUZZING" "VHOST" "No hostname provided, skipping vhost fuzzing"
        return 0
    fi

    log "INFO" "FUZZING" "VHOST" "Starting virtual host fuzzing"

    local ffuf_intensity="${TOOL_CONFIGS[ffuf:${INTENSITY}]:-${TOOL_CONFIGS[ffuf:2]}}"
    local ffuf_cmd="ffuf ${ffuf_intensity} \
        -u http://${TARGET_IP}:${PORT} \
        -H 'Host: FUZZ.${HOSTNAME}' \
        -w ${VHOST_WORDLIST} \
        -mc ${HTTP_STATUS_CODES} \
        -o ${RESULTS_DIR}/ffuf_vhosts.txt"

    run_command "${ffuf_cmd}" "FFuf vhost scan"
}
