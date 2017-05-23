#!/bin/bash

set -e

robot_name="${HOSTNAME//-b1}"
ROS_DISTRO="indigo"

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-start /usr/sbin/cob-start
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-start
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start
sudo sed -i "s/myuser/msh/g" /usr/sbin/cob-start
sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-stop /usr/sbin/cob-stop
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop
sudo sed -i "s/myuser/msh/g" /usr/sbin/cob-stop
sudo sed -i "s/mydistro/$ROS_DISTRO/g" /usr/sbin/cob-stop
sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-stop"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-start-gui /usr/sbin/cob-start-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-start-gui
sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start-gui"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob-stop-gui /usr/sbin/cob-stop-gui
sudo sed -i "s/myrobotname/$robot_name/g" /usr/sbin/cob-stop-gui
sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

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

sudo mkdir -p /etc/ros/$ROS_DISTRO/cob.d
sudo cp -rf /u/robot/git/setup_cob4/upstart_msh/cob.d /etc/ros/$ROS_DISTRO/
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/$ROS_DISTRO/cob.d/launch/robot/robot.launch
