#!/usr/bin/env bash

## Headcam ##
HeadcamAttr1='ATTRS{idVendor}=="05a3"'
HeadcamAttr2='ATTRS{idProduct}=="8830"'

wait_file() {
    local file="$1"; shift
    local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

    echo "Waiting for USB device $file $wait_seconds seconds..."

    until test $((wait_seconds--)) -eq 0 -o -e "$file" ; do sleep 1; done

    ((++wait_seconds))
}

timeout=10

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video0" $timeout
then
    echo "Found USB device /dev/video0. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video0)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video0 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video1" $timeout
then
    echo "Found USB device /dev/video1. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video1)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video1 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video2" $timeout
then
    echo "Found USB device /dev/video2. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video2)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video2 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video3" $timeout
then
    echo "Found USB device /dev/video3. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video3)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video3 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video4" $timeout
then
    echo "Found USB device /dev/video4. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video4)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video4 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video5" $timeout
then
    echo "Found USB device /dev/video5. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video5)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video5 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video6" $timeout
then
    echo "Found USB device /dev/video6. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video6)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video6 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi

# If usb is already there the files should be as well. So just wait 10 secs
if wait_file "/dev/video7" $timeout
then
    echo "Found USB device /dev/video7. Setting permissions and softlinks"
    # shellcheck disable=SC2024
    sudo udevadm info -a -p "$(udevadm info -q path -n /dev/video7)" > /tmp/headcam0
    if grep -qs "${HeadcamAttr1[@]}" /tmp/headcam0  && grep -qs "${HeadcamAttr2[@]}" /tmp/headcam0
    then
        sudo ln -s video7 /dev/headcam
        exit
    fi
else
    echo "Waited $timeout seconds for USB device /dev/headcam0 to become availible. Controller will not work on this device!"
fi
