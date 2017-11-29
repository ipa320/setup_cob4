#!/bin/bash

#outsources retrieval client_list variables
IP=$(hostname -I | awk '{print $1}')
client_list_ip=$(nmap --unprivileged $IP-50 --system-dns | grep report | awk '{print $6}' | sed 's/(//g;s/)//g' | tr '\n' ' ')
client_list_hostnames=$(nmap --unprivileged $IP-50 --system-dns | grep report | awk '{print $5}' | sed 's/(//g;s/)//g' | tr '\n' ' ')

#echo client_list_ip
#echo $client_list_ip
#echo client_list_hostnames
#echo $client_list_hostnames
