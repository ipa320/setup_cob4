#!/bin/bash

set -e # force the script to exit if any error occurs
#set -o xtrace # print all commands before executing

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

#### COMMON PARAMETERS
usage=$(cat <<"EOF"
INFO: This script is a helper tool for the setup and installation of Care-O-bot:
1. Setup root user
2. Setup robot user
3. Setup mimic user
4. Setup devices (e.g. systemd service and scripts for laser scanners detection)
5. Install system services (upstart, ...)
6. SetupWorkspaces
9. SyncPackages
99. Full installation
EOF
)

upstart_selection=$(cat << "EOF"
INFO: The following upstart variants are available:
0. skip (do not update upstart configuration)
1. cob_bringup
2. custom upstart (specify path to yaml)
EOF
)

red='\e[0;31m'    # ERROR
yellow='\e[0;33m' # USER_INPUT
green='\e[0;32m'  # STATUS_PROGRESS
blue='\e[1;34m'   # INFORMATION
NC='\e[0m' # No Color

#### retrieve client_list variables
# shellcheck source=./helper_client_list.sh
source "$SCRIPTPATH"/helper_client_list.sh
# shellcheck source=./helper_component_list.sh
source "$SCRIPTPATH"/helper_component_list.sh

#### check hostname
function check_hostname () {
  if [[ ${HOSTNAME} != *"$1"* ]];then
    echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED ON PC $1${NC}"
    exit 1
  fi
}

function get_search_domain () {
  grep "^search" /etc/resolv.conf | sed -e "s/^search //"
}

#### DEFINE SPECIFIC LIST OF PCs
function query_pc_list {
  echo -e "${blue}PC_LIST:${NC} $1"
  echo -e "\n${yellow}Do you want to use the suggested pc list (y/N)?${NC}"
  read -r answer

  if echo "$answer" | grep -iq "^y" ;then
    LIST=$1
  else
    echo -e "\n${yellow}Enter your list of pcs of your robot:${NC}"
    read -r LIST
  fi
}

#### SETUP ROOT USER
function SetupRootUser {
  check_hostname "b1"
  echo -e "\n${green}=== SETUP ROOT USER ===${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupRootUser${NC}\n"
  # shellcheck disable=SC2154
  query_pc_list "$client_list_hostnames $component_list_hostnames" # confirm list of hostnames used for password-less login (includes pcs and components)
  pc_list=$LIST

  #generate a ssh key for root user per pc
  if sudo grep -q SSH_ASKPASS "/root/.bashrc"; then
    echo -e "\n${blue}INFO: Found SSH_ASKPASS${NC}\n"
  else
    sudo sh -c "echo 'unset SSH_ASKPASS' >> /root/.bashrc"
  fi

  if sudo test -f "/root/.ssh/id_rsa.pub"; then
    echo -e "\n${blue}INFO: ssh key exists for root${NC}\n"
  else
    echo -e "${blue}INFO: creating new ssh key${NC}"
    sudo su - root -c "ssh-keygen -f /root/.ssh/id_rsa -N ''"
    sudo su - root -c "ssh-keyscan -H localhost >> /root/.ssh/known_hosts"
    sudo -u root -i ssh-copy-id -i /root/.ssh/id_rsa.pub root@localhost
    sudo -u root -i ssh root@localhost 'exit'
    sudo cat /root/.ssh/id_rsa.pub | \
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    root@localhost "sudo tee -a /root/.ssh/authorized_keys"
  fi

  for i in $pc_list; do
    if [[ $i == *"flexisoft"* ]]; then # we cannot ssh into flexisoft
        echo "skipping $i"
        continue
    fi
    sudo su - root -c "ssh-keyscan -H $i >> /root/.ssh/known_hosts"
    sudo -u root -i ssh-copy-id -i /root/.ssh/id_rsa.pub root@"$i"
    sudo -u root -i ssh root@"$i" 'exit'
    sudo cat /root/.ssh/id_rsa.pub | sudo ssh root@"$i" "mkdir -p /root/.ssh && cat >>  /root/.ssh/authorized_keys"
  done
  echo -e "${green}=== SETUP ROOT USER DONE! ===${NC}"
}

#### SETUP ROBOT USER
function SetupRobotUser {
  check_hostname "b1"
  echo -e "\n${green}=== SETUP ROBOT USER ===${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupRobotUser${NC}\n"
  query_pc_list "$client_list_hostnames"
  pc_list=$LIST

  "$SCRIPTPATH"/cob-adduser robot

  # shellcheck disable=SC1090
  source /opt/ros/"$ROS_DISTRO"/setup.bash

  if grep "source /u/robot/setup/user.bashrc" /u/robot/.bashrc > /dev/null; then
    echo -e "${blue}INFO: .bashrc already configured${NC}"
  else
    "$SCRIPTPATH"/cob-adduser robot
  fi

  if [ -d /u/robot/git/care-o-bot/src ]; then
    echo -e "${blue}INFO: robot workspace already exits${NC}"
  else
    mkdir -p /u/robot/git/care-o-bot/src
    # shellcheck disable=SC1091
    source /u/robot/.bashrc
    cd /u/robot/git/care-o-bot/ && catkin init
    cd /u/robot/git/care-o-bot/ && catkin config -DCMAKE_BUILD_TYPE=Release
    cd /u/robot/git/care-o-bot/ && catkin build
  fi

  for i in $pc_list; do
    sudo -u root -i ssh-copy-id robot@"$i"
    sudo -u root -i ssh robot@"$i" 'exit'
  done
  echo -e "${green}=== SETUP ROBOT USER DONE! ===${NC}"
}

#### SETUP MIMIC USER
function SetupMimicUser {
  check_hostname "b1"
  echo -e "${green}=== SETUP MIMIC USER ===${NC}"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupMimicUser${NC}\n"
  query_pc_list "h1"
  pc_head=$LIST
  if [ -z "$pc_head" ]; then
    echo -e "${blue}WARN: no head pc, skipping setup mimic user${NC}"
    return
  fi
  if ! sudo ssh "$pc_head" "exit"; then
    echo -e "${blue}WARN: head pc $pc_head not reachable, skipping setup mimic user${NC}"
    return
  fi

  "$SCRIPTPATH"/cob-adduser mimic

  GDM_PATH=/etc/gdm3/custom.conf
  sudo ssh "$pc_head" "sed -i s/'#  TimedLoginEnable = true'/'TimedLoginEnable = true'/g $GDM_PATH"
  sudo ssh "$pc_head" "sed -i s/'#  TimedLogin = user1'/'TimedLogin = mimic'/g $GDM_PATH"
  sudo ssh "$pc_head" "sed -i s/'#  TimedLoginDelay = 10'/'TimedLoginDelay = 10'/g $GDM_PATH"

  DESKTOP_PATH=/u/mimic/.config/autostart
  if sudo test -d $DESKTOP_PATH; then
    echo -e "${blue}Folder $DESKTOP_PATH exists${NC}"
  else
    sudo su mimic -c "mkdir -p /u/mimic/.config/autostart/"
  fi

  sudo su mimic -c "cat <<EOF > $DESKTOP_PATH/xhost.desktop
[Desktop Entry]
Type=Application
Exec=xhost +
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=mimic
Name=mimic
Comment[en_US]=
Comment=
EOF"

    sudo su mimic -c "cat <<EOF > $DESKTOP_PATH/rotation.desktop
[Desktop Entry]
Type=Application
Exec=xrandr -o right
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=2
Name[en_US]=rotation
Name=rotation
Comment[en_US]=rotation
Comment=rotation
EOF"

  #Brightness and lock
  sudo -u mimic -i ssh "$pc_head" 'dbus-launch gsettings set org.gnome.desktop.screensaver lock-enabled false'
  sudo -u mimic -i ssh "$pc_head" 'dbus-launch gsettings set org.gnome.desktop.session idle-delay 0'

  #Background
  sudo su mimic -c "cp -f $SCRIPTPATH/mimic.jpg /u/mimic/mimic.jpg"
  command_setbackground="dbus-launch gsettings set org.gnome.desktop.background picture-uri file:/u/mimic/mimic.jpg"
  sudo su mimic -c "ssh $pc_head $command_setbackground"

  echo -e "${green}=== SETUP MIMIC USER DONE! ===${NC}"
}

#### SETUP DEVICES
function SetupDevices {
  check_hostname "b1"
  echo -e "${green}=== SETUP DEVICES ===${NC}"
  echo -e "\n${green}INFO: Setup cob-devices service and script for scanners and joystick${NC}\n"

  echo -e "\n${blue}INFO: copy cob-devices.sh to /sbin/cob-devices${NC}"
  sudo cp -f "$SCRIPTPATH"/scripts/cob-devices.sh /sbin/cob-devices.sh
  echo -e "\n${blue}INFO: copy cob-devices.service to /etc/systemd/system/cob-devices.service${NC}\n"
  sudo cp -f "$SCRIPTPATH"/upstart/cob-devices.service /etc/systemd/system/cob-devices.service

  for file in /dev/ttyUSB*; do
    sudo chmod 666 "$file"
    sudo rm -f /tmp/usb"${file: -1}"
    sudo udevadm info -a -p "$(udevadm info -q path -n "${file}")" | tee /tmp/usb"${file: -1}" > /dev/null
    sudo chmod 666 /tmp/usb"${file: -1}"
  done

  results=()
  count=0

  for file in /tmp/usb*; do
    if grep --quiet 'ATTRS{serial}=="F' "$file"; then
      # shellcheck disable=SC2010
      result=$(ls -l |grep -R 'ATTRS{serial}=="F' "$file")
      echo -e "${blue}found scanner with $result ${NC}"
      results[$count]=$result
      count=$((count+1))
    fi
  done

  echo -e "${blue}found $count scanners: " "${results[@]}" " ${NC}"

  if [[ ${results[0]} == "${results[1]}" ]]; then
    ATTRSSerialFL=${results[0]}
    ATTRSSerialR=${results[2]}
  elif [[ ${results[1]} == "${results[2]}" ]]; then
    ATTRSSerialFL=${results[1]}
    ATTRSSerialR=${results[0]}
  elif [[ ${results[0]} == "${results[2]}" ]]; then
    ATTRSSerialFL=${results[0]}
    ATTRSSerialR=${results[1]}
  fi

  # shellcheck disable=SC2001
  ATTRSSerialFL="$( echo "$ATTRSSerialFL" | sed 's/ //g' )"
  # shellcheck disable=SC2001
  ATTRSSerialR="$( echo "$ATTRSSerialR" | sed 's/ //g' )"

  sudo sed -i -re "s/(ScanFrontAttr2=).*/\1'${ATTRSSerialFL}'/g" /sbin/cob-devices.sh
  sudo sed -i -re "s/(ScanLeftAttr2=).*/\1'${ATTRSSerialFL}'/g" /sbin/cob-devices.sh
  sudo sed -i -re "s/(ScanRightAttr2=).*/\1'${ATTRSSerialR}'/g" /sbin/cob-devices.sh

  sudo systemctl enable cob-devices.service

  if [ $count -eq 3 ]; then
    echo -e "${green}=== SETUP DEVICES DONE! ===${NC}"
  else
    echo -e "${yellow}setup devices done, but only found $count scanners instead of 3 (see above)${NC}"
  fi
}

#### INSTALL SYSTEM SERVICES
function InstallSystemServices {
  check_hostname "b1"
  echo -e "${green}=== INSTALL SYSTEM SERVICES ===${NC}"
  echo -e "\n${green}INFO: Install System Services (upstart,...)${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for InstallSystemServices${NC}\n"
  query_pc_list "$client_list_hostnames"
  client_list=$LIST

  echo -e "${green}Installing cob service${NC}"
  sudo cp -f "$SCRIPTPATH"/upstart/cob.service /etc/systemd/system/cob.service
  sudo systemctl enable cob.service

  for i in $client_list; do
    echo -e "${blue}Installing tmux service on $i ${NC}"
    sudo -u root -i ssh robot@"$i" "sudo cp -f $SCRIPTPATH/upstart/tmux.service /etc/systemd/system/tmux.service"
    sudo -u root -i ssh robot@"$i" "sudo systemctl enable tmux.service"

    echo -e "${blue}Installing chrony-wait service on $i ${NC}"
    sudo -u root -i ssh robot@"$i" "sudo cp -f $SCRIPTPATH/upstart/chrony-wait.service /etc/systemd/system/chrony-wait.service"
    sudo -u root -i ssh robot@"$i" "sudo systemctl enable chrony-wait.service"
  done

  # install cob scripts
  sudo cp -f "$SCRIPTPATH"/scripts/robmuxinator /usr/sbin/robmuxinator
  sudo cp -f "$SCRIPTPATH"/scripts/cob-start /usr/sbin/cob-start
  sudo cp -f "$SCRIPTPATH"/scripts/cob-restart /usr/sbin/cob-restart
  sudo cp -f "$SCRIPTPATH"/scripts/cob-stop /usr/sbin/cob-stop
  sudo cp -f "$SCRIPTPATH"/scripts/cob-shutdown /usr/sbin/cob-shutdown
  sudo cp -f "$SCRIPTPATH"/scripts/cob-powerbutton /usr/sbin/cob-powerbutton
  sudo cp -f "$SCRIPTPATH"/scripts/powerbtn /etc/acpi/events/powerbtn

  sudo cp -f "$SCRIPTPATH"/scripts/10-cob-scripts /etc/sudoers.d/

  sudo sed -i "s/myrosdistro/$ROS_DISTRO/g" /usr/sbin/robmuxinator

  echo -e "\n${yellow}Please confirm CLIENT_LIST for UPTIME_MONITOR${NC}\n"
  query_pc_list "$client_list_hostnames"
  host_names_expected=$LIST
  sudo cp -f "$SCRIPTPATH"/scripts/uptime-monitor /usr/sbin/uptime-monitor
  sudo sed -i "s/HOST_NAMES_EXPECTED/$host_names_expected/g" /usr/sbin/uptime-monitor

  # install cob.yaml
  echo -e "\n${green}INFO:UPSTART CONFIGURATION:${NC}"
  echo -e "$upstart_selection"
  echo -e "${yellow}Please select an upstart option: ${NC}"
  read -r choice
  if [[ "$choice" == 0 ]] ; then
    echo -e "${blue}skip updating an upstart configuration${NC}"
  else
    if [[ "$choice" == 1 ]] ; then
      path_to_cob_yaml="$SCRIPTPATH/upstart/cob_bringup.yaml"
    else
      echo -e "${yellow}==> Please provide fully qualified path of your custom upstart configuration file (find them e.g. in X_bringup of your scenario): ${NC}"
      read -r path_to_cob_yaml
    fi
    echo -e "${blue}installing the following upstart configuration: $path_to_cob_yaml ${NC}"
    cat "$path_to_cob_yaml"
    sudo mkdir -p /etc/ros && sudo cp -f "$path_to_cob_yaml" /etc/ros/cob.yaml
    sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml
    sudo sed -i "s/myrosdistro/$ROS_DISTRO/g" /etc/ros/cob.yaml
  fi

  echo -e "${green}=== INSTALL SYSTEM SERVICES DONE! ===${NC}"
}

#### SETUP WORKSPACES
function SetupWorkspaces {
  check_hostname "b1"
  echo -e "${green}=== SETUP WORKSPACES ===${NC}"

  "$SCRIPTPATH"/workspace_tools/setup_workspaces.sh -m robot

  echo -e "${green}=== SETUP WORKSPACES DONE! ===${NC}"
}

#### SYNC PACKAGES
function SyncPackages {
  check_hostname "b1"
  echo -e "${green}=== SYNC PACKAGES ===${NC}"

  "$SCRIPTPATH"/cob-pcs/sync_packages.sh -v

  echo -e "${green}=== SYNC PACKAGES DONE! ===${NC}"
}

########################################################################
############################# INITIAL MENU #############################
########################################################################

if [[ "$1" =~ "--help" ]]; then echo -e "$usage"; exit 0; fi

#### check prerequisites
if [ "$USER" != "robot" ]; then
  echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED AS robot USER${NC}"
  exit 1
fi

if [ "$(lsb_release -sc)" == "xenial" ]; then
  # shellcheck disable=SC1091
  source /opt/ros/kinetic/setup.bash
elif [ "$(lsb_release -sc)" == "focal" ]; then
  # shellcheck disable=SC1091
  source /opt/ros/noetic/setup.bash
else
  echo -e "\n${red}FATAL: Script only supports kinetic and noetic"
  exit 1
fi

if [ -z "$ROS_DISTRO" ]; then
  echo -e "${red}\nNo ROS_DISTRO available, please source ROS first\n${NC}"
  exit 1
fi

kickstart_log_file="/var/log/kickstart.log"
arr=()
for i in $client_list; do
  # shellcheck disable=SC2029
  if ! ssh "$i" "grep -q 'FinalizeKickstartRobot' $kickstart_log_file"; then
    arr+=( "$i" )
    echo -e "${yellow}WARN: 'kickstart-robot.sh' did not finish correctly on $i during stick setup.${NC}"
    # echo -e "${yellow}WARN: Some of the following steps did not executed correctly on $i:${NC}"
    # grep -E '^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)' "$SCRIPTPATH"/images_config/kickstart/kickstart-robot.sh
    echo -e "${yellow}WARN: Please investigate '/var/log/installer/syslog' and '$kickstart_log_file' to see what went wrong.${NC}"
  fi
done
if [ ${#arr[@]} -eq 0 ]; then
  echo -e "${green}'kickstart-robot.sh' was successfull on all PCs${NC}"
else
  echo -e "${red}'kickstart-robot.sh' failed on the following PCs:" "${arr[@]}" "${NC}"
  echo -e "\nDo you still want to continue now anyway (y/n)?"
  read -r answer

  if echo "$answer" | grep -iq "^y" ;then
    :
  else
    exit 1
  fi
fi

if [ ! -d /u/robot/git/setup_cob4 ]; then
  echo -e "${blue} clone ipa320/setup_cob4...${NC}"
  mkdir /u/robot/git
  git clone git@github.com/ipa320/setup_cob4 /u/robot/git/setup_cob4
fi

if [ -z "$ROBOT" ]; then
  echo -e "${yellow}ROBOT not set yet.${NC}"
  echo -e "${yellow}Specify ROBOT to be used for PostInstall (ENTER will set ROBOT=$(get_search_domain))${NC}"
  read -r robot_name
  if [ -z "$robot_name" ]; then
    robot_name=$(get_search_domain)
  fi
else
  robot_name=$ROBOT
fi
echo -e "${blue}ROBOT is set to '$robot_name'${NC}"

echo -e "${green}===========================================${NC}"
echo "                INITIAL MENU"
echo -e "${green}===========================================${NC}"

echo -e "$usage"
echo -e "${yellow}Please select an installation option: ${NC}"
read -r choice

if [[ "$choice" == 1 ]]; then
  SetupRootUser
elif [[ "$choice" == 2 ]]; then
  SetupRobotUser
elif [[ "$choice" == 3 ]]; then
  SetupMimicUser
elif [[ "$choice" == 4 ]]; then
  SetupDevices
elif [[ "$choice" == 5 ]]; then
  InstallSystemServices
elif [[ "$choice" == 6 ]]; then
  SetupWorkspaces
elif [[ "$choice" == 9 ]]; then
  SyncPackages
elif [[ "$choice" == 99 ]]; then
  SetupRootUser
  SetupRobotUser
  SetupMimicUser
  SetupDevices
  InstallSystemServices
  SyncPackages
else
  echo -e "\n${red}INFO: Invalid install option. Exiting. ${NC}\n"
  exit 1
fi

echo -e "\n${green}POSTINSTALL SUCCESSFUL${NC}\n"
