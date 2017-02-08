#!/bin/bash

robot_name="${HOSTNAME//-b1}"

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
echo "%users ALL=NOPASSWD:/usr/sbin/cob-start" | sudo tee -a /etc/sudoers

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop /usr/sbin/cob-stop
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop
echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop" | sudo tee -a /etc/sudoers

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start-msh-gui /usr/sbin/cob-start-msh-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start-msh-gui
echo "%users ALL=NOPASSWD:/usr/sbin/cob-start-msh-gui" | sudo tee -a /etc/sudoers

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop-msh-gui /usr/sbin/cob-stop-msh-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop-msh-gui
echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-msh-gui" | sudo tee -a /etc/sudoers

camera_client_list="
$robot_name-t1
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

sudo mkdir /etc/ros/$ROS_DISTRO
sudo cp -rf /u/robot/git/setup_cob4/upstart_msh/cob.d /etc/ros/$ROS_DISTRO/cob.d
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
sudo sed -i "s/myrobotname/$robot_name/g" /etc/ros/$ROS_DISTRO/cob.d/setup/setup.sh
