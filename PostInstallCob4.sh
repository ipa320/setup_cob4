#!/bin/bash
#### COMMON PARAMETERS
usage=$(cat <<"EOF"
INFO: This script is a helper tool for the setup and installation of Care-O-bot: \n
  1.  Create root ssh keys \n
  2.  Synchronizes the passwords and robot user \n
  3.  Setup the robot bashrc and workspace \n
  4.  Add and setup the mimic user configuration \n
  5.  Install Upstart software \n
  6.  Update Upstart software \n
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


#### FUNCTION TO DEFINE SPECIFIC LIST OF PCs
function Entry {

  echo -e "\n${green}INFO:POST-INSTALLATION${NC}\n" 
  echo -e "${green} Default pc list:${NC}  $robot_name-b1  $robot_name-t1  $robot_name-t2  $robot_name-t3  $robot_name-s1  $robot_name-h1"
  echo -e "\nDo you want to install the default configuration (y/n)?"
  read answer

  if echo "$answer" | grep -iq "^y" ;then
    pc_list="$robot_name-b1 $robot_name-t1 $robot_name-t2 $robot_name-t3 $robot_name-s1 $robot_name-h1"
  else
    echo -e "\n${green}==>${NC} Please specify the list of pcs of your robot (e.g. 'cob4-2-b1 cob4-2-t1 cob4-2-t2 cob4-2-t3 cob4-2-s1 cob4-2-h1'):"
  echo -e "\nEnter your list of pcs of your robot::"
    read pc_list  
  fi

}


#### FUNCTION TO UPDATE ROOT SSH KEYS 
function UpdateRootSSH {

  echo -e "\n${green}INFO:Update root ssh keys${NC}\n"

  Entry
  #generate a ssh key for root user per pc
  if sudo grep -q SSH_ASKPASS "/root/.bashrc"; then
    echo -e "\n${green}INFO: Found SSH_ASKPASS${NC}\n"
  else
    sudo sh -c "echo 'unset SSH_ASKPASS' >> /root/.bashrc"
  fi

  if sudo test -d "/root/.ssh";then
    echo -e "\n${green}INFO:.ssh directory exist in /root${NC}\n"
  else
    echo "create new ssh key"
    sudo su - root -c "ssh-keygen -f /root/.ssh/id_rsa -N ''"
    sudo su - root -c "ssh-keyscan -H localhost >> /root/.ssh/known_hosts"
    sudo su - root -c "ssh-copy-id root@localhost"
    sudo su - root -c "ssh root@localhost 'exit'"
    sudo cat /root/.ssh/id_rsa.pub | \
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    ssh root@localhost \
    "sudo tee -a /root/.ssh/authorized_keys"
  fi

  for i in $pc_list; do
    sudo su - root -c "ssh-keyscan -H $i >> /root/.ssh/known_hosts"
    sudo su - root -c "ssh-copy-id root@$i"
    sudo su - root -c "ssh root@$i 'exit'" 
    sudo cat /root/.ssh/id_rsa.pub | sudo ssh root@$i "mkdir -p /root/.ssh && cat >>  /root/.ssh/authorized_keys"
  done

}

#### FUNCTION Syncronize Robot User
function  SyncronizeRobotUser {

  echo -e "\n${green}INFO:Syncronize Robot User${NC}\n"

  mkdir /u/robot/git
  git clone https://github.com/ipa320/setup_cob4 /u/robot/git/setup_cob4
  cob-adduser robot

  #Entry
  # syncronize passwords
  #for i in $pc_list; do
  #  sudo su root -c -l "rsync -avz -e ssh /etc/passwd /etc/shadow /etc/group root@$i:/etc/"
  #done


  #generate a ssh key for robot user per pc
  #if sudo grep -q SSH_ASKPASS "/u/robot/.bashrc"; then
  #  echo -e "\n${green}INFO: Found SSH_ASKPASS${NC}\n"
  #else
  #  sudo sh -c "echo 'unset SSH_ASKPASS' >> /u/robot/.bashrc"
  #fi
  #if sudo test -d "/u/robot/.ssh";then
  #  echo -e "\n${green}INFO:.ssh directory exist in /u/robot${NC}\n"
  #else
  #  echo "create new ssh key"
  #  ssh-keygen
  #  ssh-copy-id -o PubkeyAuthentication=no robot@localhost
  #  ssh -o PubkeyAuthentication=no robot@$i 'exit'
  #fi


  #for i in $pc_list; do
  #  if [[ -s /u/robot/.ssh/known_hosts ]]; then 
  #    echo "known_hosts file is full" 
  #  else 
  #    eval "$(ssh-agent -s)"
  #    ssh-add
  #    ssh-copy-id -o PubkeyAuthentication=no robot@$i
  #    sudo ssh -o PubkeyAuthentication=no robot@$i 'exit'
  #  fi
  #done

}

#### FUNCTION Setup Robot Bashrc Workspace
function SetupRobotBashrcWorkspace {

  echo -e "\n${green}INFO:Setup Robot Bashrc Workspace${NC}\n"
  Entry

    if grep -q ROBOT "/u/robot/.bashrc"; then  
      echo ".bashrc already configured"
    else
      wget -O /u/robot/.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/user.bashrc 
      sed -i -e "s/myrobot/${robot_name}/g" ~/.bashrc
      sed -i -e "s/mydistro/indigo/g" ~/.bashrc #only working for indigo!!!
    fi

    if [ -d /u/robot/git/care-o-bot/src ]; then 
      echo "INFO: robot workspace already exits"
    else
      mkdir -p /u/robot/git/care-o-bot/src
      source /u/robot/.bashrc
      if [ ! -d /etc/ros/rosdep/sources.list.d ]; then
        sudo rosdep init
      fi
      rosdep update
      cd /u/robot/git/care-o-bot/ && catkin init
      cd /u/robot/git/care-o-bot/ && catkin config -DCMAKE_BUILD_TYPE=Release
      cd /u/robot/git/care-o-bot/ && catkin build
    fi

}

####Miminc##############
function SetupMimicUser {

  echo -e "\n${green}INFO:Setup Mimic User${NC}\n"

  echo -e "${green} default pc head:${NC} $robot_name-h1"
  echo -e "\nDo you want to install the default configuration in the pc head (y/n)?"
  read answer

  if echo "$answer" | grep -iq "^y" ;then
    pc_head="$robot_name-h1"
  else
    echo -e "\n${green}==>${NC} Please specify the head pc of your robot (e.g. 'cob4-2-h1'):"
  echo -e "\nEnter your head pc of your robot::"
    read pc_head  
  fi

  cob-adduser mimic
  GDM_PATH=/etc/gdm/custom.conf
  sudo ssh $pc_head "sed -i \"s/#  AutomaticLoginEnable=True'/AutomaticLoginEnable=True'/g\" $GDM_PATH"
  sudo ssh $pc_head "sed -i \"s/#  AutomaticLogin=user1'/AutomaticLogin=mimic'/g\" $GDM_PATH"

  DESKTOP_PATH=/u/mimic/.config/autostart/xhost.desktop
  if sudo ssh $pc_head stat $DESKTOP_PATH \> /dev/null 2\>\&1; then
    echo "File $DESKTOP_PATH exists"
  else
    sudo su mimic -c "mkdir -p /u/mimic/.config/autostart/"
    sudo su mimic -c "cat <<EOF > $DESKTOP_PATH
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

  fi
  #Brightness and lock
  LOCK_PATH=/etc/default/acpi-support
  echo $pc_head
  echo $LOCK_PATH
  sudo ssh $pc_head 'sed -i "s/LOCK_SCREEN=true/LOCK_SCREEN=false/g" $LOCK_PATH'

  #inactive
  sudo su mimic -c 'ssh $pc_head "dbus-launch gsettings set org.gnome.desktop.session idle-delay 0"'

  #Background
  sudo su mimic -c 'wget -O /u/mimic/mimic.jpg https://raw.githubusercontent.com/ipa320/setup_cob4/master/mimic.jpg'
  command_setbackground="dbus-launch gsettings set org.gnome.desktop.background picture-uri 'file:/u/mimic/mimic.jpg'"
  sudo su mimic -c 'ssh $pc_head $command_setbackground'

  #rotate clockwise
  sudo su mimic -c 'ssh $pc_head "xrandr -o right"'

}

######## Install Upstart############
function  InstallUpstart {

  echo -e "\n${green}INFO: Install Upstart${NC}\n"

  echo -e "\n${green}INFO:UPSTART DEFAULT CONFIGURATION:${NC}"
  echo -e "${green}check pc list:${NC} $ROBOT-t1 $ROBOT-t3 $ROBOT-s1"
  echo -e "\nDo you want to install the default configuration (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    checkPc_list="myrobot-t1 myrobot-t3 myrobot-s1"
  else
    echo -e "\n${green}==>${NC} Please specify the list of pcs with a check condition of your robot (e.g. 'cob4-2-t1 cob4-2-t3 cob4-2-s1'): "
    read checkPc_list
  fi

  set -e

  sudo apt-get install ros-indigo-robot-upstart
  sudo apt-get install tmux
  sudo apt-get install nmap

  sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
  sudo sed -i "s/myrobot/$robot_name/g" /usr/sbin/cob-start
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob-stop /usr/sbin/cob-stop
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob.yaml /etc/ros/cob.yaml
  sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers 
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop" -e "}" /etc/sudoers 
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers 

  for client in $checkPc_list; do
    echo "-------------------------------------------"
    echo "Executing on $client"
    echo "-------------------------------------------"
    echo ""
    ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
    ssh $client "sudo update-rc.d check_cameras.sh defaults"
  done

  UpdateUpstart

}

######## Update Upstart############
function  UpdateUpstart {

  echo -e "\n${green}INFO: Update Upstart${NC}\n"

  echo -e "\n${green}INFO:UPSTART DEFAULT CONFIGURATION:${NC}"
  echo -e "${green}Command:${NC} roslaunch cob_bringup robot.launch"
  echo -e "${green}pc list:${NC} $ROBOT-b1 $ROBOT-t1 $ROBOT-t2 $ROBOT-t3 $ROBOT-s1 $ROBOT-h1"
  echo -e "${green}check pc list:${NC} $ROBOT-t1 $ROBOT-t3 $ROBOT-s1"
  echo -e "\nDo you want to install the default configuration (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    sudo cp -f /u/robot/git/setup_cob4/upstart/cob.yaml /etc/ros/cob.yaml
    pc_list="myrobot-b1 myrobot-t1 myrobot-t2 myrobot-t3 myrobot-s1 myrobot-h1"
    checkPc_list="myrobot-t1 myrobot-t3 myrobot-s1"
  else
    echo -e "${green}==>${NC} Please specify the path of the scenario configuration file (e.g. /u/robot/git/setup_cob4/upstart/cob.yaml): "
    read answer
    sudo cp -f $answer /etc/ros/cob.yaml
    echo -e "\n${green}==>${NC} Please specify the list of pcs of your robot (e.g. 'cob4-2-b1 cob4-2-t1 cob4-2-t2 cob4-2-t3 cob4-2-s1 cob4-2-h1'): "
    read pc_list
    echo -e "\n${green}==>${NC} Please specify the list of pcs with a check condition of your robot (e.g. 'cob4-2-t1 cob4-2-t3 cob4-2-s1'): "
    read checkPc_list
  fi

  sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml
  sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
  sudo sed -i "s/pc_list/$pc_list/g" /usr/sbin/cob-start
  sudo sed -i "s/checkPc_list/$checkPc_list/g" /usr/sbin/cob-start
  sudo sed -i "s/myrobot/$robot_name/g" /usr/sbin/cob-start

}
########################################################################
############################# INITIAL MENU #############################
########################################################################


if [[ "$1" =~ "--help" ]]; then echo -e $usage; exit 0; fi

echo -e "${green}===========================================${NC}"
echo "                INITIAL MENU"
echo -e "${green}===========================================${NC}"

read -p "Please select an installation option 
1. Update root ssh keys
2. Syncronize robot user
3. Setup robot bashrc and Workspace
4. Setup mimic user
5. Install upstart
6. Update upstart
7. Full installation
" choice 

robot_name="${HOSTNAME//-b1}"

if [[ "$choice" == 1 ]]
  then
    UpdateRootSSH
fi
if [[ "$choice" == 2 ]]
  then
    SyncronizeRobotUser
fi
if [[ "$choice" == 3 ]]
  then
    SetupRobotBashrcWorkspace
fi
if [[ "$choice" == 4 ]]
  then
    SetupMimicUser
fi
if [[ "$choice" == 5 ]]
  then
    InstallUpstart
fi
if [[ "$choice" == 6 ]]
  then
    UpdateUpstart
fi
if [[ "$choice" == 7 ]]
  then
    UpdateRootSSH
    SyncronizeRobotUser
    SetupRobotBashrcWorkspace
    SetupMimicUser
    InstallUpstart
fi


