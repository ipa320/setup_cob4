#!/bin/bash

robot_name="${HOSTNAME//-b1}"

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/indigo/g" /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/myuser/msh/g" /usr/sbin/cob-start
echo "%users ALL=NOPASSWD:/usr/sbin/cob-start" | sudo tee -a /etc/sudoers

sudo cp /u/robot/git/setup_cob4/scripts/cob-stop /usr/sbin/cob-stop
echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop" | sudo tee -a /etc/sudoers

sudo cp /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command
sudo echo "%users ALL=NOPASSWD:/usr/sbin/cob-command" | sudo tee -a /etc/sudoers

camera_client_list="
$robot_name-t2
$robot_name-t3
$robot_name-s1"

for client in $camera_client_list; do
        echo "-------------------------------------------"
        echo "Executing on $client"
        echo "-------------------------------------------"
        echo ""
        ssh $client "sudo cp /u/robot/git/setup_cob4/upstart_msh/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done

