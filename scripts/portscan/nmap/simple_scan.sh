#!/bin/sh

target_host=$1
echo "Using target: $1"
echo "Finding open ports..."
ports=$(nmap -p- -T5 $target_host | grep ^[0-9] | tr '/' ' ' | awk '{ print $1 }' | tr '\n' ',' | sed s/,$//)

echo "Open ports discovered on $1: $ports"
echo "Analysing open ports..."
nmap -p$ports -sC -sV -Pn $target_host > scan.txt 2> scan_errors.txt
