# How to use Intel NUC PC as an Internet Gateway

### 1. Prepare Intel NUC
#### Update BIOS
- Download Bios from here: https://downloadcenter.intel.com/product/70407/Intel-NUC-Kits (use the OS Independent Version)
- Copy the downloaded *.bio file to an USB Stick (should be Fat32 Formated)
- Start the NUC with the USB Stick plugged in and enter Bios by pressing F2 during the Intel Logo apears
- On the right top corner press the settings button, select bios update and choose the file on the USB Stick

#### Enable Wifi
- Check that Wifi is enabled inside the Bios settings

### 2. Update Intel Network Driver for Ubuntu
- Boot into Ubuntu
- Download Driver from here: https://downloadcenter.intel.com/download/15817/Intel-Network-Adapter-Driver-for-PCI-E-Gigabit-Network-Connections-under-Linux-
- Abhängigkeiten installieren   
  Es müssen einige Pakete installiert werden die für das Kompilieren des Treibers benötigt werden.
   ```
   sudo apt-get install build-essential linux-headers-`uname -r`
   ```
- Treiber entpacken   
   ```
   tar -zxf e1000e-3.4.0.2.tar.gz -C /tmp
   ¸¸¸
- Treiber kompilieren
   ```
   cd tmp/e1000e-1.2.8/src
   ```
- Mit "make" wird das Treibermodul kompiliert. Name des fertigen Moduls: e1000e.ko
   ```
   make
   ```
- Mit "make install" wird das Modul nach /lib/modules/`uname -r`/kernel/drivers/net/e1000e/e1000e.ko kopiert
   ```
    sudo make install
    ```
- Das Modulverzeichnis neu einlesen
   ```
   sudo depmod -a
   ```
- Das Initrd Image mit dem neuen Treiber erstellen (wichtig wenn der Treiber schon zur Bootzeit benötigt wird)
   ```
   sudo update-initramfs -u -k all
   ```
- Version des neuen Moduls prüfen
   ```
   modinfo e1000e | grep version
   ```
- Module neu laden
   ```
   sudo rmmod e1000e && sudo modprobe e1000e
   ```
   
### 3. Configure Ubuntu
#### Vlan Setup
- install vlan
   ```
   sudo apt-get install vlan
   ```
- enable 8021q module
   ```
   sudo modprobe 8021q
   ```
- make it permanent
   ```
   sudo su -c 'echo "8021q" >> /etc/modules'
   ```
#### Interfaces Setup
- Add the following lines to /etc/network/interfaces
   ```
   auto eno1.10
   iface eno1.10 inet static
     address 192.168.254.1
     netmask 255.255.255.0
     pre-up iptables-restore < /etc/iptables.sav
     vlan-raw-device eno1
   ```
- create iptables rules
   ```
   sudo iptables -A FORWARD -o wlp2s0 -i eno1.10 -s 192.168.254.0/24 -m conntrack --ctstate NEW -j ACCEPT
   sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
   sudo iptables -t nat -F POSTROUTING
   sudo iptables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE
   ```
- save iptables rules
   ```
   sudo iptables-save | sudo tee /etc/iptables.sav
   ```

### 4. Configure Switches
#### Find out witch Ports needs to be patched for vlan
Take a look at the switch and note the Port Number from the connected NUC and Router
#### Create VLan and assign it to the Ports
- Open Cisco Web Interface on Browser
- Go to "VLAN-Management -> Create VLAN" 
   Add a new VLAN with id 10 and name internet
   
![cisco_create_vlan](manual_administrator/doc/cisco_create_vlan.png)
   
- Go to "VLAN-Management -> Interface Settings"
   Select the Ports you have identified for VLAN. 
   Edit Settings, change VLAN Mode from Trunk to General
   
![cisco_interface_setting](manual_administrator/doc/cisco_interface_setting.png)
   
- Go to "VLAN-MAnagement -> Port to VLAN"
   Select VLAN id 10 on dropdown menue
   Check Member and Tagged for the identified Ports
   
![cisco_port_to_vlan](manual_administrator/doc/cisco_port_to_vlan.png)
   
- Save Settings

### 4. Router Setup
This can only be done with the new ubiquiti router. ddwrt is somehow not able to tag the wan interface with an vlan id.

- Got to Routers web page. Usally 10.4.x.1 or 192.168.1.1
- Click on Wizards and select the Basic setup wizard.
- Enter the desired information and do not forget to set VLAN id 10 for the WAN interface
- Enable dnsmasq: https://help.ubnt.com/hc/en-us/articles/115002673188-EdgeRouter-Using-dnsmasq-for-DHCP-Server
- Enable openvpn: https://mediarealm.com.au/articles/ubiquiti-edgemax-router-openvpn-client-setup/
