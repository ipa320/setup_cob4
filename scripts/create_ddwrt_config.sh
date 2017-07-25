#!/bin/bash

function valid_ip()
{
    local ip=$1
    local stat=1

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

function valid_mac()
{
    local mac=$1
    local stat=1

    #capitalize it
    mac=${mac^^}
    if ! [ `echo $mac | egrep "^([0-9A-F]{2}:){5}[0-9A-F]{2}$"` ]; then
        stat=0
    fi

    return $stat
}

function read_mac()
{
    local pc_name=$1
    local mac_addr="$2"

    echo "Please insert MAC for $pc_name:"
    read mac
    valid_mac $mac

    while [[ $? -ne 1 ]];do
        echo "Wrong MAC format. Please insert MAC in format 00:11:22:33:44:55"
        read mac
        valid_mac $mac
    done
    eval $mac_addr=$mac
    return 1
}

function read_cert_from_file()
{
    local file=$1
    local stat=1
    local str=""
    certificate=$str
    if ! [ -f $file ];then
        echo "Error opening File $file"
        stat=0
    else
        str=`cat "$file"`
        idx=`expr index "$str" -----BEGIN`
        certificate=${str:$idx}
        echo $certificate
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

echo =====================================================
echo This Script configures a ddwrt router for a new robot
echo =====================================================
echo
echo Please insert the robot number. Eg. 7 for cob4-7 or 2 for cob4-2:
read robotnumber

echo
read -p "Do you like to add static leases (y/n):" static_leases
if echo "$static_leases" | grep -iq "^y" ;then
    mac_b_one=""
    read_mac "b1" 'mac_b_one'
    mac_t_one=""
    read_mac "t1" 'mac_t_one'
    mac_t_two=""
    read_mac "t2" 'mac_t_two'
    mac_t_three=""
    read_mac "t3" 'mac_t_three'
    mac_s_one=""
    read_mac "s1" 'mac_s_one'
    mac_h_one=""
    read_mac "h1" 'mac_h_one'

fi

echo
read -p "Do you like to add vpn certs (y/n):" vpn_certs
if echo "$vpn_certs" | grep -iq "^y" ;then
    echo "Please insert Path to VPN ca_cert (cacert.pem):"
    read ca_cert_path
    read_cert_from_file $ca_cert_path
    ca_cert=$certificate
    echo "Please insert Path to VPN Public Client Cert (xxxxxxxxxx.pem):"
    read pub_cert_path
    read_cert_from_file $pub_cert_path
    pub_cert=$certificate
    echo "Please insert Path to VPN Private Client Cert: (user.pem)"
    read priv_cert_path
    read_cert_from_file $priv_cert_path
    priv_cert=$certificate
fi

robotname='cob4-'$robotnumber
ipaddress='10.4.'$robotnumber

echo
echo "Are you shure you like to create a new ddwrt config with the following settings"
echo "RobotName: $robotname"
echo "IPAddress: $ipaddress.1"
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
read -p "(y/n):" choice

if echo "$choice" | grep -iq "^y" ;then
  echo "generating shell scripts"
  tmp_essential=tmp.config.essential.sh
  tmp_preferred=tmp.config.preferred.sh

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
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R 192.168.1.1
  ssh-keyscan -H 192.168.1.1 >> ~/.ssh/known_hosts
  ssh root@192.168.1.1 "echo"
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
