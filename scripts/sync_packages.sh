#!/bin/bash

#if [ "$HOSTNAME" != "$ROBOT-b1" ]; then 
#	echo "FATAL: CAN ONLY BE EXECUTED ON BASE PC"
#	exit
#fi

packages=$(dpkg --get-selections | grep -v "deinstall" | awk '{print $1}')
echo $packages > /tmp/package_list

pcs="
$ROBOT-b1
$ROBOT-t1
$ROBOT-t2
$ROBOT-t3
$ROBOT-s1
$ROBOT-h1"

declare -a commands=(
'sudo apt-get update > /dev/null'
'xargs sudo apt-get install -y <<< $packages'
'sudo apt-get autoremove -y'
)


for i in $pcs; do 
  echo "-------------------------------------------"
  echo "Installing packages on $i"
  echo "-------------------------------------------"
  echo ""
  for command in "${commands[@]}"; do
    ssh $i $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -t "$command return an error in $i (error code: $ret), aborting..."
      exit 1
    fi
  done
  echo ""
done

