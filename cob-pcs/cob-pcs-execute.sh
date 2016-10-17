#!/usr/bin/env bash

# Script for executing commands on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 command"
	exit 1
fi

robot_name="${HOSTNAME//-b1}"

client_list="
$robot_name-b1
$robot_name-t1
$robot_name-t2
$robot_name-t3
$robot_name-s1
$robot_name-h1"

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
