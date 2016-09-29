#!/usr/bin/env bash

# Script for installing apt packages on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 packages"
	exit 1
fi

robot_name="${HOSTNAME//-b1}"

echo $robot_name
client_list="
$robot_name-b1
$robot_name-t1
$robot_name-t2
$robot_name-t3
$robot_name-s1
$robot_name-h1"

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
