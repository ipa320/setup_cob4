#!/bin/bash

# get installed packages
packages=$(dpkg --get-selections | grep -v "deinstall" | awk '{print $1}')
echo $packages > /tmp/package_list

# get pcs in local network
IP=$(hostname -I | awk '{print $1}')
client_list=$(nmap --unprivileged $IP-50 --system-dns | grep report | awk '{print $5}')

declare -a commands=(
"sudo apt-get update > /dev/null"
"sudo apt-get install -y $packages"
"sudo apt-get upgrade -y"
"sudo apt-get autoremove -y"
)


for client in $client_list; do 
  echo "-------------------------------------------"
  echo "Installing packages on $client"
  echo "-------------------------------------------"
  echo ""
  for command in "${commands[@]}"; do
    echo "----> executing: $command"
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -t "$command return an error in $client (error code: $ret), aborting..."
      exit 1
    fi
  done
  echo ""
done

