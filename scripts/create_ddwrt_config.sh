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
FILE_ESSENTIAL=ddwrt.config.essential.sh
FILE_PREFERRED=ddwrt.config.preferred.sh
if ! [ -f $FILE_ESSENTIAL ];then
  echo "File ddwrt.config.essential.sh does not exist."
  exit
fi

if ! [ -f $FILE_ESSENTIAL ];then
  echo "File ddwrt.config.preferred.sh does not exist."
  exit
fi

echo ==================================================
echo This Script configures a ddwrt route for a new robot
echo ==================================================
echo
echo Please insert the robot number. Eg. 7 for cob4-7 or 2 for cob4-2:
read robotnumber

echo "Do you like to add static leases (y/n):"
old_stty_cfg=$(stty -g)
stty raw -echo
static_leases=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$static_leases" | grep -iq "^y" ;then
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
fi
echo "Do you like to add vpn certs (y/n):"
old_stty_cfg=$(stty -g)
stty raw -echo
vpn_certs=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$vpn_certs" | grep -iq "^y" ;then
    echo Please insert VPN ca_cert:
    read ca_cert
    echo Please insert VPN Public Client Cert:
    read pub_cert
    echo Please insert VPN Private Client Cert:
    read priv_cert
fi

robotname='cob4-'$robotnumber
ipaddress='10.4.'$robotnumber

echo Are you shure you like to create a new ddwrt config with the following settings
echo RobotName: $robotname
echo IPAddress: $ipaddress
if echo "$static_leases" | grep -iq "^y" ;then
    echo MAC b1: $mac_b_one
    echo MAC t1: $mac_t_one
    echo MAC t2: $mac_t_two
    echo MAC t3: $mac_t_three
    echo MAC s1: $mac_s_one
    echo MAC h1: $mac_h_one
fi
if echo "$vpn_certs" | grep -iq "^y" ;then
    echo ca_cert: $ca_cert
    echo pub_cert: $pub_cert
    echo priv_cert: $priv_cert
fi

echo "(y/n):"
old_stty_cfg=$(stty -g)
stty raw -echo
decision=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg

tmp_essential=tmp.config.essential.sh
tmp_preferred=tmp.config.preferred.sh
echo "generating shell scripts"
if echo "$decision" | grep -iq "^y" ;then
  cmd='s/cob4-x/'$robotname'/g'
  sed $cmd $FILE_ESSENTIAL > $tmp_essential
  sed $cmd $FILE_PREFERRED > $tmp_preferred
  cmd='s/10.4.1/'$ipaddress'/g'
  sed -i "$cmd" "$tmp_essential"
  sed -i "$cmd" "$tmp_preferred"

  if echo "$vpn_certs" | grep -iq "^y" ;then
    cmd='s/###CA-CERT###/'$ca_cert'/g'
    sed -i "$cmd" "$tmp_essential"
    sed -i "$cmd" "$tmp_preferred"

    cmd='s/###PUB-CLIENT-CERT###/'$pub_cert'/g'
    sed -i "$cmd" "$tmp_essential"
    sed -i "$cmd" "$tmp_preferred"

    cmd='s/###PRIV-CLIENT-CERT###/'$priv_cert'/g'
    sed -i "$cmd" "$tmp_essential"
    sed -i "$cmd" "$tmp_preferred"
  fi

  if echo "$static_leases" | grep -iq "^y" ;then
      cmd='s/00:00:00:00:00:11/'$mac_b_one'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"

      cmd='s/00:00:00:00:00:22/'$mac_t_one'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"

      cmd='s/00:00:00:00:00:33/'$mac_t_two'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"

      cmd='s/00:00:00:00:00:44/'$mac_t_three'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"

      cmd='s/00:00:00:00:00:55/'$mac_s_one'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"

      cmd='s/00:00:00:00:00:66/'$mac_h_one'/g'
      sed -i "$cmd" "$tmp_essential"
      sed -i "$cmd" "$tmp_preferred"
  fi


  #copy scripts to router
  echo "copy scripts to router"
  ssh root@192.168.1.1 "ls"
  sshpass -p 'admin' scp "$tmp_essential" root@192.168.1.1:/tmp
  sshpass -p 'admin' scp "$tmp_preferred" root@192.168.1.1:/tmp
  echo "make scripts executable"
  sshpass -p 'admin' ssh root@192.168.1.1 "chmod a+x '/tmp/'$tmp_essential"
  sshpass -p 'admin' ssh root@192.168.1.1 "chmod a+x '/tmp/'$tmp_preferred"
  echo "execute config scripts"
  sshpass -p 'admin' ssh root@192.168.1.1 "'/tmp/'$tmp_essential"
  sshpass -p 'admin' ssh root@192.168.1.1 "'/tmp/'$tmp_preferred"
  echo "reboot router"
  sshpass -p 'admin' ssh root@192.168.1.1 'reboot'

  echo "removing tmp files"
  rm "$tmp_essential"
  rm "$tmp_preferred"
else
    exit
fi
