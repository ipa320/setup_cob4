#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# Script for installing apt packages on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 packages"
	exit 1
fi

#### retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/../helper_client_list.sh

# shellcheck disable=SC2154
for client in $client_list_hostnames; do
	echo "-------------------------------------------"
	echo "Updating $client"
	echo "-------------------------------------------"
	echo ""
	# shellcheck disable=SC2029
	ssh "$client" "sudo apt-get update"
	ret=${PIPESTATUS[0]}
	if [ "$ret" != 0 ] ; then
		echo "apt-get return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
	echo "-------------------------------------------"
	echo "Installing <<""$*"">> on $client"
	echo "-------------------------------------------"
	echo ""
	# shellcheck disable=SC2029
	ssh "$client" "sudo apt-get install $* -y --allow-downgrades --allow-unauthenticated"
	ret=${PIPESTATUS[0]}
	if [ "$ret" != 0 ] ; then
		echo "apt-get return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
done
