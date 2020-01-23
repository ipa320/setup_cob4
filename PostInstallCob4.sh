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
5. Install system services (upstart,...)\n
50. Setup capabilities: cepstral voices\n
99. Full installation\n
EOF
)

upstart_selection=$(cat << "EOF"
INFO: The following upstart variants are available: \n
0. skip (do not update upstart configuration)\n
1. cob_bringup\n
2. custom upstart\n
EOF
)

yellow='\e[0;33m'
green='\e[0;32m'
red='\e[0;31m'
NC='\e[0m' # No Color

#### retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh

#### check hostname
function check_hostname () {
  if [[ ${HOSTNAME} != *"$1"* ]];then
    echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED ON PC $1${NC}"
    exit
  fi
}

function get_search_domain () {
  grep search /etc/resolv.conf | sed -e "s/search //"
}

#### DEFINE SPECIFIC LIST OF PCs
function query_pc_list {
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

#### SETUP ROOT USER
function SetupRootUser {
  check_hostname "b1"
  echo -e "\n${green}INFO:setup root user${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupRootUser${NC}\n"
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

#### SETUP ROBOT USER
function SetupRobotUser {
  check_hostname "b1"
  echo -e "\n${green}INFO:Setup Robot User${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupRobotUser${NC}\n"
  query_pc_list "$client_list_hostnames"
  pc_list=$LIST

  /u/robot/git/setup_cob4/cob-adduser robot

  source /opt/ros/$ros_distro/setup.bash

  if grep "source /u/robot/setup/user.bashrc" /u/robot/.bashrc > /dev/null; then
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

#### SETUP MIMIC USER
function SetupMimicUser {
  check_hostname "b1"
  echo -e "\n${green}INFO:Setup Mimic User${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for SetupMimicUser${NC}\n"
  query_pc_list "h1"
  pc_head=$LIST
  if [ -z "$pc_head" ]; then
    echo "no head pc, skipping setup mimic user"
    return
  fi

  /u/robot/git/setup_cob4/cob-adduser mimic

  if [ $(lsb_release -sc) == "trusty" ]; then
    GDM_PATH=/etc/gdm/custom.conf
  elif [ $(lsb_release -sc) == "xenial" ]; then
    GDM_PATH=/etc/gdm3/custom.conf
  fi
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

  # rotation and display position seems to work on xenial. Not need for this trick
  if [ $(lsb_release -sc) == "trusty" ]; then
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

  fi

  #Brightness and lock
  if [ $(lsb_release -sc) == "trusty" ]; then
    LOCK_PATH=/etc/default/acpi-support
    sudo ssh $pc_head "sed -i 's/LOCK_SCREEN=true/LOCK_SCREEN=false/g' $LOCK_PATH"
  elif [ $(lsb_release -sc) == "xenial" ]; then
    sudo -u mimic -i ssh $pc_head 'dbus-launch gsettings set org.gnome.desktop.screensaver lock-enabled false'
  fi

  sudo -u mimic -i ssh $pc_head 'dbus-launch gsettings set org.gnome.desktop.session idle-delay 0'

  #Background
  sudo su mimic -c 'cp -f /u/robot/git/setup_cob4/mimic.jpg /u/mimic/mimic.jpg'
  command_setbackground="dbus-launch gsettings set org.gnome.desktop.background picture-uri file:/u/mimic/mimic.jpg"
  sudo su mimic -c "ssh $pc_head $command_setbackground"

  echo "setup mimic user done"
}

#### SETUP DEVICES
function SetupDevices {
  check_hostname "b1"
  echo -e "\n${green}INFO: Setup udev rules for the scanners ${NC}\n"

  ## ScanFront ##
  ScanFrontAttr1='ATTRS{bInterfaceNumber}=="00"'

  ## ScanLeft ##
  ScanLeftAttr1='ATTRS{bInterfaceNumber}=="01"'

  ## ScanRight ##
  ScanRightAttr1='ATTRS{bInterfaceNumber}=="00"'

  for file in /dev/ttyUSB*; do
    sudo chmod 666 $file
    sudo rm -f /tmp/usb${file: -1}
    sudo udevadm info -a -p $(udevadm info -q path -n $file) > /tmp/usb${file: -1}
    sudo chmod 666 /tmp/usb${file: -1}
  done

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

#### INSTALL SYSTEM SERVICES
function InstallSystemServices {
  check_hostname "b1"
  echo -e "\n${green}INFO: Install System Services (upstart,...)${NC}\n"

  echo -e "\n${yellow}Please confirm CLIENT_LIST for InstallSystemServices${NC}\n"
  query_pc_list "$client_list_hostnames"
  client_list=$LIST

  if [ $(lsb_release -sc) == "trusty" ]; then
    sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
  elif  [ $(lsb_release -sc) == "xenial" ]; then
    echo "Installing cob service"
    sudo cp -f /u/robot/git/setup_cob4/upstart/cob.service /etc/systemd/system/cob.service
    sudo systemctl enable cob.service

    for i in $client_list; do
      echo "Installing tmux service on $i"
      sudo -u root -i ssh robot@$i 'sudo cp -f /u/robot/git/setup_cob4/upstart/tmux.service /etc/systemd/system/tmux.service'
      sudo -u root -i ssh robot@$i 'sudo systemctl enable tmux.service'

      echo "Installing chrony-wait service on $i"
      sudo -u root -i ssh robot@$i 'sudo cp -f /u/robot/git/setup_cob4/upstart/chrony-wait.service /etc/systemd/system/chrony-wait.service'
      sudo -u root -i ssh robot@$i 'sudo systemctl enable chrony-wait.service'

      # disable systemd suspension handling
      sudo -u root -i ssh robot@$i "sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target"
      sudo -u root -i ssh robot@$i "dbus-launch gsettings set org.gnome.settings-daemon.plugins.power button-power 'shutdown'"
    done
  fi

  # install cob scripts
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-start /usr/sbin/cob-start
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-stop /usr/sbin/cob-stop
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-shutdown /usr/sbin/cob-shutdown
  sudo cp -f /u/robot/git/setup_cob4/scripts/cob-powerbutton /usr/sbin/cob-powerbutton
  sudo sed -i "s/myrosdistro/$ros_distro/g" /usr/sbin/cob-command
  sudo sed -i '/action/c\action=/usr/sbin/cob-powerbutton' /etc/acpi/events/powerbtn

  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-shutdown"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-shutdown|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-shutdown||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-shutdown" -e "}" /etc/sudoers
  sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-powerbutton"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-powerbutton|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-powerbutton||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-powerbutton" -e "}" /etc/sudoers

  sudo sed -i "s/CLIENT_LIST/$client_list/g" /usr/sbin/cob-start

  # install cob.yaml
  echo -e "\n${green}INFO:UPSTART CONFIGURATION:${NC}"
  echo -e $upstart_selection
  read -p "Please select an upstart option: " choice
  if [[ "$choice" == 0 ]] ; then
    echo "skip updating an upstart configuration"
  else
    if [[ "$choice" == 1 ]] ; then
      path_to_cob_yaml="/u/robot/git/setup_cob4/upstart/cob_bringup.yaml"
    else
      echo -e "${green}==>${NC} Please provide fully qualified path of your custom upstart configuration file (find them e.g. in X_bringup of your scenario): "
      read path_to_cob_yaml
    fi
    echo "installing the following upstart configuration: $path_to_cob_yaml"
    cat $path_to_cob_yaml
    sudo cp -f $path_to_cob_yaml /etc/ros/cob.yaml
    sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml
    sudo sed -i "s/myrosdistro/$ros_distro/g" /etc/ros/cob.yaml
  fi

  # setup camera checks - outdated
  check_client_list=""
  sudo sed -i "s/CHECK_LIST/$check_client_list/g" /usr/sbin/cob-start
  ## get check_client_list
  #echo -e "\n${yellow}Please confirm CLIENT_LIST for CAMERA_CHECKS${NC}\n"
  #query_pc_list ""
  #check_client_list=$LIST

  #if [ $(lsb_release -sc) == "trusty" ]; then
    ## install check scripts on pc
    #for client in $check_client_list; do
      #echo "-------------------------------------------"
      #echo "Executing on $client"
      #echo "-------------------------------------------"
      #echo ""
      #ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
      #ssh $client "sudo update-rc.d check_cameras.sh defaults"
    #done
  #fi
  #sudo sed -i "s/CHECK_LIST/$check_client_list/g" /usr/sbin/cob-start

  echo "install system services done"
}

#### SETUP_CAPABILITIES
function SetupCapabilitiesCepstralVoices {
  check_hostname "h1"
  echo -e "\n${green}INFO: Setup Capabilities: CEPSTRAL VOICES${NC}\n"

  #download voices
  DIR_PREFIX="/u/robot/voices/cepstral/"
  CEPSTRAL_DAVID="Cepstral_David_x86-64-linux_6.2.3.873"
  CEPSTRAL_DIANE="Cepstral_Diane_x86-64-linux_6.2.3.873"
  CEPSTRAL_MATTHIAS="Cepstral_Matthias_x86-64-linux_6.2.3.873"
  CEPSTRAL_KATRIN="Cepstral_Katrin_x86-64-linux_6.2.3.873"
  if [ ! -e "$DIR_PREFIX$CEPSTRAL_DAVID.tar.gz" ]; then
    bash -c "wget http://www.cepstral.com/downloads/installers/linux64/$CEPSTRAL_DAVID.tar.gz -P $DIR_PREFIX"
  fi
  if [ ! -e "$DIR_PREFIX$CEPSTRAL_DIANE.tar.gz" ]; then
    bash -c "wget http://www.cepstral.com/downloads/installers/linux64/$CEPSTRAL_DIANE.tar.gz -P $DIR_PREFIX"
  fi
  if [ ! -e "$DIR_PREFIX$CEPSTRAL_MATTHIAS.tar.gz" ]; then
    bash -c "wget http://www.cepstral.com/downloads/installers/linux64/$CEPSTRAL_MATTHIAS.tar.gz -P $DIR_PREFIX"
  fi
  if [ ! -e "$DIR_PREFIX$CEPSTRAL_KATRIN.tar.gz" ]; then
    bash -c "wget http://www.cepstral.com/downloads/installers/linux64/$CEPSTRAL_KATRIN.tar.gz -P $DIR_PREFIX"
  fi
  #extract voices
  if [ ! -d "$DIR_PREFIX$CEPSTRAL_DAVID" ]; then
    bash -c "tar -xzvf $DIR_PREFIX$CEPSTRAL_DAVID.tar.gz -C $DIR_PREFIX"
  fi
  if [ ! -d "$DIR_PREFIX$CEPSTRAL_DIANE" ]; then
    bash -c "tar -xzvf $DIR_PREFIX$CEPSTRAL_DIANE.tar.gz -C $DIR_PREFIX"
  fi
  if [ ! -d "$DIR_PREFIX$CEPSTRAL_MATTHIAS" ]; then
    bash -c "tar -xzvf $DIR_PREFIX$CEPSTRAL_MATTHIAS.tar.gz -C $DIR_PREFIX"
  fi
  if [ ! -d "$DIR_PREFIX$CEPSTRAL_KATRIN" ]; then
    bash -c "tar -xzvf $DIR_PREFIX$CEPSTRAL_KATRIN.tar.gz -C $DIR_PREFIX"
  fi
  #cepstral conf
  sudo touch /etc/ld.so.conf.d/cepstral.conf
  sudo sh -c 'echo "/opt/swift/lib" > /etc/ld.so.conf.d/cepstral.conf'
  sudo ldconfig
  bash -c "sudo /u/robot/git/care-o-bot/src/cob_driver/cob_sound/fix_swift_for_precise.sh"
  #install and register voices
  if [ ! -e "/opt/swift/voices/David/license.txt" ]; then
    bash -c "cd $DIR_PREFIX$CEPSTRAL_DAVID && sudo ./install.sh"
    echo -e "\nPlease register DAVID:"
    bash -c "sudo swift --reg-voice"
  fi
  if [ ! -e "/opt/swift/voices/Diane/license.txt" ]; then
    bash -c "cd $DIR_PREFIX$CEPSTRAL_DIANE && sudo ./install.sh"
    echo -e "Please register DIANE:"
    bash -c "sudo swift --reg-voice"
  fi
  if [ ! -e "/opt/swift/voices/Matthias/license.txt" ]; then
    bash -c "cd $DIR_PREFIX$CEPSTRAL_MATTHIAS && sudo ./install.sh"
    echo -e "Please register MATTHIAS:"
    bash -c "sudo swift --reg-voice"
  fi
  if [ ! -e "/opt/swift/voices/Katrin/license.txt" ]; then
    bash -c "cd $DIR_PREFIX$CEPSTRAL_KATRIN && sudo ./install.sh"
    echo -e "Please register KATRIN:"
    bash -c "sudo swift --reg-voice"
  fi

  echo "setup cepstral voices done"
}

########################################################################
############################# INITIAL MENU #############################
########################################################################

if [[ "$1" =~ "--help" ]]; then echo -e $usage; exit 0; fi

#### check prerequisites
if [ "$USER" != "robot" ]; then
  echo -e "\n${red}FATAL: CAN ONLY BE EXECUTED AS robot USER${NC}"
  exit
fi

robot_name=$(get_search_domain)
if [ $(lsb_release -sc) == "trusty" ]; then
  ros_distro='indigo'
  source /opt/ros/indigo/setup.bash
elif [ $(lsb_release -sc) == "xenial" ]; then
  ros_distro='kinetic'
  source /opt/ros/kinetic/setup.bash
else
  echo -e "\n${red}FATAL: Script only supports indigo and kinetic"
  exit
fi

if [ -z $ROS_DISTRO ]; then
  echo -e "${red}\nNo ROS_DISTRO available, please source ROS first\n${NC}"
  exit 1
fi

if [ ! -e "/etc/kickstart_finished" ]; then
  echo -e "${yellow}\n${NC}"
  echo -e "${yellow}WARN: 'kickstart-robot.sh' did not finish correctly during stick setup.${NC}"
  echo -e "${yellow}WARN: Some of the following steps might not be executed on your robot:${NC}"
  grep -E '^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)' /u/robot/git/setup_cob4/images_config/kickstart/kickstart-robot.sh
  echo -e "${yellow}WARN: Please investigate '/var/log/installer/syslog' to see what went wrong.${NC}"
  echo -e "${yellow}WARN: 'grep' for 'Execute Kickstart-Function'...${NC}"

  echo -e "\nDo you want to continue now anyway (y/n)?"
  read answer

  if echo "$answer" | grep -iq "^y" ;then
    :
  else
    exit
  fi
fi

if [ ! -d /u/robot/git/setup_cob4 ]; then
  mkdir /u/robot/git
  git clone https://github.com/ipa320/setup_cob4 /u/robot/git/setup_cob4
else
  echo -e "\nDo you want to pull setup_cob4 from ipa320 master branch (y/n)?"
  read answer

  if echo "$answer" | grep -iq "^y" ;then
    echo -e "\nUpdating setup_cob4 from ipa320 master branch..."
    git --work-tree=/u/robot/git/setup_cob4 --git-dir=/u/robot/git/setup_cob4/.git pull https://github.com/ipa320/setup_cob4 master
  else
    echo -e "\nNot updating setup_cob4"
  fi
fi


echo -e "${green}===========================================${NC}"
echo "                INITIAL MENU"
echo -e "${green}===========================================${NC}"

echo -e $usage
read -p "Please select an installation option: " choice

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
elif [[ "$choice" == 50 ]]; then
  SetupCapabilitiesCepstralVoices
elif [[ "$choice" == 99 ]]; then
  SetupRootUser
  SetupRobotUser
  SetupMimicUser
  SetupDevices
  InstallSystemServices
else
  echo -e "\n${red}INFO: Invalid install option. Exiting. ${NC}\n"
fi
