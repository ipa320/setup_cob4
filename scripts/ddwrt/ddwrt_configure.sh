#!/usr/bin/env bash

function valid_ip()
{
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=("$ip")
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
    if ! "$(echo "$mac" | grep -Eq "^([0-9A-F]{2}:){5}[0-9A-F]{2}$")"; then
        stat=0
    fi

    return $stat
}

function read_mac()
{
    local pc_name=$1
    local mac_addr="$2"

    echo "Please insert MAC for $pc_name:"
    read -r mac
    valid_mac "$mac"

    while [[ $? -ne 1 ]];do
        echo "Wrong MAC format. Please insert MAC in format 00:11:22:33:44:55"
        read -r mac
        valid_mac "$mac"
    done
    eval "$mac_addr"="$mac"
    return 1
}

function read_cert_from_file()
{
    local file=$1
    local stat=1
    local str=""
    certificate=$str
    if ! [ -f "$file" ];then
        echo "Error opening File $file"
        stat=0
    else
        str=$(cat "$file")
        idx=$(test index "$str" -----BEGIN)
        certificate=${str:$idx}
        echo "$certificate"
    fi
    return $stat
}

echo =====================================================
echo This Script configures a ddwrt router for a new robot
echo =====================================================
echo
echo checking if router is reachable under 192.168.1.1...
if ping -c 1 192.168.1.1 &> /dev/null; then
    echo success
    router_address=192.168.1.1
else
    echo could not reach router on 192.168.1.1
    read -rp "Enter routers ip address:" router_address
    if ! ping -c 1 "$router_address" &> /dev/null; then
        echo "Could not reach router on" "$router_address"
        exit 1
    fi
fi
echo
read -rp "Do you like to configure device as a router or switch? (s/r)": config_type
echo
echo Please insert the robot number. Eg. 7 for cob4-7 or 2 for cob4-2:
read -r robotnumber
echo

robotname='cob4-'$robotnumber
ipaddress='10.4.'$robotnumber

if echo "$config_type" | grep -iq "^r" ;then
    config_type="router"
    #check if template file is inside the same directory
    CONFIG_ROUTER=ddwrt.config.router.sh
    if ! [ -f $CONFIG_ROUTER ];then
        echo "File ddwrt.config.router.sh does not exist."
        exit
    fi

    read -rp "Do you like to add static leases (y/n):" static_leases
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
        mac_flexisoft_ninetynine=""
        read_mac "flexisoft" 'mac_flexisoft_ninetynine'

    fi

    echo
    read -rp "Do you like to add vpn certs (y/n):" vpn_certs
    if echo "$vpn_certs" | grep -iq "^y" ;then
        echo "Please insert Path to VPN ca_cert (cacert.pem):"
        read -r ca_cert_path
        read_cert_from_file "$ca_cert_path"
        ca_cert=$certificate
        echo "Please insert Path to VPN Public Client Cert (xxxxxxxxxx.pem):"
        read -r pub_cert_path
        read_cert_from_file "$pub_cert_path"
        pub_cert=$certificate
        echo "Please insert Path to VPN Private Client Cert: (user.pem)"
        read -r priv_cert_path
        read_cert_from_file "$priv_cert_path"
        priv_cert=$certificate
    fi
fi

if echo "$config_type" | grep -iq "^s" ;then
    config_type="switch"
    #check if template file is inside the same directory
    CONFIG_ROUTER=ddwrt.config.switch.sh
    if ! [ -f $CONFIG_ROUTER ];then
        echo "File ddwrt.config.switch.sh does not exist."
        exit
    fi
fi

echo
echo "New Config"
echo "Config Type: $config_type"
echo "RobotName: $robotname"
echo "IPAddress: $ipaddress.1"
if echo "$static_leases" | grep -iq "^y" ;then
    echo MAC b1: "$mac_b_one"
    echo MAC t1: "$mac_t_one"
    echo MAC t2: "$mac_t_two"
    echo MAC t3: "$mac_t_three"
    echo MAC s1: "$mac_s_one"
    echo MAC h1: "$mac_h_one"
    echo MAC flexisoft: "$mac_flexisoft_ninetynine"
fi
if echo "$vpn_certs" | grep -iq "^y" ;then
    echo ca_cert:
    echo "$ca_cert"
    echo
    echo pub_cert:
    echo "$pub_cert"
    echo
    echo priv_cert:
    echo "$priv_cert"
    echo
fi
echo
echo "Are you shure you like to create a new ddwrt config with the following settings?"
read -rp "(y/n):" choice

if echo "$choice" | grep -iq "^y" ;then
  echo "generating shell scripts"
  tmp_config=tmp.config.sh


  cmd='s/robotname/'$robotname'/g'
  sed "$cmd" $CONFIG_ROUTER > $tmp_config
  cmd='s/ipaddress/'$ipaddress'/g'
  sed -i "$cmd" "$tmp_config"

  if echo "$vpn_certs" | grep -iq "^y" ;then
    cmd='s/###CA-CERT###/'$ca_cert'/g'
    sed -i "$cmd" "$tmp_config"

    cmd='s/###PUB-CLIENT-CERT###/'$pub_cert'/g'
    sed -i "$cmd" "$tmp_config"

    cmd='s/###PRIV-CLIENT-CERT###/'$priv_cert'/g'
    sed -i "$cmd" "$tmp_config"
  fi

  if echo "$static_leases" | grep -iq "^y" ;then
      cmd='s/00:00:00:00:00:11/'$mac_b_one'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:22/'$mac_t_one'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:33/'$mac_t_two'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:44/'$mac_t_three'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:55/'$mac_s_one'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:66/'$mac_h_one'/g'
      sed -i "$cmd" "$tmp_config"

      cmd='s/00:00:00:00:00:99/'$mac_flexisoft_ninetynine'/g'
      sed -i "$cmd" "$tmp_config"
  fi

  #copy scripts to router
  echo "copy scripts to router"
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$router_address"
  ssh-keyscan -H "$router_address" >> ~/.ssh/known_hosts
  ssh root@"$router_address" "echo"
  sshpass -p 'admin' scp "$tmp_config" root@"$router_address":/tmp
  echo "make scripts executable"
  sshpass -p 'admin' ssh root@"$router_address" "chmod a+x '/tmp/'$tmp_config"
  echo "execute config scripts"
  sshpass -p 'admin' ssh root@"$router_address" "'/tmp/'$tmp_config"
  echo "reboot router"
  sshpass -p 'admin' ssh root@"$router_address" 'reboot'

  echo "removing tmp files"
  rm "$tmp_config"
else
    exit
fi
