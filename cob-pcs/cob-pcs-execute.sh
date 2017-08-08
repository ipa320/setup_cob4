#!/usr/bin/env bash

# Script for executing commands on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 command"
	exit 1
fi

# get pcs in local network
IP=$(hostname -I | awk '{print $1}')
client_list=$(nmap --unprivileged $IP-98 --system-dns | grep report | awk '{print $6}' | sed 's/(//g;s/)//g' | tr '\n' ' ')

for client in $client_list; do
	echo "-------------------------------------------"
	echo "Executing <<"$*">> on $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "$*"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "command return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
done
