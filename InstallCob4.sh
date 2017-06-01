#!/bin/bash
#### COMMON PARAMETERS
usage=$(cat <<"EOF"
USAGE:  ./InstallCob4.sh [-r] [-ip] [-m]\n
Where:\n
  -r robot name (example cob4-1)\n
  -ip ip address\n
  -m installation mode (master or slave)\n
EOF
)
green='\e[0;32m'
red='\e[0;31m'
NC='\e[0m' # No Color


#### FUNCTION BASIC INSTALLATION
function BasicInstallation {

  echo -e "\n${green}INFO:Installing basic tools${NC}\n"
  sleep 5
  sudo apt-get update
  sudo apt-get install vim tree gitg git-gui meld curl default-jdk terminator language-pack-de language-pack-en ipython nmap -y --force-yes

  echo -e "\n${green}INFO:Update grub to avoid hangs on reboot${NC}\n"
  sleep 5
  if grep -q GRUB_RECORDFAIL_TIMEOUT= /etc/default/grub ; then
    echo "found GRUB_RECORD_FAIL flag already, skipping update-grub call"
  else
    grep -q -F 'GRUB_RECORDFAIL_TIMEOUT=10' /etc/default/grub || sudo sh -c '(echo "GRUB_RECORDFAIL_TIMEOUT=10") >> /etc/default/grub'
    sudo update-grub
  fi

  echo -e "\n${green}INFO:Upgrade the kernel ${NC}\n"
  sleep 5
  sudo apt-get install --install-recommends linux-generic-lts-wily -y --force-yes

  echo -e "\n${green}INFO:Install openssh server${NC}\n"
  sleep 5
  sudo apt-get install openssh-server -y --force-yes
  echo -e "\n${green}INFO:Let the server send a alive interval to clients to not get a broken pipe${NC}\n"
  grep -q -F 'ClientAliveInterval 60' /etc/ssh/sshd_config || sudo sh -c '(echo "ClientAliveInterval 60") >> /etc/ssh/sshd_config'
  sudo sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

  echo -e "\n${green}INFO:Checkout the setup repository${NC}\n"
  sleep 5
  mkdir ~/git
  cd ~/git
  git clone git://github.com/ipa320/setup_cob4.git

  echo -e "\n${green}INFO:Allow robot user to execute sudo command without password${NC}\n"
  sleep 5
  grep -q -F 'robot ALL=(ALL) NOPASSWD: ALL' /etc/sudoers || sudo sh -c '(echo "robot ALL=(ALL) NOPASSWD: ALL") >> /etc/sudoers'
  sudo adduser robot dialout
  sudo adduser robot audio
  sudo adduser robot pulse

  echo -e "\n${green}INFO:Setup local ROOT user${NC}\n"
  sleep 5
  sudo passwd root

  echo -e "\n${green}INFO: Install ROS${NC}\n"
  sleep 5
  echo -e "\n${green}   INFO: Setup your source.list${NC}\n"
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu trusty main" >> /etc/apt/sources.list.d/ros-latest.list'
  echo -e "\n${green}   INFO: Set up your keys${NC}\n"
  wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
  echo -e "\n${green}   INFO: Install ROS${NC}\n"
  sudo apt-get update
  sudo apt-get install ros-indigo-rosbash ros-indigo-care-o-bot-robot python-rosdep python-rosinstall -y --force-yes
  sudo rosdep init
  rosdep update

  echo -e "\n${green}INFO: Removing modemmanager${NC}\n"
  sudo apt-get purge modemmanager
  
  echo -e "\n${green}INFO: Installing NoMachine!${NC}\n"
  wget http://download.nomachine.com/download/5.2/Linux/nomachine_5.2.11_1_i386.deb -O /tmp/nomachine.deb
  sudo dpkg -i /tmp/nomachine.deb

  echo -e "\n${green}INFO: Setup udev rules${NC}\n"
  sleep 5
  sudo cp ~/git/setup_cob4/udev_rules/udev_cob.sh /etc/init.d/
  sudo update-rc.d udev_cob.sh defaults

  echo -e "\n${green}INFO: Install Touchscreen driver${NC}\n"
  sleep 5
  wget http://www.cartft.com/support/drivers/TFT/tftdrivers/eGTouch_v2.5.2107.L-x.tar.gz
  tar -xf eGTouch_v2.5.2107.L-x.tar.gz
  cd eGTouch_v2.5.2107.L-x
  chmod +x setup.sh
  sudo ./setup.sh

  echo -e "\n${green}INFO: Setup bash environment${NC}\n"
  sleep 5
  if [[ "$HOSTNAME" == "$ROBOT-b1" ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/cob.bash.bashrc.b /etc/cob.bash.bashrc
  fi
  if [[ "$HOSTNAME" == "$ROBOT-t"* ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/cob.bash.bashrc.t /etc/cob.bash.bashrc
  fi
  if [[ "$HOSTNAME" == "$ROBOT-h"* ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/cob.bash.bashrc.h /etc/cob.bash.bashrc
  fi
  if [[ "$HOSTNAME" == "$ROBOT-s"* ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/cob.bash.bashrc.s /etc/cob.bash.bashrc
  fi

  echo -e "\n${green}INFO: Setup network interfaces${NC}\n"
  sleep 5
  if [[ "$HOSTNAME" == "$ROBOT-b1" ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/networkInterfacesB1 /etc/network/interfaces
  fi
  if [[ "$HOSTNAME" == "$ROBOT-t1" ]]
    then
      sudo cp ~/git/setup_cob4/cob-pcs/networkInterfacesT1 /etc/network/interfaces 
  fi

  echo -e "\n${green}INFO:  Define users rights${NC}\n"
  sleep 5
  sudo cp ~/git/setup_cob4/scripts/cob-shutdown /usr/sbin/cob-shutdown
  grep -q -F '%users ALL=NOPASSWD:/usr/sbin/cob-shutdown' /etc/sudoers || sudo sh -c '(echo "%users ALL=NOPASSWD:/usr/sbin/cob-shutdown") >> /etc/sudoers'
  sudo sed -i 's/etc\/acpi\/powerbtn.sh/usr\/sbin\/cob-shutdown/g' /etc/acpi/events/powerbtn

}

#### FUNCTION NFS SETUP
function NFSSetup
{
  if [ "$MODE" == "slave" ]; then
    read -p "Please type the ip address of the server pc: " server
    read -p "Are you sure that the server pc is with $server reachable (y/n)?" choice
      case "$choice" in 
        y|Y ) echo "Yes";;
        n|N ) echo "No" && exit;;
        * ) echo "invalid"&& exit;;
      esac
  elif [ "$MODE" == "master" ]; then
    echo -e "\n${green}INFO:Installing the server pc $hostname${NC}\n"
    server=$IP
  else
    echo -e "\n${red}ERROR:Invalid installation mode ${NC}\n" 
    echo -e $usage
    exit
  fi

  echo -e "\n${green}INFO: Setup NTP time synchronitation${NC}\n"
  sleep 5
  sudo apt-get install ntp -y --force-yes
  if [ "$MODE" == "master" ]
    then
      sudo apt-get install apt-cacher-ng
      sudo cp -f ~/git/setup_cob4/cob-pcs/ntp_server /etc/ntp.conf
      sudo sed -i "s/server_ip/$IP/g" /etc/ntp.conf
  elif [ "$MODE" == "slave" ]
    then
      sudo cp -f ~/git/setup_cob4/cob-pcs/ntp_client /etc/ntp.conf
      sudo sed -i "s/server_ip/$server/g" /etc/ntp.conf
      grep -q -F 'Acquire::http::Proxy \""http://'$server':3142"\";' /etc/apt/apt.conf.d/01proxy || sudo sh -c '(echo "Acquire::http::Proxy \""http://'$server':3142"\";") >> /etc/apt/apt.conf.d/01proxy'
  fi

  echo -e "\n${green}INFO:  Install NFS${NC}\n"
  sleep 5
  sudo apt-get install nfs-kernel-server autofs -y --force-yes
  sudo mkdir /u
  if [[ "$MODE" == "master" ]]
    then
      grep -q -F '/home /u none bind 0 0' /etc/fstab || sudo sh -c '(echo "/home /u none bind 0 0") >> /etc/fstab'
      sudo mount /u
      sudo sed -i 's/NEED_STADT\=/NEED_STADT\=yes/g' /etc/default/nfs-common
      grep -q -F '/u *(rw,fsid=0,sync,no_subtree_check)' /etc/exports || sudo sh -c '(echo "/u *(rw,fsid=0,sync,no_subtree_check)") >> /etc/exports'
      if [ -d "/u/robot/git" ]
        then
          sudo sed -i 's/home\/robot/u\/robot/g' /etc/passwd
          read -p "Reboot the computer for the changes to take effect (y/n)?" choice
            case "$choice" in 
                y|Y ) echo "Yes" && sudo reboot;;
                n|N ) echo "No" && exit;;
                * ) echo "invalid"&& exit;;
            esac
      fi
  elif [[ "$MODE" == "slave" ]]
    then 
      ping -c 1 -w 3 $server
      if [ $? -ne 0 ] ; then
        echo -e "\n${red}ERROR:Server $server unreachable ${NC}\n"
        exit
      fi
      sudo sed -i 's/NEED_STADT\=/NEED_STADT\=yes/g' /etc/default/nfs-common
      
      sudo touch /etc/auto.direct
      grep -q -F '/-  /etc/auto.direct' /etc/auto.master || sudo sh -c '(echo "/-  /etc/auto.direct") >> /etc/auto.master'
      grep -q -F '/u  -fstype=nfs4    '$server':/' /etc/auto.direct || sudo sh -c '(echo "/u  -fstype=nfs4    '$server':/") >> /etc/auto.direct'
      sudo update-rc.d autofs defaults
      sudo service autofs restart
      sudo modprobe nfs
        
      if [ -d "/u/robot/git" ]
        then
          sudo sed -i 's/home\/robot/u\/robot/g' /etc/passwd
          read -p "Reboot the computer for the changes to take effect (y/n)?" choice
            case "$choice" in 
                y|Y ) sudo reboot;;
                n|N ) exit;;
                * ) echo "invalid"&& exit;;
            esac
      fi
  fi

}

#### FUNCTION COB4 SETUP
function Cob4Setup
{
  if [ "$HOSTNAME" != "$ROBOT-b1" ]; then 
	  echo "FATAL: CAN ONLY BE EXECUTED ON MASTER PC"
	  exit
  fi

  echo -e "\n${green}INFO:  Setup bash environment${NC}\n"
  sleep 5
  cp ~/git/setup_cob4/cob-pcs/user.bashrc ~/.bashrc
  source /opt/ros/indigo/setup.bash
  sudo sed -i "s/myrobot/$ROBOT/g" ~/.bashrc
  sudo sed -i "s/mydistro/$ROS_DISTRO/g" ~/.bashrc

  echo -e "\n${green}INFO:  Create overlays for stacks${NC}\n"
  sleep 5
  mkdir /u/robot/git/care-o-bot
  mkdir /u/robot/git/care-o-bot/src
  cd /u/robot/git/care-o-bot/src
  source /opt/ros/indigo/setup.bash
  catkin_init_workspace
  cd /u/robot/git/care-o-bot
  catkin_make
  cd /u/robot/git/care-o-bot/src
  wstool init
  wget https://raw.githubusercontent.com/ipa320/setup_cob4/master/.rosinstall
  wstool update
  cd /u/robot/git/care-o-bot
  catkin_make install


  echo -e "\n${green}INFO:  Enable passwordless login${NC}\n"
  sleep 5
  ssh-keygen
  cat /u/robot/.ssh/id_rsa.pub | ssh robot@$ROBOT-b1 "cat >> /u/robot/.ssh/authorized_keys"
  ssh robot@$ROBOT-t1 'exit'
  ssh robot@$ROBOT-t2 'exit'
  ssh robot@$ROBOT-t3 'exit'
  ssh robot@$ROBOT-s1 'exit'
  ssh robot@$ROBOT-h1 'exit'

  echo -e "\n${green}INFO:  Install upstart job${NC}\n"
  sleep 5
  /u/robot/git/setup_cob4/upstart/upstart_install.sh

  echo -e "\n${green}INFO:  Enable passwordless login${NC}\n"
  sleep 5
  su root
  ssh-keygen
  ssh-copy-id $ROBOT-b1
  ssh root@$ROBOT-t1 'exit'
  ssh root@$ROBOT-t2 'exit'
  ssh root@$ROBOT-t3 'exit'
  ssh root@$ROBOT-s1 'exit'
  ssh root@$ROBOT-h1 'exit'

}

####Miminc##############
function Mimic
{
  if [ "$HOSTNAME" != "$ROBOT-h1" ]; then 
	  echo "FATAL: CAN ONLY BE EXECUTED ON Slave h1 PC"
	  exit
  fi
 echo -e "\n${green}INFO:  Mimic ${NC}\n"
  sleep 5

  sudo ssh $server "cob-adduser mimic"

  sudo sed -i '$ [SeatDefaults]' /etc/lightdm/lightdm.conf 
  sudo sed -i '$ autologin-user=mimic' /etc/lightdm/lightdm.conf 
  sudo sed -i '$ autologin-user-timeout=60' /etc/lightdm/lightdm.conf 

  sudo sed -i '$ [Desktop Entry]' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Type=Application' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Exec=xhost +' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Hidden=false' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ NoDisplay=false' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ X-GNOME-Autostart-enabled=true' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Name[en_US]=mimic' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Name=mimic' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Comment[en_US]=' /u/mimic/.config/autostart/xhost.desktop 
  sudo sed -i '$ Comment=' /u/mimic/.config/autostart/xhost.desktop 
}

########Netdata tools############
function Netdatatools {

  echo -e "\n${green}INFO:Installing Netdata tools${NC}\n"
  sleep 5
  sudo apt-get update
  sudo apt-get install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl -y --force-yes
  git clone https://github.com/firehol/netdata.git /u/robot/netdata --depth=1
  cd ~/netdata
  sudo ./netdata-installer.sh
}
########################################################################
############################# INITIAL MENU #############################
########################################################################


if [[ "$@" =~ "--help" || $# < 2 ]]; then echo -e $usage; exit 0; fi

while [[ $# >=1 ]]
do
key="$1"
shift
case $key in
    -r|--robot)
    ROBOT="$1"
    shift
    ;;
    -ip|--ipaddress)
    IP="$1"
    shift
    ;;
    -m|--mode)
    MODE="$1"
    shift
    ;;
    *)
    ;;
esac
done

if [ -z "$ROBOT" ]; then
    echo -e $usage
    exit
fi

if [ -z "$IP" ]; then
    echo -e $usage
    exit
fi

if [ -z "$MODE" ]; then
    echo -e $usage
    exit
fi

echo -e "\n${green}===========================================${NC}\n"
echo -e ROBOT  = "${green}${ROBOT}${NC}"
echo -e HOSTNAME     = "${green}${HOSTNAME}${NC}"
echo -e IP ADDRESS    = "${green}${IP}${NC}"
echo -e MODE    = "${green}${MODE}${NC}"
echo -e "\n${green}===========================================${NC}\n"
read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) ;;
  n|N ) exit;;
  * ) echo "invalid" && exit;;
esac

read -p "Please select the installation type 
1.Full installation (Basic installation + Setup NFS)
2.Basic installation
3.Setup NTP and NFS system
4.Cob4 setup (Execute only on master pc and after a full installation)
5.Mimic (Execute only on slave h1 pc and after a full installation)
6.Netdatatools
 " choice 
 
if [[ "$choice" == 1 ]]
  then
       BasicInstallation
       NFSSetup
fi

if [[ "$choice" == 2 ]]
  then
       BasicInstallation
fi

if [[ "$choice" == 3 ]]
  then
       NFSSetup
fi

if [[ "$choice" == 4 ]]
  then
       Cob4Setup
fi
if [[ "$choice" == 5 ]]
  then
       Mimic
fi
if [[ "$choice" == 6 ]]
  then
       Netdatatools
fi
