#!/bin/bash
#copy this file to /etc/init.d folder
#and call "sudo update-rc.d check_cam3dASUS.sh defaults"
#
sleep 5
check1=false
check2=false
check3=false
check4=false
check5=false

echo "$(date)" >> /u/testlog_cam_right

dmesg | grep "Not enough bandwidth for new device state."
if [ $? -eq 0 ]; then
  echo "error -- Not enough bandwidth -- found" >> /u/testlog_cam_right 
else
  check1=true
fi

dmesg | grep "cannot get min/max values"
if [ $? -eq 0 ]; then
  echo "error -- cannot get min/max value -- found" >> /u/testlog_cam_right 
else
  check2=true
fi

dmesg | grep "cannot get freq at ep 0x84"
if [ $? -eq 0 ]; then
  echo "error -- cannot get freq -- found" >> /u/testlog_cam_right 
else
  check3=true
fi

dmesg | grep "device descriptor read/all, error -110"
if [ $? -eq 0 ]; then
  echo "error -- device descriptor read/all -- found" >> /u/testlog_cam_right 
else
  check4=true
fi

dmesg | grep "cannot set freq 44100 to ep 0x84"
if [ $? -eq 0 ]; then
  echo "error -- cannot set freq 44100 to ep 0x84 -- found" >> /u/testlog_cam_right  
else
  check5=true
fi

if $check1 && $check2 && $check3 && $check4 && $check5; then
 echo "OK" >> /u/testlog_cam_right 
 echo " " >> /u/testlog_cam_right
 echo " " >> /u/testlog_cam_right
 echo " " >> /u/testlog_cam_right
 touch /tmp/check_done
else
 reboot -f now
fi
