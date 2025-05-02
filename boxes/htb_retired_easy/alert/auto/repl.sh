#!/bin/bash

# Global variables for background processes and log file
server_pid=""
server_log=""
tail_pid=""

# Function to print messages consistently
log_message() {
    printf "%s\n" "$@"
}

# Function to clean up background processes and log file on exit
cleanup() {
    log_message "\nCleaning up..."

    # Stop the tail process if it's running
    if [[ -n "$tail_pid" ]] && ps -p "$tail_pid" > /dev/null 2>&1; then
        log_message "Stopping tail process (PID: $tail_pid)..."
        kill -9 "$tail_pid" 2>/dev/null
    fi

    # Stop the server process if it's running
    if [[ -n "$server_pid" ]] && ps -p "$server_pid" > /dev/null 2>&1; then
        log_message "Stopping server process (PID: $server_pid)..."
        kill -15 "$server_pid" 2>/dev/null
        sleep 0.5
        if ps -p "$server_pid" > /dev/null 2>&1; then
            log_message "Force killing server process (PID: $server_pid)..."
            kill -9 "$server_pid" 2>/dev/null
        fi
    fi

    # Remove the server log file if it exists
    if [[ -n "$server_log" ]] && [[ -f "$server_log" ]]; then
        log_message "Removing log file: $server_log"
        rm -f "$server_log" 2>/dev/null
    fi

    log_message "Cleanup complete."
}

# Function to handle termination signals (Ctrl+C, etc.)
force_exit() {
    log_message "\nReceived termination signal. Exiting..."
    exit 1
}

# --- Main Script ---

trap cleanup EXIT
trap force_exit SIGINT SIGTERM

# --- Argument Parsing ---
run_server=false
server_port=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --server)
            run_server=true
            shift
            ;;
        --port)
            if [[ -n "$2" ]]; then
                server_port="$2"
                shift 2
            else
                log_message "Error: --port requires a value." >&2
                log_message "Usage: $0 [--server] [--port PORT_NUMBER]" >&2
                exit 1
            fi
            ;;
        *)
            log_message "Error: Unknown option: $1" >&2
            log_message "Usage: $0 [--server] [--port PORT_NUMBER]" >&2
            exit 1
            ;;
    esac
done

# --- Server Startup (Optional) ---
if $run_server; then
    if [[ -z "$server_port" ]]; then
        log_message "Error: --port argument is required when using --server" >&2
        log_message "Usage: $0 [--server] [--port PORT_NUMBER]" >&2
        exit 1
    fi

    # Check if stdbuf command exists
    if ! command -v stdbuf &> /dev/null; then
        log_message "Warning: 'stdbuf' command not found. Server output might be buffered." >&2
        # Define run_cmd without stdbuf as a fallback
        run_cmd=(./server2.sh "$server_port")
    else
        # Use stdbuf to force line buffering on server's stdout
        # This makes logs appear in tail -f more immediately.
        run_cmd=(stdbuf -o L ./server2.sh "$server_port")
    fi

    server_log=$(mktemp "/tmp/server_log_XXXXXXXXXX") || { log_message "Error: Failed to create temp log file." >&2; exit 1; }
    log_message "Starting server (${run_cmd[*]}) on port $server_port in background..."
    log_message "Server log: $server_log"

    # Start server2.sh using the run_cmd array, redirecting stdout/stderr
    "${run_cmd[@]}" > "$server_log" 2>&1 &
    server_pid=$!

    sleep 0.2
    if ! ps -p "$server_pid" > /dev/null 2>&1; then
         log_message "Error: server2.sh failed to start. Check log: $server_log" >&2
         # No need to explicitly call cleanup, EXIT trap handles it
         exit 1
    fi
    log_message "Server started with PID: $server_pid"

    # Tail the log file
    tail -f "$server_log" | sed 's/^/[SERVER] /' &
    tail_pid=$!
    # Check if tail started okay (optional, but good practice)
    if ! ps -p "$tail_pid" > /dev/null 2>&1; then
        log_message "Error: Failed to start log tailing process." >&2
        # Kill the server we just started
        kill -9 "$server_pid" 2>/dev/null
        exit 1
    fi
    log_message "Log tail process started with PID: $tail_pid"

    sleep 1 # Give server/tail time to settle
    log_message "Server startup sequence initiated."

else
    log_message "Running without server (use --server --port PORT to start one)"
fi

# --- Main REPL Loop ---
while true; do
    printf "\nEnter a filename (or 'exit' to quit): "
    if ! read -r filename; then
        log_message "\nEOF detected. Exiting..."
        break
    fi

    if [[ "$filename" == "exit" ]]; then
        log_message "Exiting..."
        break
    fi

    if [[ -z "$filename" ]]; then
        continue
    fi

    #log_message "Executing 3.sh with filename: $filename"
    temp_output_3sh=$(mktemp) || { log_message "Error: Failed to create temp file for 3.sh output." >&2; continue; }

    # Execute 3.sh, redirect stdout & stderr to temp file
    if ! ./3.sh "$filename" > "$temp_output_3sh" 2>&1; then
        exec_status=$?
        log_message "Error: 3.sh execution failed (status $exec_status). Output:" >&2
        cat "$temp_output_3sh" >&2
        rm -f "$temp_output_3sh"
        continue
    fi

    url=$(<"$temp_output_3sh")
    rm -f "$temp_output_3sh"

    if [[ -z "$url" ]]; then
        log_message "Error: 3.sh did not return a value (URL)." >&2
        continue
    fi
    #log_message "Received URL: $url"

    #log_message "Executing 5.sh with URL: $url"
    if ! ./5.sh "$url"; then
         log_message "Warning: 5.sh exited with non-zero status ($?)." >&2
    fi

    log_message "Command sequence completed."
done

log_message "Exiting normally."
# EXIT trap ensures cleanup runs