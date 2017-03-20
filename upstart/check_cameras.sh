#!/bin/bash
sleep 30
check1=false
check2=false
check3=true
check4=false
check5=true

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

#dmesg | grep "cannot get freq at ep 0x84"
#if [ $? -eq 0 ]; then
#  echo "error -- cannot get freq -- found" 
#else
#  check3=true
#fi

dmesg | grep "device descriptor read/all, error -110"
if [ $? -eq 0 ]; then
  echo "error -- device descriptor read/all -- found"
else
  check4=true
fi

#dmesg | grep "cannot set freq 44100 to ep 0x84"
#if [ $? -eq 0 ]; then
#  echo "error -- cannot set freq 44100 to ep 0x84 -- found"
#else
#  check5=true
#fi

if $check1 && $check2 && $check3 && $check4 && $check5; then
 echo "OK"
 touch /tmp/check_done
else
 reboot -f now
fi
