#!/usr/bin/env bash

# Script for installing apt packages on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 packages"
	exit 1
fi

# get pcs in local network
IP=$(`hostname -I | awk '{print $1}'`)
client_list=$(nmap --unprivileged $IP-98 --system-dns | grep report | awk '{print $6}' | sed 's/(//g;s/)//g')

for client in $client_list; do
	echo "-------------------------------------------"
	echo "Installing <<"$*">> on $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "sudo apt-get install $* -y --force-yes"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "apt-get return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
done
