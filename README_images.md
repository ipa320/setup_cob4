<a id="top"/> 
# cob4 Auto-Installation with iso image 

### Contents

1. <a href="#Installation">Automatic installation with Bootable USB/CD</a>
#2. <a href="#Extra-Installation">Extra installation</a>
     #1. <a href="#Asus">Asus Xtion</a>
     #2. <a href="#Hands">Hand configuration</a>
     #3. <a href="#Mimic">Mimic</a>
     #4. <a href="#Touch">Calibration touchscreen</a>
     #5. <a href="#NetData">Netdata tool</a>


### 1. Automatic installation with Bootable USB/CD <a id="Installation"/> 

+ **Full Installation** A full installation means the combination of (Basic Installation + Setup NTP and NFS)

+ **Basic Installation** It is composed by the following steps:

  * Install basic tools (vim, meld, terminator ...)
  * Install and configure openssh
  * Allow robot user to execute sudo command without password
  * Setup root user (in this step the user will be asked for a password)
  * Install ROS
  * Setup udev rules
  * Setup bash environment 

+ **Setup NTP and NFS** 
Full installation can be done with the help of bootable USB/CD with ethernet connection.
(Note: If you're starting with a new computer (NUC) bootable CD is suggested)
Plugin the bootable USB to computer press F10 to get the menu select Master Auto installation if your using cob4 master USB , select Slave Auto installation if your using cob4 slave
In case of using bootable CD no need to press F10 it boot directly to the Master/Slave installation.

After few seconds you need to enter your hostname and press enter.

To compleate the full installation it takes some time after that its ready to use for further configuration.


### 2. Extra Installation <a id="Extra-Installation"/>

#### 2.1. Asus Xtion <a id="Asus"/>

The Asus Xtion cameras are only properly supported by USB 2.0 , it is recommended to force the bios of the Computer to disable the xHCI driver. For the NUCs (5th generation) open the bios Menu go to "Advanced" -->  Devices --> USB --> xHCI Mode and choose the option "Auto", save your configuration, boot linux and disable the usbhid module:
```
sudo rmmod  usbhid
```
And save this configuration as default:
```
sudo update-initramfs -u 
```


#### 2.2. Hands configuration <a id="Hands"/>

The hands use a bluetooth connection to receive the commands and send the link positions to ROS. This requires the configuration of the bluetooth devices on the hands (Raspberry pcs) and on the torso pc, also some upstart jobs are needed to launch the hand driver on boot. An image of the operative system can be copied to a new SD card and changing the hostname of the pc and the network configuration the hand pc is installed.

To change the hostname please modify the files */etc/hosts* and */etc/hostname* and to connect the pc to the robot router add following lines to */etc/network/interfaces*:
```
auto wlan0
iface wlan0 inet dhcp
	wpa-ssid cob4-X-direct
	wpa-psk AAAAAAAAAAAAABBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDD
```

To obtain the wpa-psk key use the command:
```
wpa_passphrase cob4-X-direct YourNetworkPassword
```

##### Hand Pcs:

Add a rule (*/etc/udev/rules/98-bluetooth.rules*) to identify the bluetooth device as a serial port:

```
KERNEL=="rfcomm*",GROUP="dialout",MODE="0666",SYMLINK+="ttyBridge"
```

Create the *cob_hand_bridge* service (*/etc/systemd/system/cob_hand_bridge.service*):
```
[Unit]
Description=Virtual Distributed Ethernet

[Service]
ExecStart=/usr/bin/rfcomm watch rfcomm0 1 cob_hand_bridge /dev/ttyBridge

[Install]
WantedBy=multi-user.target
```
And enable the service with the command:
```
sudo systemctl enable cob_hand_bridge.service
```
##### Torso Pcs:

Uninstall the modemmanager package to avoid any bluetooth interference:
```
sudo apt-get purge modemmanager
```
And add a rule (*/etc/udev/rules/99-gripper.rules*) :

```
KERNEL=="rfcomm[0-9]*", ENV{ID_MM_DEVICE_IGNORE}="1"
```
Setup the bluetooth configuration (*/etc/bluetooth/rfcomm.conf*):

```
rfcomm0 {
bind no;
device **B8:27:EB:67:31:B4**; (hand hci device address)
channel	1;
comment "Bluetooth hand right";
}
```
Add the following upstart job (*/etc/init/cob_hand.conf*):
```
# auto connect cob hand

start on started bluetooth
stop on runlevel [!2345]

respawn
respawn limit 0 10

script
  rfcomm connect rfcomm0 
end script
```

#### 2.4. Mimic <a id="Mimic"/>

The mimic should be installed on head pc. A special user "mimic" has to be created to control the display. After create the user add the following lines to */etc/lightdm/lightdm.conf* :

```
[SeatDefaults]
autologin-user=mimic
autologin-user-timeout=60
```

And also the following autostart job to */u/mimic/.config/autostart/xhost.desktop* :
```
[Desktop Entry]
Type=Application
Exec=xhost +
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=mimic
Name=mimic
Comment[en_US]=
Comment=
```

#### 2.4. Calibration touchscreen <a id="Touch"/>

The touchscreen driver can be found under http://zytronic.co.uk/support/downloads/# , after install the driver use the following command to invert the axis and calibrate the panel:
```
 sudo ZyConfig
```
or from a remote PC:
```
export DISPLAY=:0 && sudo ZyConfig
```

#### 2.5. Netdata tool <a id="NetData"/>

Install the dependencies:
```
sudo apt-get install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl
```

Install from netdata from source:
```
git clone https://github.com/firehol/netdata.git --depth=1
cd netdata
sudo ./netdata-installer.sh
```

The tool is available under the address http://*hostname*:19999

For further information take a look at the official installation guide: https://github.com/firehol/netdata/wiki/Installation

<a href="#top">top</a>
