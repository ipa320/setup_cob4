#!/usr/bin/env sh
echo "Write variables"

nvram set wan_proto="dhcp"
nvram set wan_primary="1"
nvram set wan_netmask_static=".."
nvram set wan_netmask="0.0.0.0"
nvram set wan_mtu="1500"
nvram set wan_ipaddr_static=".."
nvram set wan_ipaddr_buf="ipaddress.1"
nvram set wan_hostname="robotname"
nvram set wan_domain="robotname"
nvram set wan_dns="ipaddress.1 8.8.8.8"

nvram set time_zone="Europe/Berlin"
nvram set telnetd_enable="1"
nvram set telnet_wanport="23"
nvram set static_leases="00:00:00:00:00:11=b1=ipaddress.11= 00:00:00:00:00:22=t1=ipaddress.21= 00:00:00:00:00:33=t2=ipaddress.22= 00:00:00:00:00:44=t3=ipaddress.23= 00:00:00:00:00:55=s1=ipaddress.31= 00:00:00:00:00:66=h1=ipaddress.41= 00:00:00:00:00:99=flexisoft=ipaddress.99="
nvram set static_leasenum="7"
nvram set sshd_wanport="22"
nvram set sshd_port="22"
nvram set sshd_passwd_auth="1"
nvram set sshd_forwarding="0"
nvram set sshd_enable="1"

nvram set router_name="robotname"
nvram set rc_startup="ifconfig ath0 down
ifconfig ath1 down"
nvram set rc_shutdown=""
nvram set rc_firewall="iptables -I INPUT 1 -p udp --dport 5060 -j ACCEPT
iptables -I FORWARD 1 --source 217.10.64/20 -j ACCEPT
iptables -I INPUT 1 -p udp --dport 1194 -j ACCEPT
iptables -I FORWARD 1 --source 10.0.3.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -o br0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -j MASQUERADE
iptables -I FORWARD -i br0 -o tun1 -j ACCEPT
iptables -I FORWARD -i tun1 -o br0 -j ACCEPT
iptables -t nat -I POSTROUTING -o tun1 -j MASQUERADE
iptables -I INPUT 1 -i tun1 -p tcp --dport 53 -j ACCEPT
iptables -I INPUT 1 -i tun1 -p udp --dport 53 -j ACCEPT"
nvram set openvpncl_upauth="0"
nvram set openvpncl_tuntap="tun"
nvram set openvpncl_remoteport="1194"
nvram set openvpncl_remoteip="vpn.mojin-robotics.de"
nvram set openvpncl_proto="udp"
nvram set openvpncl_lzo="adaptive"
nvram set openvpncl_key="###PRIV-CLIENT-CERT###"
nvram set openvpncl_enable="1"
nvram set openvpncl_config="route 217.10.64.0 255.255.240.0
route 217.116.112.0 255.255.240.0
route 212.9.32.0 255.255.255.224"
nvram set openvpncl_client="###PUB-CLIENT-CERT###"
nvram set openvpncl_cipher="aes-256-cbc"
nvram set openvpncl_certtype="0"
nvram set openvpncl_ca="###CA-CERT###"
nvram set openvpncl_bridge="0"
nvram set openvpncl_auth="sha512"
nvram set openvpncl_adv="1"

nvram set ntp_server="de.pool.ntp.org"
nvram set ntp_mode="auto"
nvram set ntp_enable="1"
nvram set ntp_done="1"
nvram set local_dns="1"

nvram set language="english"
nvram set lan_stp="0"
nvram set lan_proto="dhcp"
nvram set lan_netmask="255.255.255.0"
nvram set lan_lease="86400"
nvram set lan_ipaddr="ipaddress.1"
nvram set lan_gateway="0.0.0.0"
nvram set lan_domain="robotname"

nvram set expert_mode="1"

nvram set dnsmasq_strict="0"
nvram set dnsmasq_options="interface=br0,tun1
no-dhcp-interface=tun1
server=/wlrob.net/10.0.1.1
dhcp-option=15,\"robotname\""
nvram set dnsmasq_no_dns_rebind="0"
nvram set dnsmasq_enable="1"
nvram set dnsmasq_add_mac="0"
nvram set dns_redirect="0"
nvram set dns_dnsmasq="1"
nvram set dhcp_start="100"
nvram set dhcp_num="50"
nvram set dhcp_lease="1440"
nvram set dhcp_domain="lan"
nvram set dhcp_dnsmasq="1"

nvram set block_wan="1"
nvram set block_snmp="1"
nvram set block_proxy="0"
nvram set block_multicast="1"
nvram set block_loopback="0"
nvram set block_java="0"
nvram set block_ident="1"
nvram set block_cookie="0"
nvram set block_activex="0"

nvram set auth_dnsmasq="1"

nvram set ath2_mode="sta"
nvram set ath2_wpa_psk="care-o-bot"
nvram set ath2_ssid="cob-extern"
nvram set ath2_security_mode="psk2"
nvram set ath2_regulatory="1"
nvram set ath2_regdomain="GERMANY"
nvram set ath2_radio="1"
nvram set ath2_protmode="None"
nvram set ath2_net_mode="acn-mixed"
nvram set ath2_nctrlsb="Auto"
nvram set ath2_nband="1"
nvram set ath2_nat="1"

nvram set ath2_crypto="aes"
nvram set ath2_bridged="1"
nvram set ath2_br1_netmask="255.255.255.0"
nvram set ath2_akm="psk2"

nvram set ath1_wpa_psk="care-o-bot"
nvram set ath1_ssid="robotname-direct"
nvram set ath1_security_mode="psk2"
nvram set ath1_regulatory="1"
nvram set ath1_regdomain="GERMANY"
nvram set ath1_radio="1"
nvram set ath1_net_mode="mixed"
nvram set ath1_nctrlsb="Auto"
nvram set ath1_crypto="aes"
nvram set ath1_akm="psk2"

nvram set ath0_wpa_psk="care-o-bot"
nvram set ath0_ssid="robotname-direct"
nvram set ath0_security_mode="psk2"
nvram set ath0_regulatory="1"
nvram set ath0_regdomain="GERMANY"
nvram set ath0_radio="1"
nvram set ath0_net_mode="mixed"
nvram set ath0_nctrlsb="Auto"
nvram set ath0_akm="psk2"

# Commit variables
echo "Save variables to nvram"
nvram commit
