#!/bin/bash
sleep 5
dmesg | grep "Not enough bandwidth for new device state."
if [ $? -eq 0 ]; then
  echo "error found"
  sudo reboot -f now
else
  touch /tmp/check_done
fi
