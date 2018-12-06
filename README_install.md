<a id="top"/>

# cob4 Installation Manual

### Contents

1. <a href="#Installation">Automatic installation</a>
2. <a href="#Extra-Installation">Extra installation</a>
     1. <a href="#Asus">Asus Xtion</a>
     2. <a href="#HandsBluetooth">Hand configuration Bluetooth</a>
     3. <a href="#HandsWlan">Hand configuration Wlan</a>
     4. <a href="#Mimic">Mimic</a>
     5. <a href="#Touch">Calibration touchscreen</a>
     6. <a href="#NetData">Netdata tool</a>
     7. <a href="#CiscoFirmware">Update CISCO Switch Firmware</a>


### 1. Automatic installation <a id="Installation"/>

The Care-O-bot pcs can be installed using a pre-created image via a bootable USB media:

1. Plug in USB to the NUC and restart the NUC, press F10 to get bootable option. For example if you are using Master USB stick in bootable option, select USB bootable mode and then the first option would be Automatically install of Care-O-bot MASTER .
2. After creating CD /DVD no need to press any keys it directly directs to bootabe options.
3. While booting per-installiting script poops up asking for host name.

Fur further information about the creation and customization of images please see the following link: [Image configuration manual](images_config/README_images.md)

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


#### 2.2. Hands configuration Bluetooth<a id="HandsBluetooth"/>

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

#### 2.3. Hands configuration Wlan<a id="HandsWlan"/>
Download raspberry image from here:
```
wget usb stick von Benni
```

Flash the raspberry image to the sd card
```
sudo dd bs=4M if=ubuntu_gripper.img of=/dev/sdX conv=fsync
```

Put the sdcard into the Raspberry and start it up.

Log into the raspberry via ssh or use mouse, tastatur and monitor.
```
ssh robot@raspberry_ip
```

Set root password
```
sudo passwd root
```

Set hostname
```
sudo vim /etc/hostname
sudo vim /etc/hosts
```

Update system time
```
sudo date --set="2018-12-06 15:30:00.000"
```

Update setup_cob4 repo (only possible if ipa320/setup_cob4 is updated)
```
cd git/setup_cob4
git fetch origin
git merge origin/master
```

Copy cob-hand.service to /etc/systemd/system
```
sudo cp cob-hand.service /etc/systemd/system
```

Replace my_component_name with correct name inside the systemd unit. Eg. gripper_left or gripper_right
```
sudo vim /etc/systemd/system/cob-hand.service
```

And enable the service with the command:
```
cd /etc/systemd/system
sudo systemctl enable cob_hand.service
```

Set ip to base pc's address inside chrony config.
```
cd
sudo vim /etc/chrony/chrony.conf

server 10.4.x.11 minpoll 0 maxpoll ....
```

Modify bashrc
```
vim .bashrc

export ROBOT=cob4-x
export ROBOT_ENV=xxx
export ROS_MASTER_URI=http://10.4.x.11:11311
```

Network wifi setup:
- put the following to /etc/network/interfaces
```
auto wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```
- put the connection details into /etc/wpa_supplicant/wpa_supplicant.conf
```
country=DE

network={
    ssid="cob4-x-direct"
    psk="care-o-bot"
}
```
- remove the network-manager
```
sudo apt-get remove network-manager
```

Log into base pc and copyid from base to gripper
```
ssh-copy-id hostname
```

ssh to other pcs on the robot
```
ssh b1
ssh t1
ssh t2
ssh t3
ssh s1
ssh h1
ssh 10.4.x.11
ssh 10.4.x.21
ssh 10.4.x.22
ssh 10.4.x.23
ssh 10.4.x.31
ssh 10.4.x.41
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

#### 2.5. Calibration touchscreen <a id="Touch"/>

The touchscreen driver can be found under http://zytronic.co.uk/support/downloads/# , after install the driver use the following command to invert the axis and calibrate the panel:
```
 sudo ZyConfig
```
or from a remote PC:
```
export DISPLAY=:0 && sudo ZyConfig
```

#### 2.6. Netdata tool <a id="NetData"/>

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

#### 2.7. Update CISCO Switch Firmware (for old switches)<a id="CiscoFirmware"/>

Issue: http://www.viktorious.nl/2013/11/05/cisco-sg200-08-nfs/

Download latest firmware version (e.g. 1.0.8.3): https://software.cisco.com/download/release.html?mdfid=283454003&softwareid=282463182&release=1.0.5.1

Assign yourself a fixed IP adress, e.g. 192.168.1.250.

IP address cisco management: http://192.168.1.254/ (User: cisco, pw: cisco, check the manual of the switch, the address and login might change depending on the version)

Go to Administration -> File Management -> Upgrade/Backup Firmware and choose the downloaded file

This might take 10min.

<a href="#top">top</a>
