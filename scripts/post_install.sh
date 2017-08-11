#!/bin/bash

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

robot_name=$(echo ${HOSTNAME%-*})

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

#generate a ssh key for root user per pc
sudo echo -e "unset SSH_ASKPASS" >> /root/.bashrc
if [ ! -d "/root/.ssh" ]; then
  echo "create new ssh key"
  sudo su - root -c "ssh-keygen -f /root/.ssh/id_rsa -N ''"
  sudo su - root -c "ssh-keyscan -H localhost >> /root/.ssh/known_hosts"
  sudo su - root -c "ssh-copy-id root@localhost"
  sudo su - root -c "ssh root@localhost 'exit'"
  sudo cat /root/.ssh/id_rsa.pub | \
  ssh root@localhost \
  "sudo tee -a /root/.ssh/authorized_keys"
fi

for i in $pc_list; do
  sudo su - root -c "ssh-keyscan -H $i >> /root/.ssh/known_hosts"
  sudo su - root -c "ssh-copy-id root@$i"
  sudo su - root -c "ssh root@$i 'exit'"
  sudo cat /root/.ssh/id_rsa.pub | \
  ssh root@$i \
  "sudo mkdir /root/.ssh; sudo tee -a /root/.ssh/authorized_keys"
done

# syncronize passwords
for i in $pc_list; do
  sudo su root -c -l "rsync -avz -e ssh /etc/passwd /etc/shadow /etc/group root@$i:/etc/"
done

#generate a ssh key for robot user per pc
sudo echo -e "unset SSH_ASKPASS" >> /u/robot/.bashrc
if [ ! -d "/robot/.ssh" ]; then
  echo "create new ssh key"
  ssh-keygen -f /u/robot/.ssh/id_rsa -N ''
  ssh-keyscan -H localhost >> /u/robot/.ssh/known_hosts
  ssh-copy-id robot@localhost
  ssh robot@localhost 'exit'
fi

for i in $pc_list; do
  ssh-keyscan -H $i >> /u/robot/.ssh/known_hosts
  ssh-copy-id robot@$i
  ssh robot@$i 'exit'
done

# Configure basrc
if grep -q ROBOT "/u/robot/.bashrc"; then  
  echo ".bashrc already configured"
else
  wget -O /u/robot/.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/user.bashrc 
  sed -i -e "s/myrobot/${robot_name}/g" ~/.bashrc
  sed -i -e "s/mydistro/indigo/g" ~/.bashrc #only working for indigo!!!
fi

sudo apt-get install python-catkin-tools -y
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
  cd /u/robot/git/care-o-bot/ && catkin config --install
  cd /u/robot/git/care-o-bot/ && catkin config -DCMAKE_BUILD_TYPE=Release
  cd /u/robot/git/care-o-bot/ && catkin build
fi
