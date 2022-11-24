#!/usr/bin/env bash
set -e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTNAME=$(basename "$0")

function check_hostname () {
  if [[ ${HOSTNAME} != *"$1"* ]];then
    echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED ON PC $1${NC}"
    exit 1
  fi
}

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

usage=$(cat <<"EOF"
Available options:
1. Upgrade Master + Sync
2. Specify InstallFiles (debian and pip) + Sync
EOF
)

# get correct pip command (pip is not available for focal)
if [ "$(lsb_release -sc)" == "xenial" ]; then
  PIP_CMD=pip
elif [ "$(lsb_release -sc)" == "focal" ]; then
  PIP_CMD=pip3
else
  echo -e "\n${red}FATAL: Script only supports kinetic and noetic"
  exit 1
fi

## parse arguments
VERBOSE_OPTIONS="> /dev/null"
PARALLEL=false
if [[ $# -gt 0 ]]; then
  while [[ $# -gt 0 ]]; do
    option=$1
    case $option in
      "-v" | "--verbose")
        shift
        VERBOSE_OPTIONS=""
        ;;
      "-p" | "--parallel")
        shift
        PARALLEL=true
        ;;
      *)
        break
        ;;
    esac
  done
fi

## retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/../helper_client_list.sh
query_pc_list "$client_list_hostnames"
pc_list=$LIST

check_hostname "b1"
echo -e "$usage"
echo -e "${yellow}Please select a sync option: ${NC}"
read -r choice

## upgrade master and generate DPKG_/PIP_FILE
if [[ "$choice" == 1 ]]; then
  ## upgrade local pc
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Upgrading packages on ${HOSTNAME}${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a upgradecommands=(
    "sudo apt-get update $VERBOSE_OPTIONS"
    "sudo apt-get upgrade -y $VERBOSE_OPTIONS"
    "sudo apt-get dist-upgrade -y $VERBOSE_OPTIONS"
    "sudo apt-get autoremove -y $VERBOSE_OPTIONS"
  )
  for command in "${upgradecommands[@]}"; do
    command_head=$(echo "$command" | head -1)
    echo "----> executing: $command_head"
    # shellcheck disable=SC2029
    ssh "${HOSTNAME}" "$command"
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      echo -e "${red}$command return an error in ${HOSTNAME} (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""

  ## allow pip upgrade
  PIP_OPTIONS="--upgrade"

  # get installed packages
  DPKG_FILE="${HOME}/.dpkg_installed_${ROS_DISTRO}_updated.txt"
  PIP_FILE="${HOME}/.pip_installed_${ROS_DISTRO}_updated.txt"
  dpkg -l | grep '^ii' | awk '{print $2 "\t" $3}' | tr "\t" "=" > "$DPKG_FILE"
  sudo -H $PIP_CMD freeze | tee "$PIP_FILE"

## use DPKG_/PIP_FILE from setup_cob4
elif [[ "$choice" == 2 ]]; then
  ## allow pip to downgrade - if needed
  PIP_OPTIONS="--force-reinstall"

  DPKG_FILE="${SCRIPTPATH}/dpkg_installed_${ROS_DISTRO}.txt"
  PIP_FILE="${SCRIPTPATH}/pip_installed_${ROS_DISTRO}.txt"
  echo -e "${blue}DPKG_FILE:${NC} $DPKG_FILE"
  echo -e "${blue}PIP_FILE:${NC} $PIP_FILE"
  echo -e "\n${yellow}Do you want to use the install files (y/n)?${NC}"
  read -r answer

  if echo "$answer" | grep -iq "^n" ;then
    echo -e "${yellow}Please provide install file for ${red}DPKG_PACKAGES${yellow} (absolute path):${NC}"
    read -r DPKG_FILE
    echo -e "${yellow}Please provide install file for ${red}PIP_PACKAGES${yellow} (absolute path):${NC}"
    read -r PIP_FILE
  fi

## invalid option
else
  echo -e "\n${red}INFO: Invalid option. Exiting. ${NC}\n"
  exit 1
fi


## check file existence
if [ ! -f "$DPKG_FILE" ]; then
  echo -e "\n${red}File not found: $DPKG_FILE${NC}"
  exit 1
fi
if [ ! -f "$PIP_FILE" ]; then
  echo -e "\n${red}File not found: $PIP_FILE${NC}"
  exit 1
fi



### check whether version can be installed
declare -a testdpkg=(
"sudo apt-get update $VERBOSE_OPTIONS"
"sudo apt-get -qq install -y --allow-downgrades --allow-unauthenticated --simulate DPKG_PKG 2>&1"
"sudo apt-get autoremove -y $VERBOSE_OPTIONS"
)

declare -a testpip=(
"sudo -H $PIP_CMD install $PIP_OPTIONS -r $PIP_FILE 2>&1 $VERBOSE_OPTIONS"
)

set +e
echo -e "${green}-------------------------------------------${NC}"
echo -e "${green}Verifying install file${NC}"
echo -e "${green}-------------------------------------------${NC}"
echo ""
# shellcheck disable=SC2154
for client in $pc_list; do
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Verifying dpkg packages on $client${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  for command in "${testdpkg[@]}"; do
    # shellcheck disable=SC2086
    command=${command/DPKG_PKG/$(<$DPKG_FILE)}
    # shellcheck disable=SC2086
    command_head=$(echo $command | head -1 | cut -c -"$(tput cols)")
    echo "----> executing on $client: $command_head" "$VERBOSE_OPTIONS"
    # shellcheck disable=SC2029 disable=SC2086
    RESULT=$(ssh "$client" $command)
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      while IFS= read -r line; do
        #E: Version 'VVV' for 'XXX' was not found
        if [[ "$line" =~ ^E:\ Version.*  ]]; then
          version=$(echo "$line" | cut -d"'" -f2)
          package=$(echo "$line" | cut -d"'" -f4)
          sed -i "s/$package\(\:amd64\)\?\=$version/$package/g" "$DPKG_FILE"
          echo -e "${red} $line ${NC}"
          echo -e "${red} -> $package will be installed with the latest version instead ${NC}"
        fi
      done <<< "$RESULT"
    fi
  done
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Verifying pip packages on $client${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  for command in "${testpip[@]}"; do
    # shellcheck disable=SC2029 disable=SC2086
    command_head=$(echo $command | head -1)
    echo "----> executing on $client: $command_head" "$VERBOSE_OPTIONS"
    # shellcheck disable=SC2029 disable=SC2086
    RESULT=$(ssh -n "$client" $command) # -n is for preventing ssh to read from standard input thus eating all remaining lines
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      while IFS= read -r line; do
        #AssertionError: XXX==VVV .dist-info directory not found
        if [[ "$line" =~ ^AssertionError:.*  ]]; then
          if [[ "$line" =~ .*not\ found$ ]]; then
            tmp=$(echo "$line" | cut -d" " -f2)
            package=$(echo "$tmp" | cut -d"=" -f1)
            version=$(echo "$tmp" | cut -d"=" -f3)
            sed -i "s/$package\=\=$version/$package/g" "$PIP_FILE"
            echo -e "${red} $line ${NC}"
            echo -e "${red} -> $package will be installed with the latest version instead ${NC}"
          fi
        fi
        #No matching distribution found for XXX==VVV
        if [[ "$line" =~ ^'No matching distribution found for'.*  ]]; then
          tmp=$(echo "$line" | awk -F' ' '{print $NF}')
          package=$(echo "$tmp" | cut -d"=" -f1)
          version=$(echo "$tmp" | cut -d"=" -f3)
          sed -i "s/$package\=\=$version/$package/g" "$PIP_FILE"
          echo -e "${red} $line ${NC}"
          echo -e "${red} -> $package will be installed with the latest version instead ${NC}"
        fi
      done <<< "$RESULT"
    fi
  done
done
set -e


### sync/install packages
declare -a aptcommands=(
"sudo apt-get update $VERBOSE_OPTIONS"
"sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --allow-downgrades --allow-unauthenticated $(<"$DPKG_FILE") $VERBOSE_OPTIONS"
"sudo apt-get autoremove -y $VERBOSE_OPTIONS"
)

declare -a pipcommands=(
"sudo -H $PIP_CMD install $PIP_OPTIONS -r $PIP_FILE $VERBOSE_OPTIONS"
)

function sync_client () {
  client=$1
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Installing packages on $client${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  for command in "${aptcommands[@]}"; do
    command_head=$(echo "$command" | head -1)
    echo "----> executing: $command_head"
    # shellcheck disable=SC2029 disable=SC2086
    ssh "$client" $command
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
  for command in "${pipcommands[@]}"; do
    command_head=$(echo "$command" | head -1)
    echo "----> executing: $command_head"
    # shellcheck disable=SC2029 disable=SC2086
    ssh "$client" $command
    ret=${PIPESTATUS[0]}
    if [ "$ret" != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
}

if "$PARALLEL"; then
  pids=""
  for client in $pc_list; do
    ( sync_client "$client" &> /tmp/sync_"$client" ) & #run process in background
    pids+=" $!" # store PID of process
    echo -e "${green}PID for sync_client $client is $!${NC}"
  done

  # wait for all processes to finnish
  sync_failure=false
  for p in $pids; do
    if wait "$p"; then
      echo -e "${green}Process $p success${NC}"
    else
      echo -e "${red}Process $p fail${NC}"
      sync_failure=true
    fi
  done

  # print output of sync process for each client
  for client in $pc_list; do
    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Result for $client${NC}"
    echo -e "${green}-------------------------------------------${NC}"
    echo ""
    cat /tmp/sync_"$client"
  done

  # exit in case of failure
  if "$sync_failure"; then
    echo -e "${red}Failed to sync a client, aborting...${NC}"
    exit 1
  fi
else
  for client in $pc_list; do
    sync_client "$client"
  done
fi

## clean up
if [ -f "${HOME}"/.dpkg_installed_"${ROS_DISTRO}"_updated.txt ]; then
  rm "${HOME}"/.dpkg_installed_"${ROS_DISTRO}"_updated.txt
fi
if [ -f "${HOME}"/.pip_installed_"${ROS_DISTRO}"_updated.txt ]; then
  rm "${HOME}"/.pip_installed_"${ROS_DISTRO}"_updated.txt
fi


echo -e "${green}-------------------------------------------${NC}"
echo -e "${green}Comparing Sync Result${NC}"
echo -e "${green}-------------------------------------------${NC}"

## compare "internal" sync - call analyze_packages
"$SCRIPTPATH"/analyze_packages.sh

## compare "external" sync - compare installed_${ROS_DISTRO}_b1 vs. installed_${ROS_DISTRO}_setup_cob4
## updating the package files - based on what is installed on b1 pc
DPKG_LATEST="${HOME}/dpkg_installed_${ROS_DISTRO}_sync_$(date '+%Y%m%d_%H%M%S').txt"
DPKG_SETUPCOB4="${SCRIPTPATH}/dpkg_installed_${ROS_DISTRO}.txt"
PIP_LATEST="${HOME}/pip_installed_${ROS_DISTRO}_sync_$(date '+%Y%m%d_%H%M%S').txt"
PIP_SETUPCOB4="${SCRIPTPATH}/pip_installed_${ROS_DISTRO}.txt"
dpkg -l | grep '^ii' | awk '{print $2 "\t" $3}' | tr "\t" "=" > "$DPKG_LATEST"
sudo -H $PIP_CMD freeze | tee "$PIP_LATEST"

declare -a commands=(
  "diff --side-by-side --suppress-common-lines $DPKG_LATEST $DPKG_SETUPCOB4; echo \$?;"
  "diff --side-by-side --suppress-common-lines $PIP_LATEST $PIP_SETUPCOB4; echo \$?;"
)
for command in "${commands[@]}"; do
  echo "----> executing: $command"
  # shellcheck disable=SC2029
  result=$(ssh "$client" "$command")
  ret=$(echo "$result" | tail -n1)
  if [ "$ret" != 0 ] ; then
    FILE1=$(echo "$command" | cut -d' ' -f4)
    FILE2=$(echo "$command" | cut -d' ' -f5)
    echo -e "${red}Found a difference between $FILE1 and $FILE2.${NC}"
    echo -e "${red}Please merge/sync/update the install files in '$SCRIPTPATH' and create a PR!${NC}"
    echo -e "\n${yellow}Do you want to see diff (y/n)?${NC}"
    read -r answer
    if echo "$answer" | grep -iq "^y" ;then
      echo -e "${blue} column left: $FILE1 - column right: $FILE2${NC}"
      echo "$result"
    fi
  fi
done

echo -e "${green}syncing packages done.${NC}"
