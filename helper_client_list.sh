#!/usr/bin/env bash

#outsources retrieval client_list variables
if [ -z "$client_list_ip" ] || [ -z "$client_list_ip" ]; then
  echo "gathering client list..."
  IP=$(hostname -I | awk '{print $1}')
  nmap_report=$(nmap "$IP"-50 --system-dns | grep report) || echo "No clients found"
  client_list_ip=$(echo "$nmap_report" | awk '{print $6}' | sed 's/(//g;s/)//g' | tr '\n' ' ')
  client_list_hostnames=$(echo "$nmap_report" | awk '{print $5}' | sed 's/(//g;s/)//g' | sed 's/\..*$//g' | tr '\n' ' ')
fi

if [ -n "$client_list_ip" ] && [ -n "$client_list_hostnames" ]; then
  echo client_list_ip
  echo "$client_list_ip"
  echo client_list_hostnames
  echo "$client_list_hostnames"
fi
