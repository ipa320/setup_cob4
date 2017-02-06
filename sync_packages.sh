#!/bin/bash
robot_name="${HOSTNAME//-b1}"

if [ "$HOSTNAME" != "$robot_name-b1" ]; then 
	echo "FATAL: CAN ONLY BE EXECUTED ON BASE PC"
	exit
fi

sudo apt list --installed > /tmp/package_list
perl -pi -e 's{ / .*? ]}{}x' /tmp/package_list
sed -i 's/Listing...//' /tmp/package_list 
sed -i ':a;N;$!ba;s/\n/ /g' /tmp/package_list
tr '\n' ' ' < /tmp/package_list | sed -i '$s/ $/\n/' /tmp/package_list
packages=$(cat /tmp/package_list)

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
  ssh $i "sudo apt-get install $packages -y"
  ret=${PIPESTATUS[0]}
  if [ $ret != 0 ] ; then
    echo -t "apt-get return an error (error code: $ret), aborting..."
    exit 1
  fi
  echo ""
done

