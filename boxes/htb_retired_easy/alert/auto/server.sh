#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: $0 <port>"
    exit 1
fi
PORT=$1
echo "Listening on port $PORT..."

# Use a loop to handle multiple connections
while true; do
    echo "Waiting for connection..."
    # Use a temporary file for the response
    TMPFILE=$(mktemp)
    
    nc -l -p "$PORT" > "$TMPFILE" &
    NC_PID=$!
    
    # Wait for nc to start and listen
    sleep 1
    
    # Wait for the nc process to finish (connection received)
    wait $NC_PID
    
    # Process the received data
    while IFS= read -r line; do
        if [[ "$line" == "GET /?suction="* ]]; then
            # Extract the parameter directly
            suction_value="${line#GET /?suction=}"
            # Remove HTTP version and any other parameters
            suction_value="${suction_value%% *}"
            echo "Received base64: $suction_value"
            
            # URL decode with more robust handling
            decoded_url=$(printf '%b' "${suction_value//%/\\x}")
            
            # Safely decode base64 to handle special characters
            echo "Decoding base64 content..."
            DECODED_FILE=$(mktemp)
            echo -n "$decoded_url" | base64 -d > "$DECODED_FILE" 2>/dev/null
            
            # Check if base64 decoding succeeded
            if [ $? -eq 0 ]; then
                echo "Decoded result:"
                cat "$DECODED_FILE"
            else
                echo "Error: Failed to decode base64 content"
            fi
            
            rm -f "$DECODED_FILE"
            
            # Send HTTP response
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nProcessed." | nc -l -p "$PORT" &
            RESP_PID=$!
            sleep 1
            kill $RESP_PID 2>/dev/null
            break
        fi
    done < "$TMPFILE"
    
    # Clean up temp file
    rm -f "$TMPFILE"
done