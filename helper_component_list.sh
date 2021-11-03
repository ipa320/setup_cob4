#!/bin/bash

#outsources retrieval component_list variables
if [ -z "$component_list_ip" ] || [ -z "$component_list_hostnames" ]; then
  echo "gathering component list..."
  IP=$(hostname -I | awk '{print $1}')
  IP_RANGE=${IP:0:-3}
  nmap_report=$(nmap "$IP_RANGE".50-99 --system-dns | grep report) || echo "No components found"
  component_list_ip=$(echo "$nmap_report" | awk '{print $6}' | sed 's/(//g;s/)//g' | tr '\n' ' ')
  component_list_hostnames=$(echo "$nmap_report" | awk '{print $5}' | sed 's/(//g;s/)//g' | sed 's/\..*$//g' | tr '\n' ' ')
fi

if [ -n "$component_list_ip" ] && [ -n "$component_list_hostnames" ]; then
  echo component_list_ip
  echo "$component_list_ip"
  echo component_list_hostnames
  echo "$component_list_hostnames"
fi
