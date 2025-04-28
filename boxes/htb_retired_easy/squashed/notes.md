
== PORT SCAN ==

nmap -v -sS -sC -sV -A -T5 -p 1-1000 -oN scan.txt squashed.htb
nmap -v -sS -sC -sV -A -T5 -p 1000-10000 -oN scan1.txt squashed.htb

PORT    STATE SERVICE VERSION                                                                                                  │
22/tcp  open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.5 (Ubuntu Linux; protocol 2.0)                                             │
| ssh-hostkey:                                                                                                                 │
|   3072 48:ad:d5:b8:3a:9f:bc:be:f7:e8:20:1e:f6:bf:de:ae (RSA)                                                                 │
|   256 b7:89:6c:0b:20:ed:49:b2:c1:86:7c:29:92:74:1c:1f (ECDSA)                                                                │
|_  256 18:cd:9d:08:a6:21:a8:b8:b6:f7:9f:8d:40:51:54:fb (ED25519)                                                              │
80/tcp  open  http    Apache httpd 2.4.41 ((Ubuntu))                                                                           │
|_http-server-header: Apache/2.4.41 (Ubuntu)                                                                                   │
| http-methods:                                                                                                                │
|_  Supported Methods: HEAD GET POST OPTIONS                                                                                   │
|_http-title: Built Better                                                                                                     │
111/tcp open  rpcbind 2-4 (RPC #100000)                                                                                        │
| rpcinfo:                                                                                                                     │
|   program version    port/proto  service                                                                                     │
|   100000  2,3,4        111/tcp   rpcbind                                                                                     │
|   100000  2,3,4        111/udp   rpcbind                                                                                     │
|   100000  3,4          111/tcp6  rpcbind                                                                                     │
|   100000  3,4          111/udp6  rpcbind                                                                                     │
|   100003  3           2049/udp   nfs                                                                                         │
|   100003  3           2049/udp6  nfs                                                                                         │
|   100003  3,4         2049/tcp   nfs                                                                                         │
|   100003  3,4         2049/tcp6  nfs                                                                                         │
|   100005  1,2,3      36139/udp6  mountd                                                                                      │
|   100005  1,2,3      36723/udp   mountd                                                                                      │
|   100005  1,2,3      51125/tcp   mountd                                                                                      │
|   100005  1,2,3      54081/tcp6  mountd                                                                                      │
|   100021  1,3,4      35599/udp6  nlockmgr                                                                                    │
|   100021  1,3,4      42571/tcp6  nlockmgr                                                                                    │
|   100021  1,3,4      46443/tcp   nlockmgr                                                                                    │
|   100021  1,3,4      58005/udp   nlockmgr                                                                                    │
|   100227  3           2049/tcp   nfs_acl                                                                                     │
|   100227  3           2049/tcp6  nfs_acl                                                                                     │
|   100227  3           2049/udp   nfs_acl                                                                                     │
|_  100227  3           2049/udp6  nfs_acl   
2049/tcp open  nfs     3-4 (RPC #100003) 


== NFS ==
