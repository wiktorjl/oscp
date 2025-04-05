#!/bin/bash

# Function: Display help message
show_help() {
    cat << EOF
Usage: $(basename "$0") -t TARGET_IP [OPTIONS]

Required:
    -t, --target        Target IP address

Options:
    -p, --port         Port number (default: 80)
    -h, --hostname     Hostname for vhost scanning
    -i, --intensity    Scan intensity (1=Low, 2=Normal, 3=High)
    -a, --interactive  Enable interactive mode (pause between steps)
    -d, --debug        Enable debug output
    --help            Show this help message

Advanced Options:
    --custom-wordlist  Specify custom wordlist for directory bruteforcing
    --timeout         Set global timeout for all operations (default: 30s)
    --max-rate        Set maximum rate limit for requests
    --proxy           Specify proxy server (e.g., http://127.0.0.1:8080)
    --user-agent      Specify custom User-Agent string
    --cookies         Specify cookies for authenticated scanning
    --headers         Specify additional HTTP headers

Output Options:
    --output-format   Specify output format (text,json,html)
    --no-color        Disable colored output
    --quiet           Minimize output, only show critical findings

Example:
    $(basename "$0") -t 192.168.1.100 -p 8080 -h example.com -i 2 -a
EOF
}

# Function: Enhanced logging
log() {
    local level=${1:-INFO}
    local category=${2:-GENERAL}
    local subcategory=${3:-}
    local message=${4:-No message provided}

    # Default values if array keys don't exist
    local icon=${ICONS[$level]:-"?"}
    local color=${COLORS[$level]:-${COLORS[NC]}}

    # Format timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Build log message
    local formatted_message="${timestamp} ${icon} [${level}] ${category}"
    [[ -n $subcategory ]] && formatted_message+=" (${subcategory})"
    formatted_message+=": ${message}"

    # Output to console with color if available
    echo -e "${color}${formatted_message}${COLORS[NC]:-}"

    # Output to log file without color if LOG_FILE is defined
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${formatted_message}" >> "${LOG_FILE}"
        sync
    fi

    # Additional debug information if enabled
    if [[ "${DEBUG:-false}" == true && "${level}" == "DEBUG" ]]; then
        echo -e "${COLORS[PURPLE]:-}[DEBUG] Call stack:${COLORS[NC]:-}"
        caller 0
    fi
}

# Function: Execute command with error handling
run_command() {
    local cmd="$1"
    local description="$2"
    local output_file="${TEMP_DIR}/$(echo "$description" | tr ' ' '_').out"
    local error_file="${TEMP_DIR}/$(echo "$description" | tr ' ' '_').err"

    log "INFO" "EXECUTION" "START" "Running: $description"

    if timeout "${COMMAND_TIMEOUT}" bash -c "$cmd" > "$output_file" 2> "$error_file"; then
        log "SUCCESS" "EXECUTION" "COMPLETE" "$description completed successfully"
        return 0
    else
        local exit_code=$?
        log "ERROR" "EXECUTION" "FAILED" "$description failed with exit code $exit_code"
        if [[ -s "$error_file" ]]; then
            log "ERROR" "EXECUTION" "ERROR_OUTPUT" "$(cat "$error_file")"
        fi
        return $exit_code
    fi
}

# Function: Parse command line parameters
parse_params() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)
                TARGET_IP="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -h|--hostname)
                HOSTNAME="$2"
                shift 2
                ;;
            -i|--intensity)
                INTENSITY="$2"
                shift 2
                ;;
            -a|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "PARAMS" "INVALID" "Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "${TARGET_IP:-}" ]]; then
        log "ERROR" "PARAMS" "MISSING" "Target IP is required"
        show_help
        exit 1
    fi
}

# Function: Validate environment
validate_environment() {
    local required_tools=(
        "nmap"
        "whatweb"
        "wpscan"
        "gobuster"
        "ffuf"
        "curl"
        "jq"
        "nc"
    )

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "ENVIRONMENT" "DEPENDENCY" "Required tool not found: $tool"
            exit 1
        fi
    done

    # Validate wordlist files
    local required_wordlists=(
        "$DIRECTORY_WORDLIST"
        "$FILE_WORDLIST"
        "$VHOST_WORDLIST"
    )

    for wordlist in "${required_wordlists[@]}"; do
        if [[ ! -f "$wordlist" ]]; then
            log "ERROR" "ENVIRONMENT" "WORDLIST" "Required wordlist not found: $wordlist"
            exit 1
        fi
    done
}

# Function: Validate target parameters
validate_target() {
    if [[ ! "$TARGET_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "VALIDATION" "IP" "Invalid IP address format: $TARGET_IP"
        exit 1
    fi

    if [[ -n "${PORT:-}" && (! "$PORT" =~ ^[0-9]+$ || "$PORT" -lt 1 || "$PORT" -gt 65535) ]]; then
        log "ERROR" "VALIDATION" "PORT" "Invalid port number: $PORT"
        exit 1
    fi

    if [[ -n "${INTENSITY:-}" && ! "${INTENSITY_LEVELS[$INTENSITY]:-}" ]]; then
        log "ERROR" "VALIDATION" "INTENSITY" "Invalid intensity level: $INTENSITY"
        exit 1
    fi
}

# Function: Prompt for user continuation
prompt_continue() {
    local message="$1"
    if [[ "${INTERACTIVE:-false}" == true ]]; then
        echo -en "${COLORS[YELLOW]}${message} (y/N) ${COLORS[NC]}"
        read -r response
        if [[ ! "${response}" =~ ^[Yy]$ ]]; then
            log "INFO" "PROMPT" "ABORT" "User chose to abort"
            cleanup
            exit 0
        fi
    fi
}

# Function: Cleanup resources
cleanup() {
    log "INFO" "CLEANUP" "START" "Performing cleanup"
    [[ -d "${TEMP_DIR:-}" ]] && rm -rf "${TEMP_DIR}"
    jobs -p | xargs -r kill -9 2>/dev/null || true
    log "INFO" "CLEANUP" "COMPLETE" "Cleanup finished"
}
