#!/bin/bash

function logFile {
    touch /root/kickstart_log
    $1 >> /root/kickstart_log
}

function printHeader {
    echo "#############################################"
    echo "Execute Kickstart-Function: $1"
    echo "---------------------------------------------"
}

function SetLocalAptCacher {
    printHeader "SetLocalAptCacher"
    unset http_proxy
    touch /etc/apt/apt.conf.d/01proxy

    SERVERNAME=$(echo ${HOSTNAME%-*}-b1)
    if grep -q 'Acquire::http { Proxy "http://10.0.1.1:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        echo "Proxy already in /etc/apt/apt.conf.d/01proxy, skipping SetLocalAptCacher"
    fi 
    if grep -q 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        rm /etc/apt/apt.conf.d/01proxy
        touch /etc/apt/apt.conf.d/01proxy
        echo 'Acquire::http { Proxy "http://10.0.1.1:3142"; };' >>  /etc/apt/apt.conf.d/01proxy
    else
        echo 'Acquire::http { Proxy "http://10.0.1.1:3142"; };' >>  /etc/apt/apt.conf.d/01proxy
    fi
}

# kernel 4.13 supports realsense no need to patch kernel.
# package needs to be installed manually for now
function BlockRealsensePackage {
    if [ "$DISTRO" == "xenial" ]; then
        apt-mark hold ros-kinetic-librealsense
        apt-mark hold ros-kinetic-realsense-camera
    fi
}

function AddGnomePPA {
    printHeader "AddGnomePPA"
    add-apt-repository ppa:gnome3-team/gnome3 -y
    apt-get update
}

function EnableAptSources {
    printHeader "EnableAptSources"
    sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
    apt-get update
}

function UpgradeAptPackages {
    printHeader "UpgradeAptPackages"
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
}

# TODO: fxm
function UpgradeKernel {
    printHeader "UpgradeKernel"
    if [ "$DISTRO" == "trusty" ]; then
        apt-get install --install-recommends linux-generic-lts-xenial -y --allow
    fi
}

function InstallHWEnableStacks {
    printHeader "InstallHWEnabledStacks"
    if [ "$DISTRO" == "trusty" ]; then
        apt-get install --install-recommends linux-generic-lts-xenial xserver-xorg-core-lts-xenial xserver-xorg-lts-xenial xserver-xorg-video-all-lts-xenial xserver-xorg-input-all-lts-xenial libwayland-egl1-mesa-lts-xenial -y
        dpkg-reconfigure xserver-xorg-lts-xenial
    fi
}

function NFSSetup {
    printHeader "NFSSetup"
    if [ "$INSTALL_TYPE" == "master" ]; then
        apt-get install nfs-kernel-server nfs-common autofs -y
        if grep -q "/home /u none bind 0 0" /etc/fstab && grep -q "/u *(rw,fsid=0,sync,no_subtree_check)" /etc/exports ; then
            echo "NFS setup already in /etc/fstab or /etc/exports, skipping NFSSetup for master"
        else
            echo "/home /u none bind 0 0" >> /etc/fstab
            echo "/u *(rw,fsid=0,sync,no_subtree_check)" >> /etc/exports
        fi
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        apt-get install nfs-common autofs -y
        HOSTNAME=$(cat /etc/hostname)

        SERVERNAME=$(echo ${HOSTNAME%-*}-b1)
        echo $SERVERNAME
        touch /etc/auto.direct
        if grep -q "/u  -fstype=nfs4    $SERVERNAME:/" /etc/auto.direct && grep -q "/-  /etc/auto.direct" /etc/auto.master ; then
            echo "NFS setup already in /etc/auto.direct or /etc/auto.master, skipping NFSSetup for slave"
        else
            echo "/u  -fstype=nfs4    $SERVERNAME:/" >> /etc/auto.direct
            echo "/-  /etc/auto.direct" >> /etc/auto.master
        fi
        update-rc.d autofs defaults
        service autofs restart
        modprobe nfs
    fi
}

function AddUsers {
    printHeader "AddUsers"

    #add robot-local user (preseedd seems to have a bug adding the user before postscript execution, results in overwritten group and user ids)
    useradd -b /home -d /home/robot-local -m -s /bin/bash -k /etc/skel robot-local
    echo 'robot-local:$1$.8rMo3Kc$hwkXrTTshYmLa9iplJchz.' | chpasswd -e

    #Give robot-local full sudo rights
    if grep -q "robot-local ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ; then
        echo "found robot-local NOPASSWD in sudoers already, skipping GiveFullRights to robot-local"
    else
        echo "robot-local ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi

    if [ "$INSTALL_TYPE" == "master" ]; then      

        #Add robot user
        mkdir /u
        mount --bind /home /u
        useradd -b /u -d /u/robot -m -s /bin/bash -k /etc/skel robot
        echo 'robot:$1$.8rMo3Kc$hwkXrTTshYmLa9iplJchz.' | chpasswd -e
    fi
    #Give robot user full rights for sudo
    if grep -q "robot ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ; then
        echo "found robot NOPASSWD in sudoers already, skipping GiveFullRights to robot"
    else
        echo "robot ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

function InstallROS {
    printHeader "InstallROS"
    if grep -q "deb http://packages.ros.org/ros/ubuntu $DISTRO main" /etc/apt/sources.list.d/ros-latest.list ; then
        echo "Ros sources already setup. Skipping setup"
    else
        echo "deb http://packages.ros.org/ros/ubuntu $DISTRO main" > /etc/apt/sources.list.d/ros-latest.list
        apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
    fi

    apt-get update
    apt-get install ros-kinetic-ros-base -y
    apt-get install python-rosinstall python-rosinstall-generator python-wstool -y
    apt-get install python-catkin-tools -y
    apt-get install python-pip -y
}

function SetupGrubRecFail {
    printHeader "SetupGrubRecFail"
    if grep -q GRUB_RECORDFAIL_TIMEOUT= /etc/default/grub ; then
        echo "found GRUB_RECORD_FAIL flag already, skipping SetupGrubRecFail (update-grub call)"
    else
        echo "GRUB_RECORDFAIL_TIMEOUT=2" >> /etc/default/grub
        update-grub
    fi
}

#TODO: requires user input - No working solution found so far
function KeyboardLayout {
    printHeader "KeyboardLayout"
    L='de' && sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$L'\"/g' /etc/default/keyboard
    apt-get install console-data -y -f
    dpkg-reconfigure keyboard-configuration
}

function ConfigureSSH {
    printHeader "ConfigureSSH"
    apt-get install openssh-server -y

    if grep -q "X11Forwarding" /etc/ssh/sshd_config; then
        sed -i 's/X11Forwarding.*$/X11Forwarding yes/g' /etc/ssh/sshd_config
    else
        echo "X11Forwarding yes" >> /etc/ssh/sshd_config
    fi
    if grep -q "X11UseLocalhost" /etc/ssh/sshd_config; then
        sed -i 's/X11UseLocalhost.*$/X11UseLocalhost no/g' /etc/ssh/sshd_config
    else
        echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
    fi
    if grep -q "PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i 's/PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin yes">> /etc/ssh/sshd_config
    fi
    if grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
        sed -i 's/ClientAliveInterval.*$/ClientAliveInterval 60/g' /etc/ssh/sshd_config
    else
        echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
    fi
    
    systemctl restart ssh
}

function ChronySetup {
    printHeader "ChronySetup"
    apt-get install chrony -y -f
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /etc/chrony/chrony.conf https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/chrony_server

    elif [ "$INSTALL_TYPE" == "slave" ]; then
        HOSTNAME=$(cat /etc/hostname)
        SERVERNAME=$(echo ${HOSTNAME%-*}-b1)
        wget -O /etc/chrony/chrony.conf https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/chrony_client
        sed -i "s/server_ip/${SERVERNAME}/g" /etc/chrony/chrony.conf
    fi
}

#udev rules
function SetupUdevRules {
    printHeader "SetupUdevRules"
    wget -O /etc/udev/rules.d/98-led.rules https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/98-led.rules
    if [ "$INSTALL_TYPE" == "master" ]; then
            wget -O /etc/init.d/udev_cob.sh https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/udev_cob.sh
            chmod +x /etc/init.d/udev_cob.sh
            update-rc.d udev_cob.sh defaults
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        wget -O /etc/udev/rules.d/99-gripper.rules https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/99-gripper.rules
    fi
}

function InstallGitLFS {
    printHeader "InstallGitLFS"
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
    apt-get install git-lfs
}

function SetupDefaultBashEnv {
    printHeader "SetupDefaultBashEnv"
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /etc/cob.bash.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/cob.bash.bashrc.b

    elif [ "$INSTALL_TYPE" == "slave" ]; then
        ROBOT=$(echo ${HOSTNAME%-*})
        if [[ "$HOSTNAME" == "$ROBOT-t"* ]]; then
            wget -O /etc/cob.bash.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/cob.bash.bashrc.t
        fi

        if [[ "$HOSTNAME" == "$ROBOT-h"* ]]; then
            wget -O /etc/cob.bash.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/cob.bash.bashrc.h
        fi

        if [[ "$HOSTNAME" == "$ROBOT-s"* ]]; then
            wget -O /etc/cob.bash.bashrc https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/cob.bash.bashrc.s
        fi
    fi
}

function InstallShutdown {
    printHeader "InstallShutdown"
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /usr/sbin/cob-shutdown https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/cob-shutdown
        chmod +x /usr/sbin/cob-shutdown
        #todo kinetic
        sed -i 's/etc\/acpi\/powerbtn.sh/usr\/sbin\/cob-shutdown/g' /etc/acpi/events/powerbtn
        if grep -q  "%users ALL=NOPASSWD:/usr/sbin/cob-shutdown" /etc/sudoers ; then
            echo "NOPASSWD already for all users in /usr/sbin/cob-shutdown, skipping InstallShutdown"
        else
            echo "%users ALL=NOPASSWD:/usr/sbin/cob-shutdown" >> /etc/sudoers
        fi
    fi
}

# TODO: warum ausloggen???
function NetworkSetup {
    printHeader "NetworkSetup"
    INTERFACE=`ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`

    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /etc/network/interfaces.backup https://raw.githubusercontent.com/ipa-bnm/setup_cob4/feature/xenial_unattended/cob-pcs/networkInterfacesMaster
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        wget -O /etc/network/interfaces.backup https://raw.githubusercontent.com/ipa-bnm/setup_cob4/feature/xenial_unattended/cob-pcs/networkInterfacesSlave
    fi

    sed -i "s/eth0/$INTERFACE/g" /etc/network/interfaces.backup

    echo "mv /etc/network/interfaces.backup /etc/network/interfaces && ifup -a && sed -i '/fixnet.sh/d' /etc/rc.local && rm -f /fixnet.sh" > /fixnet.sh
    sed -i '$ibash /fixnet.sh' /etc/rc.local
    systemctl restart networking
}

function SetupEtcHosts {
    printHeader "SetupEtcHosts"
    HOSTNAME=$(cat /etc/hostname)

    sed -i "s/$HOSTNAME.wlrob.net\t//g" /etc/hosts

    ROBOTNAME=$(echo ${HOSTNAME%-*})
    ROBOT_NUM=$(echo ${ROBOTNAME##*-})

    PC_LS=(
    "10.4.${ROBOT_NUM}.41	${ROBOTNAME}-h1"
    "10.4.${ROBOT_NUM}.31	${ROBOTNAME}-s1"
    "10.4.${ROBOT_NUM}.23	${ROBOTNAME}-t3"
    "10.4.${ROBOT_NUM}.22	${ROBOTNAME}-t2"
    "10.4.${ROBOT_NUM}.21	${ROBOTNAME}-t1"
    "10.4.${ROBOT_NUM}.11	${ROBOTNAME}-b1"
    )

    for ((i = 0; i < ${#PC_LS[@]}; i++))
    do
    if ! [[ ${PC_LS[$i]} == *${HOSTNAME}* ]]; then
        sed -i "4i ${PC_LS[$i]}" /etc/hosts
    fi
    done

    sed -i $'8 a \n' /etc/hosts
}

function InstallCandumpTools {
    printHeader "InstallCandumpTools"
    wget -O /usr/local/bin/socket_buffer.py https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/socket_buffer.py
    chmod +x /usr/local/bin/socket_buffer.py
}

#TODO: only newest NoMachine ?!?
function InstallNoMachine {
    printHeader "InstallNoMachine"
    NOMACHINE_VERSION=6.0.66_2
    wget -O /root/nomachine_${NOMACHINE_VERSION}_amd64.deb http://download.nomachine.com/download/6.0/Linux/nomachine_${NOMACHINE_VERSION}_amd64.deb
    dpkg -i /root/nomachine_${NOMACHINE_VERSION}_amd64.deb
}

function InstallNetData {
    printHeader "InstallNetData"
    apt-get install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl -y
    git clone https://github.com/firehol/netdata.git --depth=1 /root/netdata
    cd /root/netdata
    yes | ./netdata-installer.sh
    cd
    rm -r /root/netdata
}

function InstallCobCommand {
    printHeader "InstallCobCommand"
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /usr/sbin/cob-command https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/cob-command
        chmod +x /usr/sbin/cob-command
        sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers
    fi
}

function RemoveModemanager {
    printHeader "RemoveModemanager"
    apt-get purge modemmanager -y
}

function DisableUpdatePopup {
    printHeader "DisableUpdatePopup"
    sed -i 's/Prompt\=lts/Prompt\=never/g' /etc/update-manager/release-upgrades
}

# TODO: fxm ;)
# Not functional under xenial
function DisableFailsafeBoot {
    printHeader "DisableFailsafeBoot"
    sed -i 's/start on \(filesystem and static-network-up\) or failsafe-boot/start on filesystem and static-network-up/g' /etc/init/rc-sysinit.conf
}

function InstallAptCacher {
    printHeader "InstallAptCacher"
    #disable local forward to 10.0.1.1 cacher
    if grep -q 'Acquire::http { Proxy "http://10.0.1.1:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        rm /etc/apt/apt.conf.d/01proxy
    fi
    if grep -q 'Acquire::http::Proxy "http://10.0.1.1:3142/";' /etc/apt/apt.conf ; then
        sed -i 's!Acquire::http::Proxy "http://10.0.1.1:3142/";!!g' /etc/apt/apt.conf
    fi

    HOSTNAME=$(cat /etc/hostname)
    SERVERNAME=$(echo ${HOSTNAME%-*}-b1)
    if [ "$INSTALL_TYPE" == "master" ]; then
        apt-get install apt-cacher-ng -y
        sed -i 's/\# PassThroughPattern: .\*/PassThroughPattern: .\*/g' /etc/apt-cacher-ng/acng.conf
        systemctl restart apt-cacher-ng
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        touch /etc/apt/apt.conf.d/01proxy

        if grep -q 'Acquire::http { Proxy "http://10.0.1.1:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
            rm /etc/apt/apt.conf.d/01proxy
            touch /etc/apt/apt.conf.d/01proxy
        fi
        if grep -q 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' /etc/apt/apt.conf.d/01proxy ; then
            echo "Proxy already in /etc/apt/apt.conf.d/01proxy, skipping InstallAptCacher"
        else
            echo 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' >>  /etc/apt/apt.conf.d/01proxy
        fi
    fi
}

function InstallRealsense {
    printHeader "InstallRealsense"
    if [ "$DISTRO" == "xenial" ]; then
        echo 'deb http://realsense-hw-public.s3.amazonaws.com/Debian/apt-repo xenial main' | tee /etc/apt/sources.list.d/realsense-public.list
        apt-key adv --keyserver keys.gnupg.net --recv-key 6F3EFCDE
        apt-get update
        apt-get install realsense-uvcvideo -y
        apt-get install ros-kinetic-librealsense -y
        apt-get install ros-kinetic-realsense-camera -y
    fi
}

function InstallCareOBot {
    printHeader "InstallCareOBot"
    apt-get install ros-kinetic-care-o-bot-robot -y
}

function FinishKickstartRobot {
    printHeader "FinalizeKickstartRobot"
    touch /var/log/installer/kickstart_robot_finished
}

########################################################################
############################# INITIAL MENU #############################
########################################################################

if [ $# -ne 2 ]; then
    echo "ERROR: wrong number of arguments, expecting:"
    echo "kickstart-robot.sh [master|slave] [xenial|trusty]"
    exit 1
fi

if [ "$1" != "master" ] && [ "$1" != "slave" ]; then
    echo "ERROR: please provide argument [master|slave] [xenial|trusty]. Got: $1 $2"
    exit 2
elif [ "$2" != "xenial" ] && [ "$2" != "trusty" ]; then
    echo "ERROR: please provide argument [master|slave] [xenial|trusty]. Got: $1 $2"
    exit 2
else
    INSTALL_TYPE=$1
    DISTRO=$2
    echo "Starting kickstart robot - using install type: $INSTALL_TYPE for distro $DISTRO"
fi

if [ ! -z "$http_proxy" ]; then
    echo "http_proxy is set from preseed. Unsetting and setup apt cacher"
    unset http_proxy
    SetLocalAptCacher
fi
AddGnomePPA
BlockRealsensePackage
EnableAptSources
UpgradeAptPackages
UpgradeKernel
InstallHWEnableStacks
NFSSetup
AddUsers
InstallROS
SetupGrubRecFail
KeyboardLayout
ConfigureSSH
ChronySetup
SetupUdevRules
InstallGitLFS
SetupDefaultBashEnv
InstallShutdown
NetworkSetup
SetupEtcHosts
InstallCandumpTools
InstallNoMachine
InstallNetData
InstallCobCommand
RemoveModemanager
DisableUpdatePopup
#DisableFailsafeBoot
InstallRealsense
InstallCareOBot
InstallAptCacher
FinishKickstartRobot
