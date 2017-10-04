#!/bin/bash
set -e # force the script to exit if any error occurs

#### COMMON PARAMETERS
usage=$(cat <<"EOF"
INFO: This script is a helper tool for the setup and installation of Care-O-bot: \n
1. Update root ssh keys\n
2. Synchronize robot user\n
3. Setup robot bashrc and Workspace\n
4. Setup mimic user\n
5. Install upstart\n
6. Setup udev rules for sick s300 scanners\n
7. Full installation\n
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


#### DEFINE SPECIFIC LIST OF PCs
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


#### UPDATE ROOT SSH KEYS 
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
    sudo su - root -c "ssh-copy-id -i /root/.ssh/id_rsa.pub root@localhost"
    sudo su - root -c "ssh root@localhost 'exit'"
    sudo cat /root/.ssh/id_rsa.pub | \
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    ssh root@localhost \
    "sudo tee -a /root/.ssh/authorized_keys"
  fi

  for i in $pc_list; do
    sudo su - root -c "ssh-keyscan -H $i >> /root/.ssh/known_hosts"
    sudo su - root -c "ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i"
    sudo su - root -c "ssh root@$i 'exit'" 
    sudo cat /root/.ssh/id_rsa.pub | sudo ssh root@$i "mkdir -p /root/.ssh && cat >>  /root/.ssh/authorized_keys"
  done

}

#### SYNCHRONIZE USERS
function  SynchronizeRobotUser {

  echo -e "\n${green}INFO:Synchronize Robot User${NC}\n"

  /u/robot/git/setup_cob4/cob-adduser robot

  #Entry
  # synchronize passwords
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

#### SETUP ROBOT WORKSPACE
function SetupRobotBashrcWorkspace {

  echo -e "\n${green}INFO:Setup Robot Bashrc Workspace${NC}\n"
  Entry

  if grep -q ROBOT "/u/robot/.bashrc"; then  
    echo ".bashrc already configured"
  else
    cp /u/robot/git/setup_cob4/cob-pcs/user.bashrc /u/robot/.bashrc
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

#### SETUP MIMIC
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

  /u/robot/git/setup_cob4/cob-adduser mimic

  GDM_PATH=/etc/gdm/custom.conf
  sudo ssh $pc_head "sed -i s/'#  AutomaticLoginEnable=True'/'AutomaticLoginEnable=True'/g $GDM_PATH"
  sudo ssh $pc_head "sed -i s/'#  AutomaticLogin=user1'/'AutomaticLogin=mimic'/g $GDM_PATH"

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

  #Brightness and lock
  LOCK_PATH=/etc/default/acpi-support
  sudo ssh $pc_head "sed -i 's/LOCK_SCREEN=true/LOCK_SCREEN=false/g' $LOCK_PATH"

  #inactive
  # FIXME: we need to login manually from msh@b1 to msh@h1 once to setup ssh key access. without that the following line will fail
  sudo su mimic -c "ssh $pc_head 'dbus-launch gsettings set org.gnome.desktop.session idle-delay 0'"

  #Background
  sudo su mimic -c 'cp /u/robot/git/setup_cob4/mimic.jpg /u/mimic/mimic.jpg'
  command_setbackground="dbus-launch gsettings set org.gnome.desktop.background picture-uri file:/u/mimic/mimic.jpg"
  sudo su mimic -c "ssh $pc_head $command_setbackground"
  #sudo su mimic -c 'touch /u/mimic/.config/monitors.xml'
  #sudo su mimic -c 'sed -i "s/\<rotation\>normal/\<rotation\>right/g" /u/mimic/.config/monitors.xml'
  #sudo ssh $pc_head 'sudo wget -O /usr/local/sbin/update-monitor-position https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/update-monitor-position'
  #sudo ssh $pc_head 'sudo chmod +x /usr/local/sbin/update-monitor-position'
  #sudo ssh $pc_head 'sudo wget -O /usr/share/applications/update-monitor-position.desktop https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/update-monitor-position.desktop'
  #sudo ssh $pc_head 'sudo chmod +x /usr/share/applications/update-monitor-position.desktop'
  #sudo su mimic -c 'sudo wget -O /u/mimic/.config/autostart/update-monitor-position.desktop https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/update-monitor-position.desktop'
}

#### INSTALL UPSTART
function  InstallUpstart {
  path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/cob.yaml"
  pc_list="myrobot-b1 myrobot-t1 myrobot-t2 myrobot-t3 myrobot-s1 myrobot-h1"
  checkPc_list=""

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
  cat $path_to_cob_yaml
  echo -e "\nDo you want to install the default configuration from $path_to_cob_yaml (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    echo "installing default upstart configuration"
  else
    echo -e "${green}==>${NC} Please specify the path of the scenario configuration file (e.g. /u/robot/git/setup_cob4/upstart/cob.yaml): "
    read path_to_cob_yaml
    echo "installing the following upstart configuration from $path_to_cob_yaml"
    cat $path_to_cob_yaml
  fi
  sudo cp -f $path_to_cob_yaml /etc/ros/cob.yaml
  sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml

  # get pc_list
  echo -e "\n${green}INFO:PC LIST FOR UPSTART:${NC}"
  echo -e "${green}pc list:${NC} $pc_list"
  echo -e "\nDo you want to install upstart with the default pc configuration (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    echo "installing upstart for default pc configuration"
  else
    echo -e "\n${green}==>${NC} Please specify the list of pcs (e.g. 'cob4-2-b1 cob4-2-t1 cob4-2-t2 cob4-2-t3 cob4-2-s1 cob4-2-h1'): "
    read pc_list
  fi
  sudo sed -i "s/pc_list/$pc_list/g" /usr/sbin/cob-start
  
  # get checkPc_list
  echo -e "\n${green}INFO:CHECK PC LIST:${NC}"
  echo -e "${green}check pc list:${NC} $checkPc_list"
  echo -e "\nDo you want to install the default check pc configuration (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    echo "installing default check pc configuration"
  else
    echo -e "\n${green}==>${NC} Please specify the list of pcs with a check condition of your robot (e.g. 'cob4-2-t1 cob4-2-t3 cob4-2-s1'): "
    read checkPc_list
  fi  
  
  # install check scripts on pc
  for client in $checkPc_list; do
    echo "-------------------------------------------"
    echo "Executing on $client"
    echo "-------------------------------------------"
    echo ""
    ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
    ssh $client "sudo update-rc.d check_cameras.sh defaults"
  done
  sudo sed -i "s/checkPc_list/$checkPc_list/g" /usr/sbin/cob-start
  sudo sed -i "s/myrobot/$robot_name/g" /usr/sbin/cob-start
}

#### SETUP SCANNERS
function  ScanSetup {

  echo -e "\n${green}INFO: Setup udev rules for the scanners ${NC}\n"

  results=()
  count=0

  for file in /tmp/usb*; do
    result=$(ls -l |grep -R 'ATTRS{serial}=="F' $file)
    results[$count]=$result
    count=$((count+1))
  done

  if [[ ${results[0]} == ${results[1]} ]]
    then
      ATTRSSerialFL=${results[0]}
      ATTRSSerialR=${results[2]}
  elif [[ ${results[1]} == ${results[2]} ]]
    then
      ATTRSSerialFL=${results[1]}
      ATTRSSerialR=${results[0]}
  elif [[ ${results[0]} == ${results[2]} ]]
    then
      ATTRSSerialFL=${results[0]}
      ATTRSSerialR=${results[1]}
  fi

  ATTRSSerialFL="$( echo "$ATTRSSerialFL" | sed 's/ //g' )"	
  ATTRSSerialR="$( echo "$ATTRSSerialR" | sed 's/ //g' )"	

  sudo sed -i -re "s/(ScanFrontAttr2=).*/\1'${ATTRSSerialFL}'/g" /etc/init.d/udev_cob.sh	
  sudo sed -i -re "s/(ScanLeftAttr2=).*/\1'${ATTRSSerialFL}'/g" /etc/init.d/udev_cob.sh
  sudo sed -i -re "s/(ScanRightAttr2=).*/\1'${ATTRSSerialR}'/g" /etc/init.d/udev_cob.sh

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

if [[ "$choice" == 1 ]]
  then
    UpdateRootSSH
fi
if [[ "$choice" == 2 ]]
  then
    SynchronizeRobotUser
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
    ScanSetup
fi
if [[ "$choice" == 7 ]]
  then
    UpdateRootSSH
    SynchronizeRobotUser
    SetupRobotBashrcWorkspace
    SetupMimicUser
    InstallUpstart
    ScanSetup
fi


