<a id="top"/> 
# cob4 Installation

### Contents

1. <a href="#Installation">Installation</a>
2. <a href="#Administrator-Manual">Administrator manual</a>
     1. <a href="#Network">Network setup</a>
     2. <a href="#New-Users">Create new user accounts</a>
     3. <a href="#Backup-Restore">Backup and restore the entire system</a>
3. <a href="#Extra-Installation">Extra installation</a>
     1. <a href="#Hands">Hand configuration</a>
     2. <a href="#Mimic">Mimic</a>
     3. <a href="#Touch">Calibration touchscreen</a>


### 1. Installation <a id="Installation"/> 

The full Care-O-bot installation can be done using a bash script. The script is in the setup repository, get it using the following command:

```
wget https://raw.githubusercontent.com/ipa320/setup_cob4/master/InstallCob4.sh
chmod +x InstallCob4.sh
```

The installation script needs the parameters robot, ip address and installation mode, where:

 * -r robot: is the robot name (cob4-X)
 * -ip :ip address for your actual installation pc, for example *10.4.IP.11* for base pc.
 * -m installation mode: on Care-O-bot there are two different types of computers, the master pc and the slave. The master PC has a large hard disk, and works as a NFS system server, the other computers will be the clients

The script allow different types of installation:

+ **Basic Installation** It is composed by the following steps:

  * Install basic tools (vim, meld, terminator ...)
  * Install and configure openssh
  * Allow robot user to execute sudo command without password
  * Setup root user (in this step the user will be asked for a password)
  * Install ROS
  * Setup udev rules
  * Setup bash environment 

+ **Setup NTP and NFS** This option will configure the NFS system depending on the installation mode, it is important that the master pc is already installed and per network reachable before install the slave computers, otherwise the installation process will be cancelled. After this installation it is necessary restart the computer.
 
+ **Full Installation** A full installation means the combination of 1 and 2 (Basic Installation + Setup NTP and NFS)
+ **Cob setup** This step holds the recommended configuration of the robot home directory. This step can only be execute after a full installation.

### 2. Administrator Manual <a id="Administrator-Manual"/>

#### 2.1. Network setup <a id="Network"/>

Inside the robot there’s a router which connects the pcs and acts as gateway to the building network. Setup the router with the following configuration.
The ip address of the router should be 10.4.X.1 and for the internal network dhcp should be activated. Use cob4-X as hostname for the router. Register the
MAC addresses of the pcs that they get a fixed ip address over dhcp. 

| Hostname      | IP            |
| ------------- |:-------------:|
| cob4-X-b1     | 10.4.X.11     |
| cob4-X-t1     | 10.4.X.21     |
| cob4-X-t2     | 10.4.X.22     |
| cob4-X-t3     | 10.4.X.23     |
| cob4-X-s1     | 10.4.X.31     |
| cob4-X-h1     | 10.4.X.41     |

Make sure you have name resolution and access to the robot pcs from your external pc. To satisfy the ROS communication you need a full DNS and reverse DNS name lockup for all machines. Check it from your remote pc with
```
ping 10.4.X.11
ping cob4-X-b1
```
and the other way round try to ping your remote pc from one of the robot pcs
```
ping your_ip_adress
ping your_hostname
```
If ping and DNS is not setup correctly, there are multiple ways to enable access and name resolution.

#### 2.2. Create new user accounts <a id="New-Users"/>

Due to the fact that all users need to be in the correct user groups, that the bash environment needs to be setup correctly and that user ids need to be synchronised between all pcs for the NFS to work, we facilitate the creation of a new user with a cobadduser script:
```
cobadduser new_user_name
```

#### 2.3. Backup and restore the entire system <a id="Backup-Restore"/>

##### Backup

We recommended to backup your system when you have a stable software version, e.g. all hardware drivers setup and running. You can backup the whole disks of your robot to an external hard disk using the tool dd.
Be sure hat the external device hat enough free space as an ext4 partition, you can format it using gparted. With the new partition mounted in your system execute the following command:
```
sudo dd if=/dev/sdaX of=/dev/sdbY
```
where /dev/sdaX is the local partition where ubuntu is installed and /dev/sdbY is the partition where your external device is mounted. With this command you copy the whole partition, this step will take several hours depending on the disk size.

##### Restore a backup

with the following instructions you can restore your system to a previous backed up version. However you should be aware of that if backing up and restoring fails you will need to setup your system from scratch. So we only reccomend to restore your system if nothing else helps to get the system up and running again.
If you have a backup on an external hard disk you can use a CD or USB stick with live linux to restore the system with the following command:
```
sudo dd if=/dev/sdbY of=/dev/sdaX
```
where /dev/sdbY is the partition where your external device is mounted and /dev/sdaX is the local partition where you want to restore ubuntu.

### 3. Extra Installation <a id="Extra-Installation"/>

#### 3.1. Hands configuration <a id="Hands"/>

The hands use a bluetooth connection to receive the commands and send the link positions to ROS. This requires the configuration of the bluetooth devices on the hands (Raspberry pcs) and on the torso pc, also some upstart jobs are needed to launch the hand driver on boot.

##### Hand Pcs:

Add a rule (*/etc/udev/rules/98-bluetooth*) to identify the bluetooth device as a serial port:

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
Setup the bluetooth configuration (*/etc/bluetooth/rfcomm.conf*):

```
rfcomm0 {
bind yes;
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

#### 3.2. Mimic <a id="Mimic"/>

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

#### 3.3. Calibration touchscreen <a id="Touch"/>

The touchscreen driver can be found under http://zytronic.co.uk/support/downloads/# , after install the driver use the following command to invert the axis and calibrate the panel:
```
 sudo ZyConfig
```
<a href="#top">top</a>
