#!/bin/bash
set -e

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)

function setup_ws {
    set -e
    new_ws=$1
    chained_ws=$2
    echo -e "${green}-------------------------------------------${NC}"
    echo -e "${green}Creating new workspace ${NC}"
    echo -e "${green}   WORKSPACE: $new_ws ${NC}"
    echo -e "${green}   UNDERLAY:  $chained_ws ${NC}"
    echo -e "${green}-------------------------------------------${NC}"

    rm -rf $new_ws/src/*
    rm -rf $new_ws/src/.rosinstall
    mkdir -p $new_ws/src

    ###############################################
    ### install dependencies from previous runs ###
    ###############################################
    # this is needed for multiple executions
    cd $new_ws
    install_dependencies
    
    ################################
    ### setup workspace chaining ###
    ################################
    cd $new_ws
    unset CMAKE_PREFIX_PATH
    source $chained_ws
    catkin init --reset
    catkin config -DCMAKE_BUILD_TYPE=Release
    catkin clean -y
    catkin build

    ######################
    ### fill workspace ###
    ######################
    cd $new_ws/src
    if [ ! -f .rosinstall ]; then
        wstool init
    fi
    if [ -z ${3+x} ]; then
        rosinstall=$SCRIPTPATH/setup_`basename $new_ws`_${ROS_DISTRO}_default.rosinstall
    else
        rosinstall=$3
    fi

    echo -e "${blue}Create workspace with $rosinstall ${NC}"
    wstool merge --merge-replace -y $rosinstall
    if [ $? -ne 0 ]; then
        echo -e "${red}Could not setup $new_ws workspace ${NC}"
        exit -1
    fi
    wstool update --delete-changed-uris
    
    ############################
    ### install dependencies ###
    ############################
    cd $new_ws
    install_dependencies
    
    #######################
    ### build workspace ###
    #######################
    cd $new_ws
    catkin build
    
    source $new_ws/devel/setup.bash
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
        unset CMAKE_PREFIX_PATH
        source $chained_ws
        catkin init --reset
        catkin clean -y
        rosdep install --as-root pip:true --from-path src -i -y
    else
        echo -e "${red}ERROR: Wrong mode, expecting [robot]. Got: $mode ${NC}"
        exit 2
    fi
}

############
### main ###
############
mode="robot"
echo -e "${blue}Using mode: $mode ${NC}"

echo -e "\n${red}This will remove/overwrite your current workspace!${NC}"
echo -e "\n${yellow}Do you want to continue? (Y/n)?${NC}"
read answer

if echo "$answer" | grep -iq "^n" ;then
  exit
fi

# check if ROS_DISTRO is sourced
if [ $(lsb_release -sc) == "xenial" ]; then
  source /opt/ros/kinetic/setup.bash
else
  echo -e "${red}FATAL: Script only supports ROS Kinetic"
  exit 3
fi
: ${ROS_DISTRO:?"not sourced"}

if [ "$mode" == "robot" ]; then
    echo -e "${blue}Installation on robot! ${NC}"
    rosdep update
    export mode
    export SCRIPTPATH
    export -f setup_ws
    export -f install_dependencies
    setup_ws ~/git/care-o-bot /opt/ros/${ROS_DISTRO}/setup.bash ${SCRIPTPATH}/setup_robot_ws_${ROS_DISTRO}_default.rosinstall
else
    echo -e "${red}ERROR: Wrong mode, expecting [robot]. Got: $mode ${NC}"
    exit 2
fi

echo -e "\n\n${green}setup_workspace completed${NC}"
