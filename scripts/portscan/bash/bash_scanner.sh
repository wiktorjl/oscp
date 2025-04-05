#!/bin/bash

# Default values
start_port=1
end_port=65535
host="localhost"
timeout=1

# Help message
usage() {
    echo "Usage: $0 [-h host] [-s start_port] [-e end_port]"
    echo "Default: localhost ports 1-1000"
    exit 1
}

# Parse command line arguments
while getopts "h:s:e:" opt; do
    case $opt in
        h) host="$OPTARG" ;;
        s) start_port="$OPTARG" ;;
        e) end_port="$OPTARG" ;;
        *) usage ;;
    esac
done

echo "Scanning $host for open ports..."

check_port() {
    local port=$1
    # Use timeout command as additional safety
    # Different approach for FTP ports
    if [ $port -eq 21 ]; then
        # For FTP, just try to establish connection without protocol
        if timeout $timeout bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            echo "Port $port is open (FTP)"
        fi
    else
        # For other ports, use curl with very short timeout
        if timeout $timeout curl --connect-timeout 0.5 -s telnet://$host:$port >/dev/null 2>&1; then
            echo "Port $port is open"
        fi
    fi
}

for port in $(seq $start_port $end_port); do
    check_port $port
done
