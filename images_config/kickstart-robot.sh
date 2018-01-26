#!/bin/bash

function UpgradeAptPackages {
    apt-get upgrade -y --force-yes
}

function SetupGroup {
    if grep -q GRUB_RECORDFAIL_TIMEOUT= /etc/default/grub ; then
        echo "found GRUB_RECORD_FAIL flag already, skipping SetupGroup (update-grub call)"
    else
        echo "GRUB_RECORDFAIL_TIMEOUT=10" >> /etc/default/grub
        update-grub
    fi
}

# TODO: fxm
function UpgradeKernel {
    apt-get install --install-recommends linux-generic-lts-xenial -y --allow
}

function InstallGraphicalIface {
    apt-get install ubuntu-gnome-desktop -y
}

#TODO: fxm
function InstallHWEnableStacks {
    apt-get install --install-recommends linux-generic-lts-xenial xserver-xorg-core-lts-xenial xserver-xorg-lts-xenial xserver-xorg-video-all-lts-xenial xserver-xorg-input-all-lts-xenial libwayland-egl1-mesa-lts-xenial -y
    dpkg-reconfigure xserver-xorg-lts-xenial
}

function AddUsers {
    if [ "$INSTALL_TYPE" == "master" ]; then
        echo "session	required	pam_mkhomedir.so " >> /etc/pam.d/common-session

        # robot user
        adduser --disabled-password --gecos "" robot --home /u/robot
        echo "robot:sawVsPPn2.KXM"  | chpasswd -e
        usermod -m -d /u/robot robot
        cp -rT /etc/skel /u/robot/
        chown robot:robot /u/robot/
    fi
    # already done in seed @fxm
    # # robot-local user
    # sed -i 's/HOME=/home/HOME=/iscsi/user/g' /etc/default/useradd
    # adduser --disabled-password --gecos "" robot-local --home /home/robot-local
    # echo "robot-local:sawVsPPn2.KXM"  | chpasswd -e
    # cp -rT /etc/skel /home/robot-local
    # chown robot-local:robot-local /home/robot-local
}
#TODO password is not set correctly!!!!
function SetupRootUser {
    if grep -q "Defaults rootpw" /etc/sudoers ; then
        echo "found Defaults rootpw in sudoers already, skipping SetupRootUser"
    else
        echo "Defaults rootpw" >> /etc/sudoers
        usermod --password sawVsPPn2.KXM root 
    fi
}

function GiveFullRights {
    if grep -q "robot-local ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ; then
        echo "found robot-local NOPASSWD in sudoers already, skipping GiveFullRights to robot-local"
    else
        echo "robot-local ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi

    if grep -q "robot ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ; then
        echo "found robot NOPASSWD in sudoers already, skipping GiveFullRights to robot"
    else
        echo "robot ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

#TODO: requires user input
function KeyboardLayout {
    L='de' && sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$L'\"/g' /etc/default/keyboard
    apt-get install console-data -y -f
    dpkg-reconfigure keyboard-configuration
}

function NFSSetup {
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

function ChronySetup {
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

function ConfigureSSH {
    apt-get install openssh-server -y
    if grep -q "X11Forwarding yes" /etc/ssh/sshd_config && grep -q "X11UseLocalhost no" /etc/ssh/sshd_config && grep -q "PermitRootLogin yes" /etc/ssh/sshd_config && grep -q "ClientAliveInterval 60" /etc/ssh/sshd_config ; then
        echo "SSH config already in /etc/ssh/sshd_config, skipping editing sshd_config"
    else
        echo "X11Forwarding yes" >> /etc/ssh/sshd_config
        echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
        echo "PermitRootLogin yes">> /etc/ssh/sshd_config
        echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
    fi
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    service ssh restart
}

function SetupUdevRules {
    wget -O /etc/udev/rules.d/98-led.rules https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/98-led.rules
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /etc/init.d/udev_cob.sh https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/udev_cob.sh
        chmod +x /etc/init.d/udev_cob.sh
        update-rc.d udev_cob.sh defaults
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        wget -O /etc/udev/rules.d/99-gripper.rules https://raw.githubusercontent.com/ipa320/setup_cob4/master/udev_rules/99-gripper.rules
    fi
}

# TODO: fxm ;)
function InstallROS {
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
    apt-get update
    apt-get install ros-kinetic-ros-base -y
    apt-get install python-rosinstall python-rosinstall-generator python-wstool build-essential -y
    #apt-get install python-catkin-tools -y
    #apt-get install python-pip -y
    apt-get install ros-kinetic-care-o-bot-robot
}

function InstallGitLFS {
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
    apt-get update
    apt-get install git-lfs
}

function SetupDefaultBashEnv {
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
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /usr/sbin/cob-shutdown https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/cob-shutdown
        chmod +x /usr/sbin/cob-shutdown
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
    apt-get -y remove biosdevname -y --force-yes
    update-initramfs -u
    update-grub
    if [ "$INSTALL_TYPE" == "master" ]; then
        (
        wget -O /etc/network/interfaces https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/networkInterfacesMaster
        ) 2>&1 | /usr/bin/tee /root/post-install.log
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        (
        wget -O /etc/network/interfaces https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/networkInterfacesSlave
        ) 2>&1 | /usr/bin/tee /root/post-install.log
    fi

    chvt 1
    touch /etc/network/interfaces.orig
    cp /etc/network/interfaces /etc/network/interfaces.orig
    echo "mv /etc/network/interfaces.orig /etc/network/interfaces && ifup -a && sed -i '/fixnet.sh/d' /etc/rc.local && rm -f /fixnet.sh" > /fixnet.sh
    sed -i '/exit 0/ibash /fixnet.sh' /etc/rc.local

    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /etc/network/interfaces https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/networkInterfacesMaster
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        wget -O /etc/network/interfaces https://raw.githubusercontent.com/ipa320/setup_cob4/master/cob-pcs/networkInterfacesSlave
    fi
    /etc/init.d/networking restart
}

function SetupEtcHosts {
    HOSTNAME=$(cat /etc/hostname)

    sed -i "s/$HOSTNAME.ipa-apartment.org\t//g" /etc/hosts

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

# TODO: fxm ;)
function InstallCandumpTools {
    initctl stop candump2mongodb
    rm /etc/init/candump2mongodb.conf
    wget -O /usr/local/bin/socket_buffer.py https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/socket_buffer.py
    chmod +x /usr/local/bin/socket_buffer.py
    #wget -O /etc/init/candump_any.conf https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/candump_any.conf
    #initctl start candump_any
}

#TODO: only newest NoMachine ?!?
function InstallNoMachine {
    NOMACHINE_VERSION=6.0.66_2
    wget -O /root/nomachine_${NOMACHINE_VERSION}_amd64.deb http://download.nomachine.com/download/6.0/Linux/nomachine_${NOMACHINE_VERSION}_amd64.deb
    dpkg -i /root/nomachine_${NOMACHINE_VERSION}_amd64.deb
}

function NetDataTools {
    apt-get install zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autoconf-archive autogen automake pkg-config curl -y
    git clone https://github.com/firehol/netdata.git --depth=1 /root/netdata
    cd /root/netdata
    yes | ./netdata-installer.sh
}

function InstallCobCommand {
    if [ "$INSTALL_TYPE" == "master" ]; then
        wget -O /usr/sbin/cob-command https://raw.githubusercontent.com/ipa320/setup_cob4/master/scripts/cob-command
        chmod +x /usr/sbin/cob-command
        sh -c 'echo "%users ALL=NOPASSWD:/usr/sbin/cob-command"' | sed -i -e "\|%users ALL=NOPASSWD:/usr/sbin/cob-command|h; \${x;s|%users ALL=NOPASSWD:/usr/sbin/cob-command||;{g;t};a\\" -e "%users ALL=NOPASSWD:/usr/sbin/cob-command" -e "}" /etc/sudoers
    fi
}

function RemoveModemanager {
    apt-get purge modemmanager -y
}

function DisableUpdatePopup {
    sed -i 's/Prompt\=lts/Prompt\=never/g' /etc/update-manager/release-upgrades
}

# TODO: fxm ;)
function DisableFailsafeBoot {
    sed -i 's/start on \(filesystem and static-network-up\) or failsafe-boot/start on filesystem and static-network-up/g' /etc/init/rc-sysinit.conf
}

function InstallAptCacher {
    apt-get install apt-cacher-ng -y
    HOSTNAME=$(cat /etc/hostname)
    SERVERNAME=$(echo ${HOSTNAME%-*}-b1)
    #TODO is $SERVERNAME same as server_ip???
    if grep -q 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        echo "Proxy already in /etc/apt/apt.conf.d/01proxy, skipping InstallAptCacher"
    else
        echo 'Acquire::http { Proxy "http://server_ip:3142"; };' >>  /etc/apt/apt.conf.d/01proxy
    fi
    sed -i "s/server_ip/${SERVERNAME}/g" /etc/apt/apt.conf.d/01proxy
    if [ "$INSTALL_TYPE" == "master" ]; then
        sed -i 's/\# PassThroughPattern: .\*/PassThroughPattern: .\*/g' /etc/apt-cacher-ng/acng.conf
    fi
}


########################################################################
############################# INITIAL MENU #############################
########################################################################

if [ $# -ne 1 ]; then
    echo "ERROR: wrong number of arguments, expecting:"
    echo "kickstart-robot.sh [master|slave]"
    exit 1
fi

if [ "$1" != "master" ] && [ "$1" != "slave" ]; then
    echo "ERROR: please provide argument [master|slave]. Got: $1"
    exit 2
else
    INSTALL_TYPE=$1
    echo "Starting kickstart robot - using install type: $INSTALL_TYPE"
fi

UpgradeAptPackages
SetupGroup
#UpgradeKernel
InstallGraphicalIface
#InstallHWEnableStacks
AddUsers
SetupRootUser
GiveFullRights
#KeyboardLayout
NFSSetup
ChronySetup
ConfigureSSH
SetupUdevRules
#InstallROS
InstallGitLFS
SetupDefaultBashEnv
InstallShutdown
NetworkSetup
SetupEtcHosts
#InstallCandumpTools
InstallNoMachine
InstallCobCommand
RemoveModemanager
#DisableFailsafeBoot
InstallAptCacher