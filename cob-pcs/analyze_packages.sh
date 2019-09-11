#!/bin/bash
set -e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

#### retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh
array_hostnames=( $client_list_hostnames )

# gather apt and pip version info
for client in $client_list_hostnames; do
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Analyzing packages on $client${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a commands=(
    "dpkg -l | grep '^ii' | awk '{print \$2 \"\t\" \$3}' | tr \"\\t\" \"=\" > ~/.dpkg_installed_$client.txt"
    "sudo -H pip freeze > ~/.pip_installed_$client.txt"
  )
  for command in "${commands[@]}"; do
    echo "----> executing: $command"
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
done

# show apt and pip diffs
for client in $client_list_hostnames; do
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Comparing packages on $client with ${array_hostnames[0]}${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a commands=(
    "diff ~/.dpkg_installed_${array_hostnames[0]}.txt ~/.dpkg_installed_$client.txt; echo \$?;"
    "diff ~/.pip_installed_${array_hostnames[0]}.txt ~/.pip_installed_$client.txt; echo \$?;"
  )
  for command in "${commands[@]}"; do
    echo "----> executing: $command"
    result=$(ssh $client $command)
    ret=$(echo "$result" | tail -n1)
    if [ $ret != 0 ] ; then
      echo -e "${yellow}Found a difference between ${array_hostnames[0]} and $client, please merge/sync/update the install files in '~/git/setup_cob4/cob-pcs' and create a PR${NC}"
      echo "$result"
    fi
  done
  echo ""
done

# clean up
#rm ~/.dpkg_installed*
#rm ~/.pip_installed*

echo -e "${green}analyzing packages done.${NC}"
