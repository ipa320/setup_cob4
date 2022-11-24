<a id="top"/>
# cob4 Administrator manual

### Contents
1. <a href="#Administrator-Manual">Administrator manual</a>
     1. <a href="#Network">Network setup</a>
     2. <a href="#New-Users">Create new user accounts</a>
     3. <a href="#Backup-Restore">Backup and restore the entire system</a>


### Administrator Manual <a id="Administrator-Manual"/>

#### 1. Network setup <a id="Network"/>

Inside the robot there’s a router which connects the pcs and acts as gateway to the building network. Setup the router with the following configuration.
The ip address of the router should be 10.4.X.1 and for the internal network dhcp should be activated. Use cob4-X as hostname for the router. Register the
MAC addresses of the pcs that they get a fixed ip address over dhcp.

| Hostname      | IP            |
| ------------- |:-------------:|
| cob4-X-b1     | 10.4.X.11     |
| cob4-X-t1     | 10.4.X.21     |
| cob4-X-t2     | 10.4.X.22     |
| cob4-X-t3     | 10.4.X.23     |
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

#### 2. Create new user accounts <a id="New-Users"/>

Due to the fact that all users need to be in the correct user groups, that the bash environment needs to be setup correctly and that user ids need to be synchronised between all pcs for the NFS to work, we facilitate the creation of a new user with a cobadduser script:
```
cobadduser new_user_name
```

#### 3. Backup and restore the entire system <a id="Backup-Restore"/>

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

<a href="#top">top</a>
