#!/bin/bash

set -e

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.conf /etc/init/cob.conf
sudo cp -f /u/robot/git/setup_cob4/scripts/cob-start /usr/sbin/cob-start
sudo cp -f /u/robot/git/setup_cob4/scripts/cob-command /usr/sbin/cob-command

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob.yaml /etc/ros/cob.yaml
sudo sed -i "s/myrobot/$ROBOT/g" /etc/ros/cob.yaml

sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start" -e "}" /etc/sudoers 
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers 

### alternative for lines above
#sudoers_string="%users ALL=NOPASSWD:/usr/sbin/cob-start"
#if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
#  echo $sudoers_string | sudo tee -a /etc/sudoers
#fi
#sudoers_string=%users ALL=NOPASSWD:/usr/sbin/cob-command"
#if ! sudo grep -q "$sudoers_string" /etc/sudoers ; then
#  echo $sudoers_string | sudo tee -a /etc/sudoers
#fi

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

#EXTRA FOR THE GUI

sudo cp -f /u/robot/git/setup_cob4/upstart_msh/cob_msh.conf /etc/init/cob_msh.conf

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-start-gui /usr/sbin/cob-start-gui
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-start-gui
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-start-gui"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-start-gui|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-start-gui||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-start-gui" -e "}" /etc/sudoers 

sudo cp /u/robot/git/setup_cob4/upstart_msh/cob-stop-gui /usr/sbin/cob-stop-gui
sudo sed -i "s/myrobot/$ROBOT/g" /usr/sbin/cob-stop-gui
sudo sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui"' | sudo sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-stop-gui" -e "}" /etc/sudoers 
