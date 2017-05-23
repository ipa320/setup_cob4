#!/bin/bash

set -e

robot_name="${HOSTNAME//-b1}"

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.yaml /etc/ros/cob.yaml
sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/cob.yaml

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers 
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers 

#sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start"
#if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
#  echo $sudoers_string | sudo tee -a /etc/sudoers
#fi


# define ASUS camera pcs
camera_client_list="
$robot_name-t1
$robot_name-t3
$robot_name-s1"

for client in $camera_client_list; do
        echo "-------------------------------------------"
        echo "Executing on $client"
        echo "-------------------------------------------"
        echo ""
        ssh $client "sudo cp -f /u/robot/git/setup_cob4/upstart/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done

#EXTRA FOR THE GUI

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start-gui /usr/sbin/cob-start-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start-gui
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start-gui"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start-gui|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start-gui||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start-gui" -e "}" /etc/sudoers 

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop-gui /usr/sbin/cob-stop-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop-gui
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui" -e "}" /etc/sudoers 
