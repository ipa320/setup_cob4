#!/bin/bash

if [ "$HOSTNAME" != "$ROBOT-b1" ]; then 
	echo "FATAL: CAN ONLY BE EXECUTED ON BASE PC"
	exit
fi


sudo cp /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop /usr/sbin/cob-stop

client_list="
$ROBOT-b1
$ROBOT-t1
$ROBOT-t2
$ROBOT-t3
$ROBOT-s1
$ROBOT-h32"

for client in $client_list; do
	echo "-------------------------------------------"
	echo "Executing on $client"
	echo "-------------------------------------------"
	echo ""
	ssh $client "sudo mkdir -p /etc/ros/$ROS_DISTRO/cob.d"
	ssh $client "sudo ln -s /u/robot/git/setup_cob4/upstart_msh/cob.d/setup /etc/ros/$ROS_DISTRO/cob.d/setup"
	ret=${PIPESTATUS[0]}
	if [ $ret != 0 ] ; then
		echo "command return an error (error code: $ret), aborting..."
	fi
	echo ""
done

sudo cp -r /u/robot/git/setup_cob4/upstart_msh/cob.d/launch /etc/ros/$ROS_DISTRO/cob.d/
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch


