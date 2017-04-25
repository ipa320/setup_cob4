#!/bin/bash

robot_name="${HOSTNAME//-b1}"

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf
sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/myuser/msh/g" /usr/sbin/cob-start
echo "%users ALL=NOPASSWD:/usr/sbin/cob-start" | sudo tee -a /etc/sudoers

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-stop /usr/sbin/cob-stop
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop
sudo sed -i "s/myuser/msh/g" /usr/sbin/cob-stop
echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop" | sudo tee -a /etc/sudoers

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-start-gui /usr/sbin/cob-start-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start-gui
echo "%users ALL=NOPASSWD:/usr/sbin/cob-start-gui" | sudo tee -a /etc/sudoers

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-stop-gui /usr/sbin/cob-stop-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop-gui
echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui" | sudo tee -a /etc/sudoers

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
        ssh $client "sudo cp -f /u/robot/git/setup_cob4/upstart/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done

sudo cp -rf /u/robot/git/setup_cob4/upstart_msh/cob.d /etc/ros/$ROS_DISTRO/.
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
