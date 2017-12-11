#!/bin/bash
set -e # force the script to exit if any error occurs
#set -o xtrace # print all commands before executing


#### COMMON PARAMETERS
usage=$(cat <<"EOF"
INFO: This script is a helper tool for the setup and installation of Care-O-bot: \n
1. Setup root user\n
2. Setup robot user\n
3. Setup mimic user\n
4. Setup devices (e.g. udev for laser scanners)\n
5. Install upstart\n
99. Full installation\n
EOF
)

upstart_selection=$(cat << "EOF"
INFO: The following upstart variants are available: \n
1. cob_bringup\n
2. unity_bringup\n
3. msh_cob_robots\n
4. msh_unity_robots\n
5. custom upstart\n
EOF
)

green='\e[0;32m'
red='\e[0;31m'
NC='\e[0m' # No Color

if [ "$USER" != "robot" ]; then
  echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED AS robot USER${NC}"
  exit
fi

if [[ ${HOSTNAME} != *"b1"* ]];then
  echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED ON BASE PC${NC}"
  exit
fi

#### retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh

#### DEFINE SPECIFIC LIST OF PCs
function query_pc_list {
  echo -e "\n${green}INFO:QUERY_PC_LIST${NC}\n"
  echo -e "${green} PC_LIST:${NC} $1"
  echo -e "\nDo you want to use the suggested pc list (y/n)?"
  read answer

  if echo "$answer" | grep -iq "^y" ;then
    LIST=$1
  else
    echo -e "\n${green}==>${NC} Please specify your custom pc list (using the hostnames):"
    echo -e "\nEnter your list of pcs of your robot:"
    read LIST
  fi
}

#### Setup root user
function SetupRootUser {
  echo -e "\n${green}INFO:setup root user${NC}\n"

  query_pc_list "$client_list_hostnames"
  pc_list=$LIST

  #generate a ssh key for root user per pc
  if sudo grep -q SSH_ASKPASS "/root/.bashrc"; then
    echo -e "\n${green}INFO: Found SSH_ASKPASS${NC}\n"
  else
    sudo sh -c "echo 'unset SSH_ASKPASS' >> /root/.bashrc"
  fi

  if sudo test -f "/root/.ssh/id_rsa.pub"; then
    echo -e "\n${green}INFO:ssh key exists for root${NC}\n"
  else
    echo "create new ssh key"
    sudo su - root -c "ssh-keygen -f /root/.ssh/id_rsa -N ''"
    sudo su - root -c "ssh-keyscan -H localhost >> /root/.ssh/known_hosts"
    sudo -u root -i ssh-copy-id -i /root/.ssh/id_rsa.pub root@localhost
    sudo -u root -i ssh root@localhost 'exit'
    sudo cat /root/.ssh/id_rsa.pub | \
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    ssh root@localhost \
    "sudo tee -a /root/.ssh/authorized_keys"
  fi

  for i in $pc_list; do
    sudo su - root -c "ssh-keyscan -H $i >> /root/.ssh/known_hosts"
    sudo -u root -i ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i
    sudo -u root -i ssh root@$i 'exit'
    sudo cat /root/.ssh/id_rsa.pub | sudo ssh root@$i "mkdir -p /root/.ssh && cat >>  /root/.ssh/authorized_keys"
  done
  echo "setup root user done"
}

#### Setup Robot user
function SetupRobotUser {
  echo -e "\n${green}INFO:Setup Robot User${NC}\n"

  query_pc_list "$client_list_hostnames"
  pc_list=$LIST

  /u/robot/git/setup_cob4/cob-adduser robot

  source /opt/ros/indigo/setup.bash #FIXME only working for indigo!!!

  if grep -q ROBOT "/u/robot/.bashrc"; then
    echo ".bashrc already configured"
  else
    /u/robot/git/setup_cob4/cob-adduser robot
  fi

  if [ -d /u/robot/git/care-o-bot/src ]; then
    echo "INFO: robot workspace already exits"
  else
    mkdir -p /u/robot/git/care-o-bot/src
    source /u/robot/.bashrc
    cd /u/robot/git/care-o-bot/ && catkin init
    cd /u/robot/git/care-o-bot/ && catkin config -DCMAKE_BUILD_TYPE=Release
    cd /u/robot/git/care-o-bot/ && catkin build
  fi

  for i in $pc_list; do
    sudo -u root -i ssh-copy-id robot@$i
    sudo -u root -i ssh robot@$i 'exit'
  done
  echo "setup robot user done"
}

#### SETUP MIMIC
function SetupMimicUser {
  echo -e "\n${green}INFO:Setup Mimic User${NC}\n"

  query_pc_list "$robot_name-h1"
  pc_head=$LIST

  /u/robot/git/setup_cob4/cob-adduser mimic

  GDM_PATH=/etc/gdm/custom.conf
  sudo ssh $pc_head "sed -i s/'#  TimedLoginEnable = true'/'TimedLoginEnable = true'/g $GDM_PATH"
  sudo ssh $pc_head "sed -i s/'#  TimedLogin = user1'/'TimedLogin = mimic'/g $GDM_PATH"
  sudo ssh $pc_head "sed -i s/'#  TimedLoginDelay = 10'/'TimedLoginDelay = 10'/g $GDM_PATH"

  DESKTOP_PATH=/u/mimic/.config/autostart
  if sudo test -d $DESKTOP_PATH; then
    echo "Folder $DESKTOP_PATH exists"
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

  sudo su mimic -c "cat <<EOF > $DESKTOP_PATH/update-monitor-position.desktop
[Desktop Entry]
Type=Application
Exec=update-monitor-position 5
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Update Monitor Positon
Name=Update Monitor Positon
Comment=Force monitors position 5 seconds after login
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
  LOCK_PATH=/etc/default/acpi-support
  sudo ssh $pc_head "sed -i 's/LOCK_SCREEN=true/LOCK_SCREEN=false/g' $LOCK_PATH"

  sudo -u mimic -i ssh $pc_head 'dbus-launch gsettings set org.gnome.desktop.session idle-delay 0'

  #Background
  sudo su mimic -c 'cp /u/robot/git/setup_cob4/mimic.jpg /u/mimic/mimic.jpg'
  command_setbackground="dbus-launch gsettings set org.gnome.desktop.background picture-uri file:/u/mimic/mimic.jpg"
  sudo su mimic -c "ssh $pc_head $command_setbackground"

  echo "setup mimic user done"
}

#### INSTALL UPSTART
function InstallUpstart {
  echo -e "\n${green}INFO: Install Upstart${NC}\n"

  sudo apt-get install nmap

  sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob-stop /usr/sbin/cob-stop
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers

  # install cob.yaml
  echo -e "\n${green}INFO:UPSTART CONFIGURATION:${NC}"
  echo -e $upstart_selection
  read -p "Please select an upstart option: " choice
  if [[ "$choice" == 1 ]] ; then
    path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/cob_bringup.yaml"
  elif [[ "$choice" == 2 ]] ; then
    path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/unity_bringup.yaml"
  elif [[ "$choice" == 3 ]] ; then
    path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/msh_cob_robots.yaml"
  elif [[ "$choice" == 4 ]] ; then
    path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/msh_unity_robots.yaml"
  else
    echo -e "${green}==>${NC} Please specify the path of your custom upstart configuration file (fully quantified filename): "
    read path_to_cob_yaml
  fi
  echo "installing the following upstart configuration: $path_to_cob_yaml"
  cat $path_to_cob_yaml
  sudo cp -f $path_to_cob_yaml /etc/ros/cob.yaml
  sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml

  # get client_list
  echo -e "\n${green}INFO:CLIENT LIST:${NC}"
  query_pc_list "$client_list_hostnames"
  client_list=$LIST
  sudo sed -i "s/CLIENT_LIST/$client_list/g" /usr/sbin/cob-start

  # get check_client_list
  echo -e "\n${green}INFO:CHECK CLIENT LIST:${NC}"
  query_pc_list ""
  check_client_list=$LIST

  # install check scripts on pc
  for client in $check_client_list; do
    echo "-------------------------------------------"
    echo "Executing on $client"
    echo "-------------------------------------------"
    echo ""
    ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
    ssh $client "sudo update-rc.d check_cameras.sh defaults"
  done
  sudo sed -i "s/myrobot/$robot_name/g" /usr/sbin/cob-start
  sudo sed -i "s/CHECK_LIST/$check_client_list/g" /usr/sbin/cob-start

  echo "install upstart done"
}

#### SETUP SCANNERS
function SetupDevices {
  echo -e "\n${green}INFO: Setup udev rules for the scanners ${NC}\n"

  results=()
  count=0

  for file in /tmp/usb*; do
    if grep --quiet 'ATTRS{serial}=="F' $file; then
      result=$(ls -l |grep -R 'ATTRS{serial}=="F' $file)
      echo "found scanner with $result"
      results[$count]=$result
      count=$((count+1))
    fi
  done

  echo "found $count scanners: $results"

  if [[ ${results[0]} == ${results[1]} ]]; then
    ATTRSSerialFL=${results[0]}
    ATTRSSerialR=${results[2]}
  elif [[ ${results[1]} == ${results[2]} ]]; then
    ATTRSSerialFL=${results[1]}
    ATTRSSerialR=${results[0]}
  elif [[ ${results[0]} == ${results[2]} ]]; then
    ATTRSSerialFL=${results[0]}
    ATTRSSerialR=${results[1]}
  fi

  ATTRSSerialFL="$( echo "$ATTRSSerialFL" | sed 's/ //g' )"
  ATTRSSerialR="$( echo "$ATTRSSerialR" | sed 's/ //g' )"

  sudo sed -i -re "s/(ScanFrontAttr2=).*/\1'${ATTRSSerialFL}'/g" /etc/init.d/udev_cob.sh
  sudo sed -i -re "s/(ScanLeftAttr2=).*/\1'${ATTRSSerialFL}'/g" /etc/init.d/udev_cob.sh
  sudo sed -i -re "s/(ScanRightAttr2=).*/\1'${ATTRSSerialR}'/g" /etc/init.d/udev_cob.sh

  echo "setup devices done"
}

########################################################################
############################# INITIAL MENU #############################
########################################################################

if [[ "$1" =~ "--help" ]]; then echo -e $usage; exit 0; fi

echo -e "${green}===========================================${NC}"
echo "                INITIAL MENU"
echo -e "${green}===========================================${NC}"

echo -e $usage
read -p "Please select an installation option: " choice

robot_name="${HOSTNAME//-b1}"

if [ ! -d /u/robot/git/setup_cob4 ]; then
  mkdir /u/robot/git
  git clone https://github.com/ipa320/setup_cob4 /u/robot/git/setup_cob4
else
  git --work-tree=/u/robot/git/setup_cob4 --git-dir=/u/robot/git/setup_cob4/.git pull origin master
fi

if [[ "$choice" == 1 ]]; then
  SetupRootUser
elif [[ "$choice" == 2 ]]; then
  SetupRobotUser
elif [[ "$choice" == 3 ]]; then
  SetupMimicUser
elif [[ "$choice" == 4 ]]; then
  SetupDevices
elif [[ "$choice" == 5 ]]; then
  InstallUpstart
elif [[ "$choice" == 99 ]]; then
  SetupRootUser
  SetupRobotUser
  SetupMimicUser
  SetupDevices
  InstallUpstart
else
  echo -e "\n${red}INFO: Invalid install option. Exiting. ${NC}\n"
fi
