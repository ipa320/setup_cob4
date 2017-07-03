#!/bin/bash

green='\e[0;32m'
red='\e[0;31m'
NC='\e[0m' # No Color
robot_name=$ROBOT

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
