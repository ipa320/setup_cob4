#!/bin/bash
set -e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m'        # No Color

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTNAME=$(basename "$0")

function setup_workspace {
  set -e
  new_ws=$1
  chained_ws=$2

  # generate path to rosinstall file
  rosinstall="$SCRIPTPATH/setup_$(basename "$new_ws")_${ROS_DISTRO}${ws_suffix}.rosinstall"

  # if no target_user is set (e.g. for local installation), install on current user
  # also install robot_ws on current user (e.g. on robot)
  if [ -z  "${target_user}" ] || [[ $new_ws == *"robot_ws"* ]]; then
    clean_workspace "$new_ws"
    populate_workspace "$new_ws" "$chained_ws" "$rosinstall" "$install" "$build_args"
    echo -e "${green}install dependencies to $new_ws ${NC}"
    cd "$new_ws" && install_dependencies
    build_workspace "$new_ws" "$build_args"
  else
    # export colors
    export red yellow green blue NC
    sudo -E su "$target_user" -c "$(declare -pf clean_workspace); clean_workspace $new_ws"
    sudo -E su "$target_user" -c "$(declare -pf populate_workspace); populate_workspace $new_ws $chained_ws $rosinstall $install $build_args"
    echo -e "${green}install dependencies to $new_ws ${NC}"
    cd "$new_ws" && install_dependencies
    sudo -E su "$target_user" -c "$(declare -pf build_workspace); build_workspace $new_ws $build_args"
  fi
}

function clean_workspace {
    set -e
    new_ws=$1

    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Cleaning workspace ${NC}"
    echo -e "${green}   WORKSPACE: $new_ws ${NC}"
    echo -e "${green}-------------------------------------------${NC}"

    rm -rf "$new_ws"
    mkdir -p "$new_ws"/src
}

function populate_workspace {
    set -e
    new_ws=$1
    chained_ws=$2
    rosinstall=$3
    install=$4
    build_args=$5  # build args always need to be the last argument, because they can be empty

    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Creating new workspace ${NC}"
    echo -e "${green}   WORKSPACE: $new_ws ${NC}"
    echo -e "${green}   UNDERLAY:  $chained_ws ${NC}"
    echo -e "${green}   ROSINSTALL FILE:  $(basename "$rosinstall") ${NC}"
    echo -e "${green}   USE INSTALL SPACE:  $install ${NC}"
    echo -e "${green}   BUILD ARGS:  $build_args ${NC}"
    echo -e "${green}-------------------------------------------${NC}"

    ######################
    ### init workspace ###
    ######################
    echo -e "${green}reset workspace $new_ws ${NC}"
    cd "$new_ws"
    unset CMAKE_PREFIX_PATH
    # shellcheck disable=SC1090
    source "$chained_ws"
    catkin init --reset
    echo -e "${blue}configure -DCMAKE_BUILD_TYPE=Release ${NC}"
    catkin config -DCMAKE_BUILD_TYPE=Release
    if [ "$install" = true ] && [ ! "$(basename "$new_ws")" == "care-o-bot" ]; then  # still use devel space for care-o-bot
      echo -e "${blue}configure --install ${NC}"
      catkin config --install
    else
      echo -e "${blue}configure --no-install ${NC}"
      catkin config --no-install
    fi
    catkin clean -y
    echo -e "${green}catkin build $new_ws with args: $build_args ${NC}"
    # diabled shellcheck because empty build_args will fail 
    # shellcheck disable=SC2086
    cd "$new_ws" && catkin build $build_args

    ######################
    ### fill workspace ###
    ######################
    echo -e "${blue}fill workspace with $rosinstall ${NC}"
    cd "$new_ws"/src
    if [ ! -f .rosinstall ]; then
        wstool init
    fi
    
    if ! wstool merge --merge-replace -y "$rosinstall" ; then
        echo -e "${red}Could not setup $new_ws workspace ${NC}"
        exit 1
    fi
    echo -e "${green}wstool update $new_ws ${NC}"
    wstool update --delete-changed-uris
}

function build_workspace {
    set -e
    new_ws=$1
    build_args=$2  # build args always need to be the last argument, because they can be empty

    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Building new workspace ${NC}"
    echo -e "${green}   WORKSPACE: $new_ws ${NC}"
    echo -e "${green}   BUILD ARGS:  $build_args ${NC}"
    echo -e "${green}-------------------------------------------${NC}"

    #######################
    ### build workspace ###
    #######################
    echo -e "${green}catkin build $new_ws with args: $build_args ${NC}"
    # diabled shellcheck empty build_args will fail 
    # shellcheck disable=SC2086
    cd "$new_ws" && catkin build $build_args

    if [ "$cleanup" = true ] && [ ! "$(basename "$new_ws")" == "care-o-bot" ]; then  # do not cleanup devel space for care-o-bot
      cd "$new_ws"
      catkin clean --logs --build --devel --yes  # cleanup log, build and devel space
      rm -rf "$new_ws"/src                       # remove source space
    fi
    echo -e "${green}done $new_ws ${NC}"
}

function install_dependencies {
    # check if rosdep is satisfied
    # do not cancel script during this step on error
    # if deps are missing we would like to install them
    # instead of canceling the script
    set +e
    if (rosdep check --from-path src -i -y); then
        echo -e "${blue}  -> rosdep satisfied ${NC}"
        set -e
        return
    else
        echo -e "${blue}  -> need to install packages ${NC}"
    fi
    # enable script cancelation on first error
    set -e

    if [ "$mode" == "robot" ]; then
        echo -e "${green}execute rosdep install ${NC}"
        unset CMAKE_PREFIX_PATH
        # shellcheck disable=SC1090
        source "$chained_ws"
        rosdep install --rosdistro="${ROS_DISTRO}" --as-root pip:true --from-path src -i -y
    elif [ "$mode" == "local" ]; then
        if has_root_privilege ; then
            echo -e "${green}execute rosdep install ${NC}"
            unset CMAKE_PREFIX_PATH
            # shellcheck disable=SC1090
            source "$chained_ws"
            rosdep install --rosdistro="${ROS_DISTRO}" --from-path src -i -y
        else
            echo -e "${yellow}Enter sudo user name:${NC}"
            read -r sudo_user_name
            if id "$sudo_user_name" &>/dev/null; then
                echo -e "${yellow}Enter '$sudo_user_name' password:${NC}"
                su "$sudo_user_name" -c "
                unset CMAKE_PREFIX_PATH
                source $chained_ws
                rosdep install --rosdistro=${ROS_DISTRO} --as-root pip:true --from-path src -i -y"
            else
                echo -e "${red}FATAL: user '$sudo_user_name' not found! Install the missing dependencies from a user that has sudo rights ${NC}"
                exit 1
            fi
        fi
    fi
}

function install_prerequisites {
  set -e
  # install essentials
  echo -e "${blue}install essentials ${NC}"
  if [ "$ROS_DISTRO" == "kinetic" ]; then
    sudo apt-get install build-essential python-catkin-tools python-wstool -y
    sudo apt-get install python-rosinstall python-rosinstall-generator -y
    sudo apt-get install python-pip python-rosdep python-rospkg curl -y
  elif [ "$ROS_DISTRO" == "noetic" ]; then
    sudo apt-get install build-essential python3-catkin-tools python3-osrf-pycommon python3-wstool -y
    sudo apt-get install python3-rosinstall python3-rosinstall-generator -y
    sudo apt-get install python3-pip python3-rosdep python3-rospkg curl -y
  fi
  if [ ! -d  /etc/ros/rosdep ] ; then
    sudo rosdep init
  fi

  # install git-lfs
  if ! command -v git-lfs 1>/dev/null; then
    echo -e "${blue}installing git-lfs ${NC}"
    if [ "$(lsb_release -sc)" == "xenial" ]; then
      curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    fi
    sudo apt-get install git-lfs -y
  else
    echo -e "${blue}git-lfs already installed ${NC}"
  fi
  git lfs install

  # install problematic pip packages
  if [ "$(lsb_release -sc)" == "xenial" ]; then
    echo -e "${blue}installing pip packages ${NC}"
    sudo -H pip install -q --no-deps dialogflow google-cloud-speech google-cloud-texttospeech slackclient
  fi

  # check mandatory packages
  mandatory_dpkg_pkgs=("git-lfs" "bash")
  dpkg -s "${mandatory_dpkg_pkgs[@]}" >/dev/null 2>&1 || (echo -e "${red}FATAL: Missing some of the following mandatory packages: " "${mandatory_dpkg_pkgs[@]}" "${NC}"; exit 1)
  echo -e "${blue}All mandatory packages installed: " "${mandatory_dpkg_pkgs[@]}" "${NC}"
}

has_root_privilege()
{
  # check user privilege
  set +e
  ret=$(sudo whoami 2>&1)
  set -e
  [ "$ret" == "root" ]
}

show_help(){
  echo "Usage: $SCRIPTNAME [-h] [-q] [-f] [-t] [-i] [-c] [-u user] -m mode"
  echo "-h | --help:    show help and exit"
  echo "-q | --quiet:   quiet   (optional)   - less verbose output         (default: false)"
  echo "-f | --force:   force   (optional)   - do not ask for confirmation (default: false)"
  echo "-t | --tagged:  tagged  (optional)   - use tagged versions         (default: false, i.e. use default branches)"
  echo "-i | --install: install (optional)   - build to install space      (default: false, i.e. use devel space)"
  echo "-c | --cleanup: cleanup (optional)   - cleanup source space        (default: false, i.e. keep source space)"
  echo "-u | --user:    user    (optional)   - target_user for installing non-robot-ws workspaces (required only for installation in mode: 'robot')"
  echo "-p | --path:    path    (optional)   - target path/directory for setup_workspace (default: apply default logic, i.e. \$HOME/git, \$(eval echo ~\$target_user) and \$(eval echo ~\$USER) depending on mode)"
  echo "-m | --mode:    mode    (mandatory)  - installation mode [robot/local]"
  echo "--underlay:     underlay(optional)   - underlay to source before starting setup_workspaces (default: /opt/ros/\$ROS_DISTRO/setup.bash"
  echo ""
}

############
### main ###
############

# parse arguments
unset path      # optional  - when not set, apply default logic, i.e. $HOME/git, $(eval echo ~$target_user) and $(eval echo ~$USER) depending on mode
quiet=false     # optional  - default: false
force=false     # optional  - default: interactive
tagged=false    # optional  - default: default branch
install=false   # optional  - default: catkin build to devel space
cleanup=false   # optional  - default: do not cleanup, i.e. keep source space
mode=""         # mandatory - [robot/local]
if [ "$(lsb_release -sc)" == "focal" ]; then
  underlay="/opt/ros/noetic/setup.bash"
else
  echo -e "${red}FATAL: Script only supports ROS Noetic ${NC}"
  exit 1
fi

while (( "$#" )); do
  case $1 in
  "-h" | "--help") shift
    show_help
    exit 0
    ;;
  "-q" | "--quiet") shift
    quiet=true
    ;;
  "-f" | "--force") shift
    force=true
    ;;
  "-t" | "--tagged") shift
    tagged=true
    ;;
  "-i" | "--install") shift
    install=true
    ;;
  "-c" | "--cleanup") shift
    cleanup=true
    ;;
  "-u" | "--user") shift
    target_user=$1
    shift
    ;;
  "-p" | "--path") shift
    path=$1
    shift
    ;;
  "-m" | "--mode") shift
    mode=$1
    shift
    ;;
  "--underlay") shift
    underlay=$1
    shift
    ;;
  *)
    break
    ;;
  esac
done

# check mode
if [ "$mode" != "local" ] && [ "$mode" != "robot" ]; then
    echo -e "${red}ERROR: Wrong mode, expecting '-m [local|robot]'. Got: '$mode' ${NC}"
    exit 1
else
    echo -e "${blue}Using mode: '$mode' ${NC}"
fi
if [ "$mode" == "robot" ]; then
  if has_root_privilege ; then
    force=false  # never force on robot!
  else
    echo -e "${red}FATAL: user '$USER' has no sudo rights - execute on user with sudo rights (e.g. 'robot')${NC}"
    exit 1
  fi
fi
if [ "$mode" == "local" ] && [ "$target_user" != "" ]; then
    echo -e "${red}Option '-u' only valid for installation on robot - resetting target user${NC}"
    # install everything on the calling user
    unset target_user
fi

# query additional info - interactive
if ! $force ; then
  # confirm deletion of workspace
  echo -e ""
  echo -e "${red}This will remove/overwrite your current workspace!${NC}"
  echo -e "${yellow}Do you want to continue? (Y/n)?${NC}"
  read -r answer
  if echo "$answer" | grep -iq "^n" ; then
    exit 1
  fi
fi

# quiet or default?
if $quiet ; then
  build_args="--no-status"
else
  build_args=""
fi

# devel or install
if $install ; then
  build_target="install"
else
  build_target="devel"
  cleanup=false  # never cleanup without install
fi

# tagged or default?
if $tagged ; then
  ws_suffix=""
else
  ws_suffix="_default"
fi

# check if ROS_DISTRO is sourced
# shellcheck disable=SC1090
source "$underlay"
: "${ROS_DISTRO:?"not sourced"}"

echo "mode='$mode', quiet=$quiet, force=$force, tagged=$tagged, install=$install, cleanup=$cleanup, user='$target_user', path='${path:-default_logic}' underlay='$underlay', leftovers: $*"

# start setup
if [ "$mode" == "robot" ]; then
    echo -e "${blue}Installation on robot! ${NC}"
    target_user="robot"
elif [ "$mode" == "local" ]; then
    echo -e "${blue}Installation on local computer ${NC}"
fi

echo -e "${green}rosdep update $USER ${NC}"
rosdep update --rosdistro="${ROS_DISTRO}"

if has_root_privilege ; then
  echo -e "${green}apt-get update ${NC}"
  sudo apt-get update
  echo -e "${green}install prerequisites ${NC}"
  install_prerequisites
fi

echo -e "${green}setup robot_ws ${NC}"
echo -e "PATH: ${path:-$HOME/git}"/robot_ws "$underlay"
setup_workspace "${path:-$HOME/git}"/robot_ws "$underlay"
# integrate care-o-bot ws of robot user (has been set up by PostInstall)
if [ "$mode" == "robot" ]; then
  care_o_bot_ws=${path:-$HOME/git}/care-o-bot
  cd "$care_o_bot_ws"
  unset CMAKE_PREFIX_PATH
  # shellcheck disable=SC1090
  source "${path:-$HOME/git}"/robot_ws/${build_target}/setup.bash
  catkin init --reset
  echo -e "${blue}configure -DCMAKE_BUILD_TYPE=Release ${NC}"
  catkin config -DCMAKE_BUILD_TYPE=Release
  # no 'catkin config --install' because we still use devel space for care-o-bot
  catkin clean -y
  echo -e "${green}catkin build $care_o_bot_ws with args: $build_args ${NC}"
  # diabled shellcheck because empty build_args will fail 
  # shellcheck disable=SC2086
  cd "$care_o_bot_ws" && catkin build $build_args
  # do not cleanup devel space for care-o-bot because we still use devel space for care-o-bot
elif [ "$mode" == "local" ]; then
  : # noop
fi

echo -e "\n\n${green}$SCRIPTNAME completed${NC}"
if [ "$mode" == "robot" ]; then
  echo -e "\n${blue}Make sure to run 'setup_cob4/cob-pcs/sync_packages.sh' next!${NC}"
fi
