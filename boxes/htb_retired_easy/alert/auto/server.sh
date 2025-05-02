#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <port>"
    exit 1
fi

PORT=$1

echo "Listening on port $PORT..."

nc -l -p "$PORT" | while IFS= read -r line; do
    if [[ "$line" == "GET /?suction="* ]]; then
        # Extract the parameter directly
        suction_value="${line#GET /?suction=}"
        # Remove HTTP version and any other parameters
        suction_value="${suction_value%% *}"
        
        echo "Received base64: $suction_value"
        
        # URL decode - replace %XX with actual characters
        decoded_url=$(echo -n "$suction_value" | sed 's/%\([0-9A-F][0-9A-F]\)/\\x\1/g' | xargs -0 echo -e)
        
        # Base64 decode using echo -n to preserve all characters
        echo -n "$decoded_url" | base64 -d > /tmp/decoded.txt
        
        echo "Decoded result:"
        cat /tmp/decoded.txt
        rm /tmp/decoded.txt
        
        # Read remaining HTTP headers
        while read -r header_line && [ -n "$header_line" ]; do
            : # do nothing
        done
        
        # Send HTTP response
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nProcessed." | nc -l -p "$PORT" &
        
        break
    fi
done
