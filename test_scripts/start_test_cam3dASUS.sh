#!/bin/bash
#copy this file to /etc/init.d folder
#and call "sudo update-rc.d start_test_cam3dASUS.sh defaults"
#
now=`date +%d-%H%M%S`
# The result of the test will be saved on the home directory of the test user
mkdir /u/test/asus_test_$now
sleep 5
dmesg > /u/test/asus_test_$now/dmesg_before_launch &
sleep 1
dmesg --clear

# Start ROS
export ROSLAUNCH_SSH_UNKNOWN=1
#define your ROS_MASTER_URI hostname or IP Address
export ROS_MASTER_URI=http://cob4-X-b1:11311 
/u/robot/git/care-o-bot/devel/env.sh roslaunch cob_bringup openni2.launch robot:=cob4-1 name:=torso_cam3d_right&
sleep 10
/u/robot/git/care-o-bot/devel/env.sh roslaunch cob_bringup hz_monitor.launch robot:=cob4-1 yaml_name:=torso_cam3d_right&
/opt/ros/indigo/env.sh rostopic echo /diagnostics > /u/test/asus_test_$now/hztest &
./etc/init.d/check_cameras.sh > /u/test/asus_test_$now/check & 
sleep 1800
dmesg > /u/test/asus_test_$now/dmesg_after_launch &
#sudo reboot -f now
