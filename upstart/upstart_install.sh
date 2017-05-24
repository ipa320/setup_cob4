#!/bin/bash

set -e

sudo cp -f /u/robot/git/setup_cob4/upstart/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/upstart/cob-start /usr/sbin/cob-start
sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

sudo cp -f /u/robot/git/setup_cob4/upstart/cob.yaml /etc/ros/cob.yaml
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/cob.yaml

sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi
sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-command"
if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
  echo $sudoers_string | sudo tee -a /etc/sudoers
fi

# define ASUS camera pcs
camera_client_list="
$ROBOT-t1
$ROBOT-t3
$ROBOT-s1"

for client in $camera_client_list; do
        echo "-------------------------------------------"
        echo "Executing on $client"
        echo "-------------------------------------------"
        echo ""
        ssh $client "sudo cp -f /u/robot/git/setup_cob4/scripts/check_cameras.sh /etc/init.d/check_cameras.sh"
        ssh $client "sudo update-rc.d check_cameras.sh defaults"
done
