#!/bin/bash

# Web Application Security Scanner
# Version: 2.0
# Description: Automated web application security scanning script for red teaming

# Set bash options
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures

# Source all required modules
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source config first as it defines required variables
source "${SCRIPT_DIR}/lib/config.sh"

# Then source other modules
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/scanning.sh"
source "${SCRIPT_DIR}/lib/reporting.sh"

# Initialize global variables
init_globals() {
    LOG_FILE="${SCRIPT_DIR}/webscan.log"
    RESULTS_DIR="${SCRIPT_DIR}/results_$(date +%Y%m%d_%H%M%S)"
    TEMP_DIR="${RESULTS_DIR}/temp"
    DEBUG=${DEBUG:-false}
    INTERACTIVE=${INTERACTIVE:-false}
    PORT=${PORT:-80}
    INTENSITY=${INTENSITY:-2}
    TARGET_IP=${TARGET_IP:-""}
    HOSTNAME=${HOSTNAME:-""}
    WORDPRESS_DETECTED=${WORDPRESS_DETECTED:-false}
}

# Main execution flow
main() {
    init_globals
    parse_params "$@"
    validate_environment
    validate_target

    # Create necessary directories
    mkdir -p "${RESULTS_DIR}" "${TEMP_DIR}"

    # Initialize log file
    {
        echo "=== Web Application Security Scan ==="
        echo "Start Time: $(date)"
        echo "Target: ${TARGET_IP}:${PORT}"
        [[ -n "${HOSTNAME:-}" ]] && echo "Hostname: ${HOSTNAME}"
        echo "==============================="
    } > "${LOG_FILE}"

    # Set up signal handlers
    trap cleanup EXIT
    trap 'log "ERROR" "SIGNAL" "INTERRUPT" "Scan interrupted by user"; cleanup; exit 1' INT

    # Execute scanning steps
    run_initial_recon
    run_service_discovery
    run_web_fingerprinting
    run_wordpress_scan
    run_vulnerability_scan
    run_directory_fuzzing
    run_file_fuzzing
    run_vhost_fuzzing

    # Generate final report
    generate_report

    log "SUCCESS" "SCAN" "COMPLETE" "Web application security scan completed"
}

# Start script execution if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
