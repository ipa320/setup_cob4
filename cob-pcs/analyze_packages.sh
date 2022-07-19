#!/usr/bin/env bash
set -e

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

#### retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/../helper_client_list.sh
query_pc_list "$client_list_hostnames"
pc_list=$LIST
IFS=" " read -r -a array_hostnames <<< "$pc_list"  # helper to retrieve first element of list

# pip is not available for focal
if [ "$(lsb_release -sc)" == "xenial" ]; then
  PIP_CMD=pip
elif [ "$(lsb_release -sc)" == "focal" ]; then
  PIP_CMD=pip3
else
  echo -e "\n${red}FATAL: Script only supports kinetic and noetic"
  exit 1
fi

# gather apt and pip version info
for client in $pc_list; do
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Analyzing packages on $client${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a commands=(
    "dpkg -l | grep '^ii' | awk '{print \$2 \"\t\" \$3}' | tr \"\\t\" \"=\" > $HOME/.dpkg_installed_$ROS_DISTRO_$client.txt"
    "sudo -H $PIP_CMD freeze > $HOME/.pip_installed_$ROS_DISTRO_$client.txt"
  )
  for command in "${commands[@]}"; do
    echo "----> executing: $command"
    # shellcheck disable=SC2029 disable=SC2086
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
done

# show apt and pip diffs
for client in $pc_list; do
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Comparing packages on $client with ${array_hostnames[0]}${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a commands=(
    "diff --side-by-side --suppress-common-lines $HOME/.dpkg_installed_$ROS_DISTRO_${array_hostnames[0]}.txt $HOME/.dpkg_installed_$ROS_DISTRO_$client.txt; echo \$?;"
    "diff --side-by-side --suppress-common-lines $HOME/.pip_installed_$ROS_DISTRO_${array_hostnames[0]}.txt $HOME/.pip_installed_$ROS_DISTRO_$client.txt; echo \$?;"
  )
  for command in "${commands[@]}"; do
    echo "----> executing: $command"
    # shellcheck disable=SC2029 disable=SC2086
    result=$(ssh $client $command)
    ret=$(echo "$result" | tail -n1)
    if [ "$ret" != 0 ] ; then
      # shellcheck disable=SC2086
      FILE1=$(echo $command | cut -d' ' -f4)
      # shellcheck disable=SC2086
      FILE2=$(echo $command | cut -d' ' -f5)
      echo -e "${red}Found a difference between ${array_hostnames[0]} ($FILE1) and $client ($FILE2).${NC}"
      echo -e "${red}Please merge/sync/update the install files in '$SCRIPTPATH' and create a PR!${NC}"
      echo -e "\n${yellow}Do you want to see diff (y/n)?${NC}"
      read -r answer
      if echo "$answer" | grep -iq "^y" ;then
        echo -e "${blue} column left: $FILE1 - column right: $FILE2${NC}"
        echo "$result"
      fi
    fi
  done
  echo ""
done

# clean up
#rm $HOME/.dpkg_installed_$ROS_DISTRO*
#rm $HOME/.pip_installed_$ROS_DISTRO*

echo -e "${green}analyzing packages done.${NC}"
