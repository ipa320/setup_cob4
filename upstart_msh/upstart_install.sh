#!/bin/bash

set -e

robot_name="${HOSTNAME//-b1}"

sudo apt-get install ros-indigo-robot-upstart
sudo apt-get install tmux
sudo apt-get install nmap

sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobot/$robot_name/g" /usr/sbin/cob-start

sudo cp -f /u/robot/git/setup_cob4/upstart/cob-stop /usr/sbin/cob-stop

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.yaml /etc/ros/cob.yaml
sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml

sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers 
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop" -e "}" /etc/sudoers 
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers 

camera_client_list="
$robot_name-t1
$robot_name-t3
$robot_name-s1"

for client in $camera_client_list; do
        echo "-------------------------------------------"
        echo "Executing on $client"
        echo "-------------------------------------------"
        echo ""
        ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done

#EXTRA FOR THE GUI

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start-gui /usr/sbin/cob-start-gui
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start-gui

sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start-gui"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop-gui /usr/sbin/cob-stop-gui
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-stop-gui

sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi 
