#!/bin/bash
robot_name="${HOSTNAME//-b1}"

if [ "$HOSTNAME" != "$robot_name-b1" ]; then 
	echo "FATAL: CAN ONLY BE EXECUTED ON BASE PC"
	exit
fi

packages=$(dpkg --get-selections | grep -v "deinstall" | awk '{print $1}')
echo $packages > /tmp/package_list

pcs="
$robot_name-b1
$robot_name-t1
$robot_name-t2
$robot_name-t3
$robot_name-s1
$robot_name-h1"

for i in $pcs; do 
  echo "-------------------------------------------"
  echo "Installing packages on $i"
  echo "-------------------------------------------"
  echo ""
  ssh $i "sudo apt-get update"
  ssh $i "xargs sudo apt-get install -y" <<< $packages
  ret=${PIPESTATUS[0]}
  if [ $ret != 0 ] ; then
    echo -t "apt-get return an error (error code: $ret), aborting..."
    exit 1
  fi
  echo ""
done

