#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# Script for executing commands on all cob-stud-pc's.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo "ERROR: Wrong number of parameters"
	echo "Usage: $0 command"
	exit 1
fi

#### retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/../helper_client_list.sh

# shellcheck disable=SC2154
for client in $client_list_hostnames; do
	echo "-------------------------------------------"
	echo "Executing <<""$*"">> on $client"
	echo "-------------------------------------------"
	echo ""
	# shellcheck disable=SC2029
	ssh "$client" "$*"
	ret=${PIPESTATUS[0]}
	if [ "$ret" != 0 ] ; then
		echo "command return an error (error code: $ret), aborting..."
		exit 1
	fi
	echo ""
done
