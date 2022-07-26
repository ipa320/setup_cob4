#!/usr/bin/env bash
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

# backing up CMAKE_PREFIX_PATH
CMAKE_PREFIX_PATH_TMP=$CMAKE_PREFIX_PATH

# user specification
echo -e "\n${yellow}Specify the user who's workspace should be analyzed (Press <ENTER> for '$USER'):${NC}"
read -r WS_USER
if [ -z "$WS_USER" ]; then
  WS_USER=$USER
fi
if ! id "$WS_USER" &>/dev/null; then
  echo -e "${red}FATAL: user $WS_USER not known ${NC}"
  exit 1
fi

# workspace specification
while true
do
  if [ -z "$CMAKE_PREFIX_PATH" ]; then
    DEFAULT_WS_BASH="$HOME_PREFIX/$WS_USER/git/care-o-bot/devel/setup.bash"
    echo -e "${yellow}Please provide a valid setup.bash script to be sourced (absolute path, Press <ENTER> for '$DEFAULT_WS_BASH'):${NC}"
    read -r WS_BASH
    if [ -z "$WS_BASH" ]; then
      WS_BASH=$DEFAULT_WS_BASH
    fi
    if [ ! -f "$WS_BASH" ]; then
      echo -e "\n${red}File not found: '$WS_BASH'${NC}"
      continue
    else
      echo -e "\n${green}Sourcing $WS_BASH ${NC}"
      # shellcheck disable=SC1090
      source "$WS_BASH"
    fi
  fi
  echo -e "\n${blue}CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH ${NC}"
  echo -e "\n${yellow}Do you want to analyze the workspace above (y/N)?${NC}"
  read -r answer
  if echo "$answer" | grep -iq "^y" ;then
    break
  else
    unset CMAKE_PREFIX_PATH
  fi
done

# query tagged or default
echo -e "${yellow}Do you use tagged workspace or the latest default [t:tagged/d:default]? ${NC}"
read -r answer
if echo "$answer" | grep -iq "^t" ;then
  tagged=true
else
  tagged=false
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
      sudo su "$user" -c "cd $f > /dev/null; echo '    > git fetch'; git fetch -q -p --all; echo '    > branch list'; git branch; cd - > /dev/null"
      echo ""
      sudo su "$user" -c "cd $f > /dev/null; echo '    > git stash list'; cd - > /dev/null"
      res=$(sudo su "$user" -c "cd $f > /dev/null; git stash list; cd - > /dev/null")
      if [[ -n "${res// }" ]]; then
        echo -e "${red}$f has local stashes${NC}"
        echo -e "${red}\t$res${NC}"
        echo ""
      fi
    fi
  done

  # determine setup_cob4 rosinstall file
  if [[ $ws_dir == "app_ws" ]]; then
    ws_rosinstall="$SCRIPTPATH/setup_${ws_dir}_full_$ROS_DISTRO"
  else
    ws_rosinstall="$SCRIPTPATH/setup_${ws_dir}_$ROS_DISTRO"
  fi

  # tagged or default?
  if $tagged ; then
    ws_rosinstall+=".rosinstall"
  else
    ws_rosinstall+="_default.rosinstall"
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
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo -e "${red}The local rosinstall file differs from $ws_rosinstall - you might want to update it${NC}"
  else
    echo -e "${green}The local rosinstall file is up to date with $ws_rosinstall${NC}"
  fi

  echo -e "\n${blue}  > wstool info${NC}"
  sudo su "$user" -c "cd $base_path/src  > /dev/null; wstool info; cd - > /dev/null"

  echo -e "\n${blue}  > wstool differences${NC}"
  res=$(sudo su "$user" -c "cd $base_path/src  > /dev/null; wstool info --managed-only --data-only --untracked --short|tail -n +3; cd - > /dev/null")
  while read -r line
  do
    if [ "$(echo "$line" | awk '{print NF}' | sort -nu | tail -n 1)" -ge 3 ]; then
      echo -e "${red}There are changes in: $(echo "$line"|awk '{ print $1; }')${NC}"
    fi
  done <<< "$res"

done

IFS=$OIFS
CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH_TMP
