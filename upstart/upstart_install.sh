#!/bin/bash

robot_name="${HOSTNAME//-b1}"
ROS_DISTRO="indigo"

sudo apt-get install ros-indigo-robot-upstart
sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo cp -f /u/robot/git/setup_cob4/upstart/cob-stop /usr/sbin/cob-stop
sudo cp -f /u/robot/git/setup_cob4/upstart/cob-stop-core /usr/sbin/cob-stop-core

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers 

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop" -e "}" /etc/sudoers 

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-core"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop-core|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop-core||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop-core" -e "}" /etc/sudoers

	

client_list="
$robot_name-b1
$robot_name-t1
$robot_name-t2
$robot_name-t3
$robot_name-s1
$robot_name-h1"

for client in $client_list; do
	echo "-------------------------------------------"
	echo "Executing on $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "sudo mkdir -p /etc/ros/$ROS_DISTRO/cob.d"
	ssh $client "sudo ln -s /u/robot/git/setup_cob4/upstart/cob.d/setup /etc/ros/$ROS_DISTRO/cob.d/setup"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "command return an error (error code: $ret), aborting..."
	fi
	echo ""
done

camera_client_list="
$robot_name-t2
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

sudo cp -rf /u/robot/git/setup_cob4/upstart/cob.d/launch /etc/ros/$ROS_DISTRO/cob.d/
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
sudo sed -i "s/myrobot/$robot_name/g" /etc/ros/indigo/cob.d/setup/setup.sh

