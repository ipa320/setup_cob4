#!/usr/bin/env bash

# Script for installing apt packages on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 packages"
	exit 1
fi

#### retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh

for client in $client_list_hostnames; do
	echo "-------------------------------------------"
	echo "Updating $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "sudo apt-get update"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "apt-get return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
	echo "-------------------------------------------"
	echo "Installing <<"$*">> on $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "sudo apt-get install $* -y --allow-downgrades --allow-unauthenticated"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "apt-get return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
done
