#!/bin/bash
set +e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# only execute if user has sudo rights
if ! sudo whoami > /dev/null ; then
  echo -e "${red}ERROR: user does not have sudo rights - exiting${NC}"
  exit
fi

# NFS/PC compatibility
if [ -d "/u" ]; then
  HOME_PREFIX="/u"
else
  HOME_PREFIX="/home"
fi

echo -e "\n${yellow}Specify the user who's workspace should be analyzed:${NC}"
read -r WS_USER
WS_BASH="$HOME_PREFIX/$WS_USER/git/care-o-bot/devel/setup.bash"

if [ ! -f "$WS_BASH" ]; then
  echo -e "\n${red}File not found: $WS_BASH${NC}"
  echo -e "${yellow}Please provide a valid setup.bash script to be sourced (absolute path):${NC}"
  read -r WS_BASH
fi

 # backing up CMAKE_PREFIX_PATH
CMAKE_PREFIX_PATH_TMP=$CMAKE_PREFIX_PATH

# source workspace to analyze
echo -e "\n${green}Sourcing $WS_BASH ${NC}"
# shellcheck disable=SC1090
source "$WS_BASH"
echo -e "\n${blue}CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH ${NC}"

echo -e "\n${yellow}Do you want to analyze the workspace above (Y/n)?${NC}"
read -r answer

if echo "$answer" | grep -iq "^n" ;then
  CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH_TMP
  exit
fi

OIFS=$IFS
IFS=':'
for WORKSPACE in $CMAKE_PREFIX_PATH; do
  echo -e "\n${green}---------------------------------------------${NC}"
  echo -e "${green}Analyzing $WORKSPACE ${NC}"
  echo -e "${green}---------------------------------------------${NC}"

  # exclude /opt/ros
  if [[ "$WORKSPACE" == *"opt"* ]]; then
    echo "Nothing to be done for $WORKSPACE"
    continue
  fi

  # get base path, user and ws_dir
  base_path=${WORKSPACE%/*}
  user=$(echo "$WORKSPACE" | cut -d"/" -f 3)
  ws_dir=$(echo "$base_path" | rev | cut -d"/" -f 1 | rev)

  # fetch, branch, stash
  for f in "$base_path"/src/*; do
    if [ -d "${f}" ]; then
      echo -e "\n${blue}  > Analyzing repo $f${NC}"
      sudo su "$user" -c "cd $f > /dev/null; echo '    > git fetch'; git fetch -q -p --all; echo '    > branch list'; git branch; echo '    > stash list'; git stash list; cd - > /dev/null"
      echo ""
    fi
  done

  # determine setup_cob4 rosinstall file
  if [[ "$user" == "robot" && $ws_dir == "care-o-bot" ]]; then
    ws_rosinstall="$SCRIPTPATH/setup_robot_ws_$ROS_DISTRO.rosinstall"
  else
    ws_rosinstall="$SCRIPTPATH/setup_${ws_dir}_$ROS_DISTRO.rosinstall"
  fi

  if [ ! -f "$ws_rosinstall" ]; then
    echo -e "\nFile not found: $ws_rosinstall - using empty rosinstall file"
    ws_rosinstall="/tmp/tmp.rosinstall"
    touch "$ws_rosinstall"
  fi

  # wstool diff and info
  echo -e "\n${blue}  > wstool diff${NC}"
  echo -e "${blue}  > column left: $base_path/src/.rosinstall - column right: $ws_rosinstall${NC}"
  diff --side-by-side --suppress-common-lines "$base_path"/src/.rosinstall "$ws_rosinstall"

  echo -e "\n${blue}  > wstool info${NC}"
  sudo su "$user" -c "cd $base_path/src  > /dev/null; wstool info; cd - > /dev/null"

done

IFS=$OIFS
CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH_TMP
