#OpenVPN Router setup

1. <a href="#Certificate">Certificate generation</a>
2. <a href="#Zentyal">Zentyal Config</a>
2. <a href="#DDWRT">DD WRT Config</a>

### 1. Certificate generation <a id="Certificate"/> 
- Open Zentyal Web Admin
- Goto Certification Authority->General
- Issue new Certificate with e.G. Common Name = cob4-X
- Goto VPN->Servers->Download client bundle
- Select Client Type and the newly generated client's certificate,
  add the VPN Servers public IP as Server address (153.97.5.93)
- Download the Certificate

### 2. Zentyal Config <a id="Zentyal"/>
- ssh to zentyal<br>
  `ssh stud-admin@10.0.1.1`
- cd directory to openvpn client config<br>
  `/etc/openvpn/cob-kitchen-vpn.d/client-config.d`
- create a new file with the excapt same name as the
  generated client ceritivates common name<br>
  `sudo vim <client cert name>`
- add the following content:
  "iroute <subnet_ip> <subnet_mask>"  without the quotes
  for example: iroute 10.4.7.0 255.255.255.0
- add new route to `/usr/share/zentyal/stubs/openvpn/openvpn.conf.mas`<br>
  `route <subnet_ip> <subnet_mask>`<br>
  e.g. `route 10.4.7.0 255.255.255.0`

### 4. DD WRT Config <a id="DDWRT"/>
open admin page and configure the follwing ddwrt settings:

#### Setup->Basic Setup:
- DNSMasq for DHCP = Enabled
- DNSMasq for DNS = Enabled
- DHCP-Authoritative = Enabled
- NTP Client = Enabled 
- NTP Client Server IP/Name = set to any NTP Server (eg. de.pool.ntp.org)

#### Services->VPN:
- Start OpenVPN Client = Enabled
- Server IP/Name = zentyals external ip
- Port = 1194
- Tunnel Device = TUN
- Tunnel Protocol = UDP
- Encryption Cipher = Blowfish
- Hash Algorithm = SHA1
- User Pass Authentication = Disabled
- Advanced Options = Enabled
- TLS Cipher = None
- LZO Compression = No
- NAT = Disabled
- IP Address = 
- Subnet Mask =
- Tunnel MTU setting = 1500
- Tunnel UDP Fragment =
- Tunnel UDP MSS-FIX = Disabled
- nsCertType verfication = Disabled
- add the following to Additional Config<br>
```
route 217.10.64.0 255.255.240.0
route 217.116.112.0 255.255.240.0
route 212.9.32.0 255.255.255.224
```
- CA Cert insert content from `cacert.pem` (downloaded in step 1)
```
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```
- Public Client Cert insert content from `1234567abc.pem`
```
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```
- Private Client Key insert content from `common_name.pem`
```
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
```
- Save Settings

#### Services->Services
- Used Domain = LAN & WLAN
- LAN Domain = Routers/Robots Domain
- DNSMasq = Enabled
- LocalDNS = Enabled
- all other DNSMasq Options are disabled
- Additional DNSMasq Options add the following lines:<br>
```
interface=br0,tun1
no-dhcp-interface=tun1
server=/ipa-apartment.org/10.0.1.1
dhcp-option=15,"ipa-apartment.org"
```
be shure to replace `tun1` with whatever index your tun interface has

#### Administration->Commands:
- add the following to Commands and click "Save Firewall"<br>
  be shure you adapt the ip addresses and interface names!!!
```
iptables -I INPUT 1 -p udp --dport 5060 -j ACCEPT
iptables -I FORWARD 1 --source 217.10.64/20 -j ACCEPT
iptables -I INPUT 1 -p udp --dport 1194 -j ACCEPT
iptables -I FORWARD 1 --source 10.0.3.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -o br0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -j MASQUERADE
iptables -I FORWARD -i br0 -o tun1 -j ACCEPT
iptables -I FORWARD -i tun1 -o br0 -j ACCEPT
iptables -t nat -I POSTROUTING -o tun1 -j MASQUERADE
iptables -I INPUT 1 -i tun1 -p tcp --dport 53 -j ACCEPT
iptables -I INPUT 1 -i tun1 -p udp --dport 53 -j ACCEPT
```
