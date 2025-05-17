#!/bin/bash
# Global variables for background processes and log file
server_pid=""
server_log=""
tail_pid=""
server_port=""
server_log_fd=""

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
    
    # Also find and kill any orphaned nc processes (in case kill didn't catch all)
    if [[ -n "$server_port" ]]; then
        for pid in $(pgrep -f "nc -l -p $server_port"); do
            log_message "Killing orphaned nc process (PID: $pid)..."
            kill -9 $pid 2>/dev/null
        done
    fi
    
    # Remove the server log file if it exists
    if [[ -n "$server_log" ]] && [[ -f "$server_log" ]]; then
        log_message "Removing log file: $server_log"
        rm -f "$server_log" 2>/dev/null
    fi
    
    # Close the server log file descriptor if it's open
    if [[ -n "$server_log_fd" ]]; then
        eval "exec $server_log_fd>&-"
    fi
    
    log_message "Cleanup complete."
}

# Function to handle termination signals (Ctrl+C, etc.)
force_exit() {
    log_message "\nReceived termination signal. Exiting..."
    cleanup
    exit 1
}

# Function to get user input with a prompt that persists even with server logs
read_with_prompt() {
    local prompt="$1"
    local input_var="$2"
    local input=""
    
    # Print the prompt
    echo -ne "$prompt"
    
    # Read the input
    read -r input
    
    # Set the output variable
    eval "$input_var=\"$input\""
}

# --- Main Script ---
trap cleanup EXIT
trap force_exit SIGINT SIGTERM

# --- Argument Parsing ---
run_server=false
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
    
    # Check if port is already in use
    if nc -z localhost "$server_port" 2>/dev/null; then
        log_message "Error: Port $server_port is already in use." >&2
        exit 1
    fi
    
    # Check if stdbuf command exists
    if ! command -v stdbuf &> /dev/null; then
        log_message "Warning: 'stdbuf' command not found. Server output might be buffered." >&2
        # Define run_cmd without stdbuf as a fallback
        run_cmd=(./server.sh "$server_port")
    else
        # Use stdbuf to force line buffering on server's stdout
        # This makes logs appear in tail -f more immediately.
        run_cmd=(stdbuf -o L ./server.sh "$server_port")
    fi
    
    server_log=$(mktemp "/tmp/server_log_XXXXXXXXXX") || { log_message "Error: Failed to create temp log file." >&2; exit 1; }
    log_message "Starting server (${run_cmd[*]}) on port $server_port in background..."
    log_message "Server log: $server_log"
    
    # Start server.sh using the run_cmd array, redirecting stdout/stderr
    "${run_cmd[@]}" > "$server_log" 2>&1 &
    server_pid=$!
    sleep 0.2
    
    if ! ps -p "$server_pid" > /dev/null 2>&1; then
         log_message "Error: server.sh failed to start. Check log: $server_log" >&2
         # No need to explicitly call cleanup, EXIT trap handles it
         exit 1
    fi
    
    log_message "Server started with PID: $server_pid"
    
    # Find an available file descriptor for server logs (typically 3)
    for fd in {3..9}; do
        if ! eval "exec $fd>&-" 2>/dev/null; then
            server_log_fd=$fd
            eval "exec $fd> >(while IFS= read -r line; do echo \"[SERVER] \$line\"; done)"
            break
        fi
    done
    
    if [[ -z "$server_log_fd" ]]; then
        log_message "Warning: Could not allocate a file descriptor for server logs."
        # Fall back to standard tail
        tail -f "$server_log" | sed 's/^/[SERVER] /' &
    else
        # Use the allocated file descriptor
        tail -f "$server_log" >&$server_log_fd &
    fi
    
    tail_pid=$!
    
    # Check if tail started okay
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
    # Use a simple prompt and standard read
    printf "\nEnter a filename (or 'exit' to quit): "
    read -r filename
    
    # Handle EOF (Ctrl+D)
    if [[ $? -ne 0 ]]; then
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
    
    log_message "Processing file: $filename"
    
    temp_output_3sh=$(mktemp) || { log_message "Error: Failed to create temp file for gen_link.sh output." >&2; continue; }
    
    # Execute gen_link.sh, redirect stdout & stderr to temp file
    if ! ./gen_link.sh "$filename" > "$temp_output_3sh" 2>&1; then
        exec_status=$?
        log_message "Error: gen_link.sh execution failed (status $exec_status). Output:" >&2
        cat "$temp_output_3sh" >&2
        rm -f "$temp_output_3sh"
        continue
    fi
    
    url=$(<"$temp_output_3sh")
    rm -f "$temp_output_3sh"
    
    if [[ -z "$url" ]]; then
        log_message "Error: gen_link.sh did not return a value (URL)." >&2
        continue
    fi
    
    log_message "Generated URL: $url"
    log_message "Sending URL via mail..."
    
    if ! ./send_mail.sh "$url"; then
         log_message "Warning: send_mail.sh exited with non-zero status ($?)." >&2
    else
         log_message "URL sent successfully!"
    fi
    
    log_message "Command sequence completed."
done

log_message "Exiting normally."
# EXIT trap ensures cleanup runs