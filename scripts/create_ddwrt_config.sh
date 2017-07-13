#!/bin/bash

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#check if template file is inside the same directory
FILE=../ddwrt_backup/cob4-x_wrt3200_backup.bin
if ! [ -f $FILE ];then
  echo "File cob4-x_wrt3200_backup.bin does not exist."
fi

echo ==================================================
echo This Script creates a ddwrt config for a new robot
echo ==================================================
echo
echo Please insert the robot number. Eg. 7 for cob4-7 or 2 for cob4-2:
read robotnumber
echo Please insert MAC from b1 PC:
read mac_b_one
echo Please insert MAC from t1 PC:
read mac_t_one
echo Please insert MAC from t2 PC:
read mac_t_two
echo Please insert MAC from t3 PC:
read mac_t_three
echo Please insert MAC from s1 PC:
read mac_s_one
echo Please insert MAC from h1 PC:
read mac_h_one
echo Please insert VPN ca_cert:
read ca_cert
echo Please insert VPN Public Client Cert:
read pub_cert
echo Please insert VPN Private Client Cert:
read priv_cert

robotname='cob4-'$robotnumber
ipaddress='10.4.'$robotnumber

echo Are you shure you like to create a new ddwrt config with the following settings
echo RobotName: $robotname
echo IPAddress: $ipaddress
echo MAC b1: $mac_b_one
echo MAC t1: $mac_t_one
echo MAC t2: $mac_t_two
echo MAC t3: $mac_t_three
echo MAC s1: $mac_s_one
echo MAC h1: $mac_h_one

echo -n "(y/n):"
old_stty_cfg=$(stty -g)
stty raw -echo
decision=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg

newfilename=../ddwrt_backup/$robotname'_wrt3200_config.bin'
if echo "$decision" | grep -iq "^y" ;then
  cmd='s/cob4-x/'$robotname'/g'
  sed $cmd $FILE > $newfilename
  cmd='s/10.4.1/'$ipaddress'/g'
  sed -i $cmd $newfilename

  cmd='s/###CA-CERT###/'$ca_cert'/g'
  sed -i "$cmd" "$newfilename"
  cmd='s/###PUB-CLIENT-CERT###/'$pub_cert'/g'
  sed -i "$cmd" "$newfilename"
  cmd='s/###PRIV-CLIENT-CERT###/'$priv_cert'/g'
  sed -i "$cmd" "$newfilename"
  cmd='s/00:00:00:00:00:11/'$mac_b_one'/g'
  sed -i $cmd $newfilename
  cmd='s/00:00:00:00:00:22/'$mac_t_one'/g'
  sed -i $cmd $newfilename
  cmd='s/00:00:00:00:00:33/'$mac_t_two'/g'
  sed -i $cmd $newfilename
  cmd='s/00:00:00:00:00:44/'$mac_t_three'/g'
  sed -i $cmd $newfilename
  cmd='s/00:00:00:00:00:55/'$mac_s_one'/g'
  sed -i $cmd $newfilename
  cmd='s/00:00:00:00:00:66/'$mac_h_one'/g'
  sed -i $cmd $newfilename
else
    exit
fi
