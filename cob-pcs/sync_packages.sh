#!/bin/bash
set -e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

function check_hostname () {
  if [[ ${HOSTNAME} != *"$1"* ]];then
    echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED ON PC $1${NC}"
    exit
  fi
}

usage=$(cat <<"EOF"
Available options: \n
1. Upgrade Master + Sync \n
2. Specify InstallFiles (debian and pip) + Sync \n
EOF
)

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

check_hostname "b1"
echo -e $usage
read -p "Please select a sync option: " choice

if [[ "$choice" == 1 ]]; then
  ## upgrade local pc
  echo -e "${green}-------------------------------------------${NC}"
  echo -e "${green}Upgrading packages on ${HOSTNAME}${NC}"
  echo -e "${green}-------------------------------------------${NC}"
  echo ""
  declare -a upgradecommands=(
    "curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash $VERBOSE_OPTIONS" # verify git-lfs signature
    "sudo apt-get update $VERBOSE_OPTIONS"
    "sudo apt-get dist-upgrade -y $VERBOSE_OPTIONS"
    "sudo apt-get autoremove -y $VERBOSE_OPTIONS"
  )
  for command in "${upgradecommands[@]}"; do
    command_head=$(echo "$command" | head -1) 
    echo "----> executing: $command_head"
    ssh ${HOSTNAME} $command 
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -e "${red}$command return an error in ${HOSTNAME} (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""

  ## allow pip upgrade
  PIP_OPTIONS="--upgrade"

  # get installed packages
  DPKG_FILE="/u/robot/.dpkg_installed_updated.txt"
  PIP_FILE="/u/robot/.pip_installed_updated.txt"
  dpkg -l | grep '^ii' | awk '{print $2 "\t" $3}' | tr "\t" "=" > $DPKG_FILE
  sudo -H pip freeze > $PIP_FILE

elif [[ "$choice" == 2 ]]; then
  ## allow pip to downgrade - if needed
  PIP_OPTIONS="--force-reinstall"

  DPKG_FILE="/u/robot/git/setup_cob4/cob-pcs/dpkg_installed.txt"
  PIP_FILE="/u/robot/git/setup_cob4/cob-pcs/pip_installed.txt"
  echo -e "${blue}DPKG_FILE:${NC} $DPKG_FILE"
  echo -e "${blue}PIP_FILE:${NC} $PIP_FILE"
  echo -e "\n${yellow}Do you want to use the install files (y/n)?${NC}"
  read answer

  if echo "$answer" | grep -iq "^n" ;then
    echo -e "${yellow}Please provide install file for ${red}DPKG_PACKAGES${yellow} (absolute path):${NC}"
    read DPKG_FILE
    echo -e "${yellow}Please provide install file for ${red}PIP_PACKAGES${yellow} (absolute path):${NC}"
    read PIP_FILE
  fi

else
  echo -e "\n${red}INFO: Invalid option. Exiting. ${NC}\n"
  exit
fi

## check file existence
if [ ! -f $DPKG_FILE ]; then
  echo -e "\n${red}File not found: $DPKG_FILE${NC}"
  exit
fi
if [ ! -f $PIP_FILE ]; then
  echo -e "\n${red}File not found: $PIP_FILE${NC}"
  exit
fi

### check whether version can be installed
declare -a testdpkg=(
"curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash $VERBOSE_OPTIONS" # verify git-lfs signature
"sudo apt-get update $VERBOSE_OPTIONS"
"sudo apt-get -qq install -y --allow-downgrades --allow-unauthenticated --simulate $(<$DPKG_FILE) 2>&1"
"sudo apt-get autoremove -y $VERBOSE_OPTIONS"
)

declare -a testpip=(
"sudo -H pip install $PIP_OPTIONS -r $PIP_FILE 2>&1 $VERBOSE_OPTIONS"
)

set +e
echo -e "${green}-------------------------------------------${NC}"
echo -e "${green}Verifying install file${NC}"
echo -e "${green}-------------------------------------------${NC}"
echo ""
for command in "${testdpkg[@]}"; do
  command_head=$(echo "$command" | head -1) 
  echo "----> executing: $command_head"
  RESULT=$(ssh b1 $command)
  ret=${PIPESTATUS[0]}
  if [ $ret != 0 ] ; then
    while IFS= read -r line; do
      #E: Version 'VVV' for 'XXX' was not found
      if [[ "$line" =~ ^E:\ Version.*  ]]; then
        version=$(echo $line | cut -d"'" -f2)
        package=$(echo $line | cut -d"'" -f4)
        sed -i "s/$package\(\:amd64\)\?\=$version/$package/g" $DPKG_FILE
        echo -e "${yellow} $line ${NC}"
        echo -e "${yellow} -> $package will be installed with the latest version instead ${NC}"
      fi
    done <<< "$RESULT"
  fi
done
for command in "${testpip[@]}"; do
  command_head=$(echo "$command" | head -1) 
  echo "----> executing: $command_head"
  RESULT=$(ssh b1 $command)
  ret=${PIPESTATUS[0]}
  if [ $ret != 0 ] ; then
    while IFS= read -r line; do
      #AssertionError: XXX==VVV .dist-info directory not found
      if [[ "$line" =~ ^AssertionError:.*  ]]; then
        if [[ "$line" =~ .*not\ found$ ]]; then
          tmp=$(echo $line | cut -d" " -f2)
          package=$(echo $tmp | cut -d"=" -f1)
          version=$(echo $tmp | cut -d"=" -f3)
          sed -i "s/$package\=\=$version/$package/g" $PIP_FILE
          echo -e "${yellow} $line ${NC}"
          echo -e "${yellow} -> $package will be installed with the latest version instead ${NC}"
        fi
      fi
    done <<< "$RESULT"
  fi
done
set -e

## retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh

declare -a aptcommands=(
"curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash $VERBOSE_OPTIONS" # verify git-lfs signature
"sudo apt-get update $VERBOSE_OPTIONS"
"sudo apt-get -qq install -y --allow-downgrades --allow-unauthenticated $(<$DPKG_FILE) $VERBOSE_OPTIONS"
"sudo apt-get autoremove -y $VERBOSE_OPTIONS"
)

declare -a pipcommands=(
"sudo -H pip install $PIP_OPTIONS -r $PIP_FILE $VERBOSE_OPTIONS"
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
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
  for command in "${pipcommands[@]}"; do
    command_head=$(echo "$command" | head -1)
    echo "----> executing: $command_head"
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -e "${red}$command return an error in $client (error code: $ret), aborting...${NC}"
      exit 1
    fi
  done
  echo ""
}

if "$PARALLEL"; then
  pids=""
  for client in $client_list_hostnames; do
    ( sync_client $client &> /tmp/sync_$client ) & #run process in background
    pids+=" $!" # store PID of process
    echo -e "${green}PID for sync_client $client is $!${NC}"
  done

  # wait for all processes to finnish
  sync_failure=false
  for p in $pids; do
    if wait $p; then
      echo -e "${green}Process $p success${NC}"
    else
      echo -e "${red}Process $p fail${NC}"
      sync_failure=true
    fi
  done

  # print output of sync process for each client
  for client in $client_list_hostnames; do
    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Result for $client${NC}"
    echo -e "${green}-------------------------------------------${NC}"
    echo ""
    cat /tmp/sync_$client
  done

  # exit in case of failure
  if "$sync_failure"; then
    echo -e "${red}Failed to sync a client, aborting...${NC}"
    exit 1
  fi
else
  for client in $client_list_hostnames; do
    sync_client $client
  done
fi

## clean up
if [ -f ~/.dpkg_installed_updated.txt ]; then
  rm ~/.dpkg_installed_updated.txt
fi
if [ -f ~/.pip_installed_updated.txt ]; then
  rm ~/.pip_installed_updated.txt
fi

## updating the package files
DPKG_LATEST="/u/robot/dpkg_installed_sync_$(date '+%Y%m%d_%H%M%S').txt"
DPKG_SETUPCOB4="/u/robot/git/setup_cob4/cob-pcs/dpkg_installed.txt"
PIP_LATEST="/u/robot/pip_installed_sync_$(date '+%Y%m%d_%H%M%S').txt"
PIP_SETUPCOB4="/u/robot/git/setup_cob4/cob-pcs/pip_installed.txt"
dpkg -l | grep '^ii' | awk '{print $2 "\t" $3}' | tr "\t" "=" > $DPKG_LATEST
sudo -H pip freeze > $PIP_LATEST

declare -a commands=(
  "diff $DPKG_LATEST $DPKG_SETUPCOB4; echo \$?;"
  "diff $PIP_LATEST $PIP_SETUPCOB4; echo \$?;"
)
for command in "${commands[@]}"; do
  echo "----> executing: $command"
  result=$(ssh $client $command)
  ret=$(echo "$result" | tail -n1)
  if [ $ret != 0 ] ; then
    echo -e "${yellow}Found a difference between LATEST install files and SETUP_COB4 install file."
    echo -e "Please merge/sync/update the install files in '~/git/setup_cob4/cob-pcs' and create a PR!${NC}"
    echo "$result"
  fi
done

echo -e "${green}syncing packages done.${NC}"
