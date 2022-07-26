#!/usr/bin/env bash

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

timeout=10

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
