#!/bin/bash
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

## ScanFront ##
ScanFrontAttr1='ATTRS{bInterfaceNumber}=="00"'
ScanFrontAttr2='ATTRS{serial}=="XXXXXXXX"'

## ScanLeft ##
ScanLeftAttr1='ATTRS{bInterfaceNumber}=="01"'
ScanLeftAttr2='ATTRS{serial}=="XXXXXXXX"'

## ScanRight ##
ScanRightAttr1='ATTRS{bInterfaceNumber}=="00"'
ScanRightAttr2='ATTRS{serial}=="XXXXXXXX"'

## Joystick ##
JoyAttr1='ATTRS{idVendor}=="046d"'
#JoyAttr2='ATTRS{idProduct}=="c21f"'

wait_file() {
    local file="$1"; shift
    local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

    echo "Waiting for USB device $file $wait_seconds seconds..."

    until test $((wait_seconds--)) -eq 0 -o -e "$file" ; do sleep 1; done

    ((++wait_seconds))
}

timeout=240

# For the first device we need to wait a longer time (time till usb is up and running during bootup)
if wait_file "/dev/ttyUSB0" $timeout
then
    echo "Found USB device /dev/ttyUSB0. Setting permissions and softlinks"
    sudo chmod 666 /dev/ttyUSB0
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/ttyUSB0)" > /tmp/usb0
    if grep -qs "${ScanFrontAttr1[@]}" /tmp/usb0  && grep -qs "${ScanFrontAttr2[@]}" /tmp/usb0
    then
        sudo ln -s ttyUSB0 /dev/ttyScanFront
    fi
    if grep -qs "${ScanLeftAttr1[@]}" /tmp/usb0  && grep -qs "${ScanLeftAttr2[@]}" /tmp/usb0
    then
        sudo ln -s ttyUSB0 /dev/ttyScanLeft
    fi
    if grep -qs "${ScanRightAttr1[@]}" /tmp/usb0  && grep -qs "${ScanRightAttr2[@]}" /tmp/usb0
    then
        sudo ln -s ttyUSB0 /dev/ttyScanRight
    fi
else
    echo "Waited $timeout seconds for USB device /dev/ttyUSB0 to become availible. Scanner will not work on this device!"
fi

timeout=2
# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/ttyUSB1" $timeout
then
    echo "Found USB device /dev/ttyUSB1. Setting permissions and softlinks"
    sudo chmod 666 /dev/ttyUSB1
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/ttyUSB1)" > /tmp/usb1
    if grep -qs "${ScanFrontAttr1[@]}" /tmp/usb1  && grep -qs "${ScanFrontAttr2[@]}" /tmp/usb1
    then
        sudo ln -s ttyUSB1 /dev/ttyScanFront
    fi
    if grep -qs "${ScanLeftAttr1[@]}" /tmp/usb1  && grep -qs "${ScanLeftAttr2[@]}" /tmp/usb1
    then
        sudo ln -s ttyUSB1 /dev/ttyScanLeft
    fi
    if grep -qs "${ScanRightAttr1[@]}" /tmp/usb1  && grep -qs "${ScanRightAttr2[@]}" /tmp/usb1
    then
        sudo ln -s ttyUSB1 /dev/ttyScanRight
    fi
else
    echo "Waited $timeout seconds for USB device /dev/ttyUSB1 to become availible. Scanner will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/ttyUSB2" $timeout
then
    echo "Found USB device /dev/ttyUSB2. Setting permissions and softlinks"
    sudo chmod 666 /dev/ttyUSB2
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/ttyUSB2)" > /tmp/usb2
    if grep -qs "${ScanFrontAttr1[@]}" /tmp/usb2  && grep -qs "${ScanFrontAttr2[@]}" /tmp/usb2
    then
        sudo ln -s ttyUSB2 /dev/ttyScanFront
    fi
    if grep -qs "${ScanLeftAttr1[@]}" /tmp/usb2  && grep -qs "${ScanLeftAttr2[@]}" /tmp/usb2
    then
        sudo ln -s ttyUSB2 /dev/ttyScanLeft
    fi
    if grep -qs "${ScanRightAttr1[@]}" /tmp/usb2  && grep -qs "${ScanRightAttr2[@]}" /tmp/usb2
    then
        sudo ln -s ttyUSB2 /dev/ttyScanRight
    fi
else
    echo "Waited $timeout seconds for USB device /dev/ttyUSB2 to become availible. Scanner will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/ttyUSB3" $timeout
then
    echo "Found USB device /dev/ttyUSB3. Setting permissions and softlinks"
    sudo chmod 666 /dev/ttyUSB3
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/ttyUSB3)" > /tmp/usb3
    if grep -qs "${ScanFrontAttr1[@]}" /tmp/usb3 && grep -qs "${ScanFrontAttr2[@]}" /tmp/usb3
    then
        sudo ln -s ttyUSB3 /dev/ttyScanFront
    fi
    if grep -qs "${ScanLeftAttr1[@]}" /tmp/usb3  && grep -qs "${ScanLeftAttr2[@]}" /tmp/usb3
    then
        sudo ln -s ttyUSB3 /dev/ttyScanLeft
    fi
    if grep -qs "${ScanRightAttr1[@]}" /tmp/usb3  && grep -qs "${ScanRightAttr2[@]}" /tmp/usb3
    then
        sudo ln -s ttyUSB3 /dev/ttyScanRight
    fi
else
    echo "Waited $timeout seconds for USB device /dev/ttyUSB3 to become availible. Scanner will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/input/js0" $timeout
then
    echo "Found USB device /dev/input/js0. Setting permissions and softlinks"
    sudo chmod 666 /dev/input/js0
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js0)" > /tmp/js0
    if grep -qs "${JoyAttr1[@]}" /tmp/js0
    then
        sudo ln -s input/js0 /dev/joypad
    fi
else
    echo "Waited $timeout seconds for USB device /dev/input/js0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/input/js1" $timeout
then
    echo "Found USB device /dev/input/js1. Setting permissions and softlinks"
    sudo chmod 666 /dev/input/js1
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js1)" > /tmp/js1
    if grep -qs "${JoyAttr1[@]}" /tmp/js1
    then
        sudo ln -s input/js1 /dev/joypad
    fi
else
    echo "Waited $timeout seconds for USB device /dev/input/js1 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/input/js2" $timeout
then
    echo "Found USB device /dev/input/js2. Setting permissions and softlinks"
    sudo chmod 666 /dev/input/js2
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/input/js2)" > /tmp/js2
    if grep -qs "${JoyAttr1[@]}" /tmp/js2
    then
        sudo ln -s input/js2 /dev/joypad
    fi
else
    echo "Waited $timeout seconds for USB device /dev/input/js2 to become availible. Controller will not work on this device!"
fi
