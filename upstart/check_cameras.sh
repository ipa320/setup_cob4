#!/bin/bash
# during the test some extra dmesg errors were found but we can ignore then to start succesfully the driver:
#ERROR1 : cannot get freq at ep 0x84
#ERROR2 : cannot set freq 44100 to ep 0x84

sleep 30
check1=false
check2=false
check3=false

echo "$(date)"

dmesg | grep "Not enough bandwidth for new device state."
if [ $? -eq 0 ]; then
  echo "error -- Not enough bandwidth -- found"
else
  check1=true
fi

dmesg | grep "cannot get min/max values"
if [ $? -eq 0 ]; then
  echo "error -- cannot get min/max value -- found"
else
  check2=true
fi

dmesg | grep "device descriptor read/all, error -110"
if [ $? -eq 0 ]; then
  echo "error -- device descriptor read/all -- found"
else
  check3=true
fi

if $check1 && $check2 && $check3; then
 echo "OK"
 touch /tmp/check_done
else
 reboot -f now
fi
