#!/bin/bash

robot_name="${HOSTNAME//-b1}"

sudo apt-get install ros-indigo-robot-upstart
sudo cp /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
sudo cp /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo cp /u/robot/git/setup_cob4/upstart/cob-stop /usr/sbin/cob-stop
sudo cp /u/robot/git/setup_cob4/upstart/cob-stop-core /usr/sbin/cob-stop-core
sudo echo "%users ALL=NOPASSWD:/usr/sbin/cob-start" | sudo tee -a /etc/sudoers
sudo echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop" | sudo tee -a /etc/sudoers
sudo echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-core" | sudo tee -a /etc/sudoers

	


camera_client_list="
$robot_name-t1
$robot_name-t3
$robot_name-s1"

for client in $camera_client_list; do
        echo "-------------------------------------------"
        echo "Executing on $client"
        echo "-------------------------------------------"
        echo ""
        ssh $client "sudo cp /u/robot/git/setup_cob4/upstart/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done

sudo mkdir /etc/ros/$ROS_DISTRO
sudo cp -rf /u/robot/git/setup_cob4/upstart/cob.d /etc/ros/$ROS_DISTRO/cob.d
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
sudo sed -i "s/myrobotname/$robot_name/g" /etc/ros/$ROS_DISTRO/cob.d/setup/setup.sh
