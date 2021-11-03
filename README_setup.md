# StickSetup and PostInstall Manual

## Contents

1. [Initial Situation](#init_sit)
2. [Preparations](#prep)
3. [StickSetup](#stick)
4. [RouterSetup](#router)
5. [PostInstall](#postinstall)
6. [Calibration](#calibration)
7. [Verification](#verification)


## Initial Situation <a name="init_sit"></a>
This manual describes the steps required for the initial setup of a Care-O-bot.  
Starting point is a new robot hardware coming out of production.  
This robot has already passed all [component tests](https://github.com/mojin-robotics/cob_hardware_test/blob/indigo_dev/cob_test_rigs/README.md) as well as all [devices tests](https://github.com/mojin-robotics/cob_hardware_test/blob/indigo_dev/cob_devices_test/README.md).  

This manual describes the setup steps for a `cob_robots` research robot.  

## Preparations <a name="prep"></a>
Make sure you have the following available:  
 - Robot is connected to power (either charging cable or charging station)  
 - USB-Stick containing the latest StickSetup  
   StickSetup is available for Focal/Noetic setups.  
   FXM can prepare this for you or follow [BootStick Tutorial](https://github.com/ipa320/setup_cob4/blob/master/images_config/README.md).  
 - Setup Cart or Peripheral Devices  
   including display + adapter, mouse, keyboard, USB-Hub, network cable
 - Internet Access via Network Cable
 - Software (config and launch files) for the new robot (Bringup Layer)  
   including `cob_supported_robots`, `cob_calibration_data`, `cob_robots`
 - For laser calibration: laser scanner calibration devices (two parts)
 - For base calibration: mechanic's level or long wooden slat
 - For camera calibration: a checkerboard (10x6)

## StickSetup <a name="stick"></a>
This step has to be performed for each PC of Care-O-bot respectively:  
 - Base PC: `b1`
 - Torso PC: `t1`, `t2`, `t3`
 - Head PC: `h1`

 1. Connect the Setup Cart or Peripheral Devices to the current PC.
 2. (Re-)Start the PC.  
    Note: PC does **not** start automatically (`PowerOn`) until BIOS settings are adjusted
 3. Press `F2` (and hold) to enter BIOS and [Configure BIOS](https://github.com/mojin-robotics/cob4/blob/groovy_dev/BIOS_settings.md)
 4. Insert the BootStick with the latest StickSetup
 5. (Re-)Start the PC.
 6. Press `F10` (and hold) to enter BootMenu and select the BootStick with the prefix `UEFI: ...` (the partition is not relevant)
 7. Continue with `ENTER` in grub menu
 8. The StickSetup will start with a sanity check first. Then it stops in a prompt asking for additional info:
 9. Specify `hostname` (e.g. `b1`) and confirm with `ENTER`
 10. Hit `ENTER` to confirm standard passwort (alternatively type desired password for `robot-local`)
 11. Select `InstallType`:
   - Master option (insert `master`) for `b1`
   - Slave option (insert `slave`) for all other `t1`, `t2`, `t3`, `h1`
 12. The StickSetup now continues with the actual Unattended Installation...this might take a while...
 13. The PC will reboot after the StickSetup is done and pause again in the grub menu from step 7.  
     Remove the BootStick and restart with `CTRL` + `ALT` + `ENTF` (***DO NOT PRESS ENTER!***)
 14. Let the PC reboot from the internal drive, then continue with the next PC.

**Finally**, the robot should be powered down completely and restarted before continuing with the next step.

## RouterSetup <a name="router"></a>
This step is required to setup the required internal network architector of the robot.  
First, make sure all routers and switches use the correct firmware version and are configured correctly.
See also: [Router einrichten](https://github.com/ipa320/setup_cob4/blob/master/manual_administrator/README_ddwrt.md)

Once the router and switches are configured correctly via the provided scripts, two more things need to be done:
 - configure static leases (fixed IP addresses) for the PCs and the Flexisoft:  
   - Log in to the Torso switch (`10.4.XX.1`)
   - Find the MAC addresses for the PCs and the Flexisoft under `Status->LAN` at the bottom under `DHCP Clients`
   - Copy the MAC addresses and paste them into the respective placeholders under `Services` under `Static Leases`
   - Save and Apply Settings
   - Hints:
     - It's best to have both pages (Status and Services) in separate browser windows
     - The MAC address of the Flexisoft is the one with the Hostname `*`
 - configure VPN access - optional  
   See also: [Setup VPN](https://github.com/ipa320/setup_cob4/blob/master/manual_administrator/README_Openvpn.md)

Finally, the robot should be powered down completely and restarted before continuing with the next step.

## PostInstall <a name="postinstall"></a>
With the OS being installed on the PCs and the network set up, various `PostInstall` steps will finalize the Care-O-bot setup.
It is recommended to execute the `PostInstall` steps one-by-one!

To run `PostInstall`:
 - Connect to the robots WLAN `cob4-XX-direct`
 - Log in to `b1` as `robot` user via `ssh -XC robot@10.4.XX.11`
 - Execute `PostInstall` script via `/u/robot/git/setup_cob4/PostInstallCob4.sh`

Before presenting the `PostInstall` steps, the script will ask you to update the repository.  
In case the robot has been setup afresh, this step can be skipped by pressing `n` and then `ENTER`.

Several times during the `PostInstall` steps you will be asked to confirm the `PC_LIST`, like so:
```
INFO:QUERY_PC_LIST

 PC_LIST: b1 t1 t2 t3 h1 

Do you want to use the suggested pc list (y/n)?
```
Please make sure all six PCs occur in the list before confirming with `y` and then `ENTER` - otherwise one of the PCs might not be reachable through the network!


The `PostInstall` menu looks like this:
```
===========================================
                INITIAL MENU
===========================================
INFO: This script is a helper tool for the setup and installation of Care-O-bot: 
 1. Setup root user
 2. Setup robot user
 3. Setup mimic user
 4. Setup devices (e.g. udev for laser scanners)
 5. Install system services (upstart, ...)
 9. SyncPackages
 99. Full installation

Please select an installation option: 
```

**Please execute the steps one by one.
In the following, hints are provided for each of the steps:**

1. `Setup root user` <a name="postinstall_root"></a>
   - Confirm `CLIENT LIST`
   - Enter `root` password when asked (several times), i.e. default robot password
   - Step is done successfully when `SETUP ROOT USER DONE!` is shown

2. `Setup robot user` <a name="postinstall_robot"></a>
   - Confirm `CLIENT LIST`
   - Enter `yes` (several times) when asked to accept SSH fingerprint
   - Specify `ROBOT_ENV`, e.g. `ipa-apartment`
   - Enter `robot` password when asked (several times), i.e. default robot password
   - Upload the ssh key to github:  
     - Confirm with `y` and then `ENTER`
     - Enter a github user name and respective github user password
   - Upload the ssh key to the router:  
     - Confirm with `y` and then `ENTER`
     - Accept SSH fingerprint with `yes` and then `ENTER`
     - Enter password for the **router's** `root` user
   - Step is done successfully when `SETUP ROBOT USER DONE!` is shown

3. `Setup mimic user` <a name="postinstall_mimic"></a>
   - Confirm `CLIENT LIST` - this time it only shows `h1`
   - Enter default `mimic` user password and confirm
   - Specify `ROBOT_ENV`, e.g. `ipa-apartment`
   - Enter `yes` (several times) when asked to accept SSH fingerprint
   - Upload the ssh key to github is **not** needed
   - Upload the ssh key to the router is **not** needed
   - Step is done successfully when `SETUP MIMIC USER DONE!` is shown

4. `Setup devices` <a name="postinstall_devices"></a>
   - Step is done successfully when `SETUP DEVICES DONE!` is shown

5. `Install system services` <a name="postinstall_system"></a>
   - Confirm `CLIENT LIST`
   - Select `UPSTART CONFIGURATION` from the menu:
     ```
     INFO: The following upstart variants are available: 
      0. skip (do not update upstart configuration)
      1. cob_bringup
      2. custom upstart (specify path to yaml)
     
     Please select an upstart option:
     ```
   - Confirm `CLIENT LIST` (all six PCs), `CHECK CLIENT LIST` (should be empty)
   - Step is done successfully when `INSTALL SYSTEM SERVICES DONE!` is shown

9. `Sync Packages`
   - Select **option 1** from the menu:
     ```
     Available options: 
      1. Upgrade Master + Sync 
      2. Specify InstallFiles (debian and pip) + Sync 
     
     Please select a sync option: 
     ```
   - Confirm the `install files` with `y`, then `ENTER`
     ```
     DPKG_FILE: /u/robot/git/setup_cob4/cob-pcs/dpkg_installed_$ROS_DISTRO.txt
     PIP_FILE: /u/robot/git/setup_cob4/cob-pcs/pip_installed_$ROS_DISTRO.txt
     
     Do you want to use the install files (y/n)?
     ```
   - The sync process will take a while (several minutes)
   - You will see the following for each of the six PCs
     ```
     -------------------------------------------
     Installing packages on XX
     -------------------------------------------
     
     ----> executing: curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash > /dev/null
     ----> executing: sudo apt-get update > /dev/null
     ----> executing: sudo apt-get -qq install -y --allow-downgrades --allow-unauthenticated account-plugin-aim=3.12.11-0ubuntu3
     ----> executing: sudo apt-get autoremove -y > /dev/null
     
     ----> executing: sudo -H pip install --force-reinstall -r /u/robot/git/setup_cob4/cob-pcs/pip_installed_$ROS_DISTRO.txt > /dev/null
     You are using pip version 8.1.1, however version 19.0.3 is available.
     You should consider upgrading via the 'pip install --upgrade pip' command.
     ```
   - Step is done successfully when `SYNC PACKAGES DONE!` is shown

---

## Calibration <a name="calibration"></a>
 - Rotate Head Display
   - Plug in a mouse to Head-PC `h1`
   - Rotate the `Display` clockwise by 90° in the system settings
 - [Calibrate Laserscanners](https://github.com/mojin-robotics/cob4/blob/groovy_dev/CalibrationLaserscanner.md)
 - [Calibrate Base/FDMs](https://github.com/mojin-robotics/cob4/blob/groovy_dev/CalibrationFDMs.md)
 - [Calibrate HeadCam](https://github.com/mojin-robotics/cob4/blob/groovy_dev/CalibrationHeadCam.md)
 - Calibrate the 3D sensors (`torso_cam3d_down`, `torso_cam3d_left`, `torso_cam3d_right`, `sensorring_cam3d`)
   - Visualize the respective `depth/points` topic in `rviz`
   - Slightly adjust the mount positions parameters (`x`, `y`, `z`, `roll`, `pitch`, `yaw`) in `calibration_offset.urdf.xacro` in the `cob_calibration_data` package to allign the sensors and properly filter noise, e.g. from the floor

## Verification <a name="verification"></a>
 - check `robot_status`: `rostopic echo /robot_status`
 - check diagnostics: `rosrun rqt_robot_monitor rqt_robot_monitor`
 - check `rviz` whether sensors (scans, pointclouds, images)
