#!/usr/bin/env bash
#################################################################
##\file
#
# \note
# Copyright (c) 2010 \n
# Fraunhofer Institute for Manufacturing Engineering
# and Automation (IPA) \n\n
#
#################################################################
#
# \note
# Project name: care-o-bot
# \note
# ROS stack name: setup
# \note
# ROS package name: setup
#
# \author
# Author: Nadia Hammoudeh Garcia, email:nadia.hammoudeh.garcia@ipa.fhg.de
# \author
# Supervised by: Nadia Hammoudeh Garcia, email:nadia.hammoudeh.garcia@ipa.fhg.de
#
# \date Date of creation: Dec 2012
#
# \brief
# Implements helper script for working with git and the care-o-bot stacks.
#
# copy this executable into /etc/init.d
# chmod +x udev_cob.sh
# sudo cp udev_cob.sh /etc/init.d/
# sudo update-rc.d udev_cob.sh defaults
#
#################################################################
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer. \n
# - Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution. \n
# - Neither the name of the Fraunhofer Institute for Manufacturing
# Engineering and Automation (IPA) nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission. \n
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License LGPL as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License LGPL for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License LGPL along with this program.
# If not, see <http://www.gnu.org/licenses/>.
#
#################################################################

## Joystick ##
JoyAttr1='Playstation'

sleep 10

sudo chmod 666 /dev/input/js0
# shellcheck disable=SC2024
sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js0)" > /tmp/js0
if grep -qs $JoyAttr1 /tmp/js0
then
    sudo ln -s input/js0 /dev/joypad
    sudo chown :dialout /dev/joypad
    sudo sh /u/robot/git/setup_cob4/udev_rules/ps3joy_node_starter.sh
fi

sudo chmod 666 /dev/input/js1
# shellcheck disable=SC2024
sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js1)" > /tmp/js1
if grep -qs $JoyAttr1 /tmp/js1
then
    sudo ln -s input/js1 /dev/joypad
    sudo chown :dialout /dev/joypad
    sudo sh /u/robot/git/setup_cob4/udev_rules/ps3joy_node_starter.sh
fi

sudo chmod 666 /dev/input/js2
# shellcheck disable=SC2024
sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js2)" > /tmp/js2
if grep -qs $JoyAttr1 /tmp/js2
then
    sudo ln -s input/js2 /dev/joypad
    sudo chown :dialout /dev/joypad
    sudo sh /u/robot/git/setup_cob4/udev_rules/ps3joy_node_starter.sh
fi
