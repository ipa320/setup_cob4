#!/bin/bash

robot_name="${HOSTNAME//-b1}"

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop /usr/sbin/cob-stop
sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop-core /usr/sbin/cob-stop-core

client_list="
$robot_name-b1
$robot_name-t1
$robot_name-t2
$robot_name-t3
$robot_name-s1
$robot_name-h32"

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

sudo cp -r /u/robot/git/setup_cob4/upstart_msh/cob.d/launch /etc/ros/$ROS_DISTRO/cob.d/
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch


