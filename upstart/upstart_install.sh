#!/bin/bash

if [ "$HOSTNAME" != "$ROBOT-b1" ]; then 
	echo "FATAL: CAN ONLY BE EXECUTED ON BASE PC"
	exit
fi

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

	
client_list="
$ROBOT-b1
$ROBOT-t1
$ROBOT-t2
$ROBOT-t3
$ROBOT-s1
$ROBOT-h1"

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

sudo cp -r /u/robot/git/setup_cob4/upstart/cob.d/launch /etc/ros/$ROS_DISTRO/cob.d/
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/indigo/cob.d/setup/setup.sh

