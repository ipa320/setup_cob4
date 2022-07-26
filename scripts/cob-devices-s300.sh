#!/usr/bin/env bash

## ScanFront ##
ScanFrontAttr1='ATTRS{bInterfaceNumber}=="00"'
ScanFrontAttr2='ATTRS{serial}=="XXXXXXXX"'

## ScanLeft ##
ScanLeftAttr1='ATTRS{bInterfaceNumber}=="01"'
ScanLeftAttr2='ATTRS{serial}=="XXXXXXXX"'

## ScanRight ##
ScanRightAttr1='ATTRS{bInterfaceNumber}=="00"'
ScanRightAttr2='ATTRS{serial}=="XXXXXXXX"'

wait_file() {
    local file="$1"; shift
    local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

    echo "Waiting for USB device $file $wait_seconds seconds..."

    until test $((wait_seconds--)) -eq 0 -o -e "$file" ; do sleep 1; done

    ((++wait_seconds))
}

timeout=240   # wait a little longer for scanner

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
