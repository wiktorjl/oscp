WIP

sudo nmap -v -sS -sC -sV -A -T5 -p 1-65535 -oN scan.txt

ffuf -o vhosts.json -u http://alert.htb -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -H "Host: FUZZ.alert.htb" -fc 301,302

NMAP http option TRACE
nc paper.htb 80 / TRACE
office.paper 

wpscan:
wp 5.2.3
apache 2.4.37
php 7.2.24

wp 5.2.3 has unauthenticated bug
https://github.com/Mad-robot/wordpress-exploits/blob/master/Wordpress%20%3C%3D5.2.3:%20viewing%20unauthenticated%20posts.md

this reveals:
http://chat.office.paper/register/8qozr226AhkCHZdyY
Password: Queenofblad3s!23

exploit path traversal in chat
../../../../../etc/passwd
user: dwight

download latest linpeas
find and run exploit for CVE-2021-3560

root

