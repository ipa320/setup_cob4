#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTNAME=$(basename "$0")

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

function query_pc_list {
  echo -e "${blue}PC_LIST:${NC} $1"
  echo -e "\n${yellow}Do you want to use the suggested pc list (y/N)?${NC}"
  read -r answer

  if echo "$answer" | grep -iq "^y" ;then
    LIST=$1
  else
    echo -e "\n${yellow}Enter list of pcs to be used for ${SCRIPTNAME}:${NC}"
    read -r LIST
  fi
}

# Script for executing commands on all client_pcs.

# checking input parameters
if [ "$#" -lt 1 ]; then
	echo -e "${red}ERROR: Wrong number of parameters${NC}"
	echo -e "${red}Usage: $SCRIPT command${NC}"
	exit 1
fi

#### retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/../helper_client_list.sh
query_pc_list "$client_list_hostnames"
pc_list=$LIST

# shellcheck disable=SC2154
for client in $pc_list; do
	echo -e "${green}-------------------------------------------${NC}"
	echo -e "${green}Executing <<""$*"">> on $client ${NC}"
	echo -e "${green}-------------------------------------------${NC}"
	echo ""
	# shellcheck disable=SC2029
	ssh "$client" "$*"
	ret=${PIPESTATUS[0]}
	if [ "$ret" != 0 ] ; then
		echo -e "${red}command return an error (error code: $ret), aborting...${NC}"
		exit 1
	fi
	echo ""
done
