#!/bin/bash
set -e # force the script to exit if any error occurs

function printHeader {
    echo "#############################################"
    echo "Execute Kickstart-Function: $1"
    echo "---------------------------------------------"
}

function SetLocalAptCacher {
    printHeader "SetLocalAptCacher"
    unset http_proxy
    touch /etc/apt/apt.conf.d/01proxy

    SERVERNAME="b1"
    if grep -q 'Acquire::http { Proxy "http://10.0.1.2:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        echo "Proxy already in /etc/apt/apt.conf.d/01proxy, skipping SetLocalAptCacher"
    fi
    if grep -q 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        rm /etc/apt/apt.conf.d/01proxy
        touch /etc/apt/apt.conf.d/01proxy
        echo 'Acquire::http { Proxy "http://10.0.1.2:3142"; };' >>  /etc/apt/apt.conf.d/01proxy
    else
        echo 'Acquire::http { Proxy "http://10.0.1.2:3142"; };' >>  /etc/apt/apt.conf.d/01proxy
    fi
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

        SERVERNAME="b1"
        echo $SERVERNAME
        cp "$SETUP_COB4_DIR"/setup_cob4/upstart/u.mount /etc/systemd/system
        systemctl daemon-reload
        systemctl enable u.mount
    fi
}

function SetupPowerSettings {
    printHeader "SetupPowerSettings"

    # in Ubuntu >= 18.04 the powerbutton is also handled by logind
    if [ "$OS_VERSION" != "xenial" ]; then
        if grep -q "HandlePowerKey" /etc/systemd/logind.conf; then
            sed -i -E 's/^#?HandlePowerKey.*$/HandlePowerKey=ignore/g' /etc/systemd/logind.conf
        else
            echo "HandlePowerKey=ignore" >> /etc/systemd/logind.conf
        fi
    fi

    # set default gnome power settings, these settings are the defaults for all users
    # 16.04 and >= 18.04 have the same default values in the gschema.xaml.

    #set default power-button-action
    ln=$(grep -n '<key name="power-button-action"' /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml | cut -d : -f 1)
    if [ -n "$ln" ]; then
        ln=$((ln + 1))
        sed -i "${ln}s/suspend/nothing/" /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml
    fi

    #set default button-power
    ln=$(grep -n '<key name="button-power"' /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml | cut -d : -f 1)
    if [ -n "$ln" ]; then
        ln=$((ln + 1))
        sed -i "${ln}s/suspend/shutdown/" /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml
    fi

    #disable suspend on ac
    ln=$(grep -n '<key name="sleep-inactive-ac-type"' /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml | cut -d : -f 1)
    if [ -n "$ln" ]; then
        ln=$((ln + 1))
        sed -i "${ln}s/suspend/nothing/" /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml
    fi

    #disable suspend on bat
    ln=$(grep -n '<key name="sleep-inactive-battery-type"' /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml | cut -d : -f 1)
    if [ -n "$ln" ]; then
        ln=$((ln + 1))
        sed -i "${ln}s/suspend/nothing/" /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml
    fi

    # disable systemd suspension, hibernation and hybrid-sleep handling
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

    # enable acpi event logging
    if [ -f /etc/default/acpid ]; then
        if grep -q "#OPTIONS=" /etc/default/acpid; then
            sed -i 's/#OPTIONS=.*$/OPTIONS="--logevents"/g' /etc/default/acpid
        else
            echo "OPTIONS=\"--logevents\"" >> /etc/default/acpid
        fi
    fi
}

function AddUsers {
    printHeader "AddUsers"

    #initially set root password
    echo "root:$PASSWORD" | chpasswd -e

    #add robot-local user (preseedd seems to have a bug adding the user before postscript execution, results in overwritten group and user ids)
    useradd -b /home -d /home/robot-local -m -s /bin/bash -k /etc/skel robot-local
    echo "robot-local:$PASSWORD" | chpasswd -e

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
        echo "robot:$PASSWORD" | chpasswd -e

        #copy setup_cob4 from stick
        mkdir -p /u/robot/git
        cp -r "$SETUP_COB4_DIR"/setup_cob4 /u/robot/git/
        chown -hR robot:robot /u/robot/git
        chmod -R u+rw /u/robot/git
    fi

    #Give robot user full rights for sudo - both master and slave pcs
    if grep -q "robot ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ; then
        echo "found robot NOPASSWD in sudoers already, skipping GiveFullRights to robot"
    else
        echo "robot ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

function InstallROS {
    printHeader "InstallROS"
    if grep -q "deb http://packages.ros.org/ros/ubuntu $OS_VERSION main" /etc/apt/sources.list.d/ros-latest.list ; then
        echo "Ros sources already setup. Skipping setup"
    else
        echo "deb http://packages.ros.org/ros/ubuntu $OS_VERSION main" > /etc/apt/sources.list.d/ros-latest.list
        apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
    fi

    apt-get update
    apt-get install ros-"$ROS_VERSION"-ros-base -y
    if [ "$OS_VERSION" == "xenial" ]; then
        apt-get install build-essential python-catkin-tools python-wstool -y
        apt-get install python-rosinstall python-rosinstall-generator -y
        apt-get install python-pip python-rosdep -y
    elif [ "$OS_VERSION" == "focal" ]; then
        apt-get install build-essential python3-catkin-tools python3-osrf-pycommon python3-wstool -y
        apt-get install python3-rosinstall python3-rosinstall-generator -y
        apt-get install python3-pip python3-rosdep -y
    fi
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

function KeyboardLayout {
    printHeader "KeyboardLayout"
    L='de' && sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$L'\"/g' /etc/default/keyboard
    export DEBIAN_FRONTEND=noninteractive
    apt-get install console-data -y -f -q
    dpkg-reconfigure keyboard-configuration
}

function ConfigureSSH {
    printHeader "ConfigureSSH"
    apt-get install openssh-server -y

    if grep -q "X11Forwarding" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?X11Forwarding.*$/X11Forwarding yes/g' /etc/ssh/sshd_config
    else
        echo "X11Forwarding yes" >> /etc/ssh/sshd_config
    fi
    if grep -q "X11UseLocalhost" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?X11UseLocalhost.*$/X11UseLocalhost no/g' /etc/ssh/sshd_config
    else
        echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
    fi
    if grep -q "PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin yes">> /etc/ssh/sshd_config
    fi
    if grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?ClientAliveInterval.*$/ClientAliveInterval 60/g' /etc/ssh/sshd_config
    else
        echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
    fi

    systemctl restart ssh
}

function ChronySetup {
    printHeader "ChronySetup"
    apt-get install chrony ntpdate -y -f
    if [ "$INSTALL_TYPE" == "master" ]; then
        cp "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/chrony_server /etc/chrony/chrony.conf
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        SERVERNAME="b1"
        cp "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/chrony_client /etc/chrony/chrony.conf
        sed -i "s/server_ip/${SERVERNAME}/g" /etc/chrony/chrony.conf
    fi

    # only needed in xenial. Newer ubuntu versions already deliver
    # the service configs and scripts via the dep package
    if [ "$OS_VERSION" == "xenial" ]; then
        systemctl disable chrony.service
        cp "$SETUP_COB4_DIR"/setup_cob4/upstart/chronyd.service /etc/systemd/system

        cp "$SETUP_COB4_DIR"/setup_cob4/scripts/chronyd-starter.sh /usr/lib/systemd/scripts
        chmod 755 /usr/lib/systemd/scripts/chronyd-starter.sh

        mkdir -p /usr/lib/chrony
        cp "$SETUP_COB4_DIR"/setup_cob4/scripts/chrony-helper /usr/lib/chrony
        chmod 755 /usr/lib/chrony/chrony-helper

        systemctl enable chronyd.service
        systemctl daemon-reload
    fi


    # allow everybody to call 'sudo service chrony restart'
    if grep -q  "%users ALL=NOPASSWD:/bin/systemctl restart chronyd" /etc/sudoers ; then
        echo "NOPASSWD already for all users in /bin/systemctl restart chronyd, skipping"
    else
        echo "%users ALL=NOPASSWD:/bin/systemctl restart chronyd" >> /etc/sudoers
    fi

    #disable ntpdate sync on network interface up
    FILE=/etc/network/if-up.d/ntpdate
    if [ -f "$FILE" ]; then
        rm $FILE
    fi
}

function SetupUdevRules {
    printHeader "SetupUdevRules"
    cp "$SETUP_COB4_DIR"/setup_cob4/udev_rules/98-led.rules /etc/udev/rules.d/98-led.rules
    cp "$SETUP_COB4_DIR"/setup_cob4/udev_rules/99-phidgets.rules /etc/udev/rules.d/99-phigets.rules
    if [ "$INSTALL_TYPE" == "slave" ]; then
        cp "$SETUP_COB4_DIR"/setup_cob4/udev_rules/99-gripper.rules /etc/udev/rules.d/99-gripper.rules
    fi
}

function InstallGitLFS {
    printHeader "InstallGitLFS"
    if [ "$OS_VERSION" == "xenial" ]; then
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
    fi
    apt-get install git-lfs -y
    # git lfs install
}

function SetupDefaultBashEnv {
    printHeader "SetupDefaultBashEnv"
    if [ "$INSTALL_TYPE" == "master" ]; then
        cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/cob.bash.bashrc.b /etc/cob.bash.bashrc
    elif [ "$INSTALL_TYPE" == "slave" ]; then
        if [[ "$HOSTNAME" == "t"* ]]; then
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/cob.bash.bashrc.t /etc/cob.bash.bashrc
        elif [[ "$HOSTNAME" == "h"* ]]; then
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/cob.bash.bashrc.h /etc/cob.bash.bashrc
        elif [[ "$HOSTNAME" == "s"* ]]; then
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/cob.bash.bashrc.s /etc/cob.bash.bashrc
        else
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/cob.bash.bashrc.s /etc/cob.bash.bashrc # unused sensorring as default
        fi
    fi
}

function InstallCobScripts {
    printHeader "InstallCobScripts"

    # prerequisites for robmuxinator
    sudo -H pip3 install argcomplete
    sudo -H pip3 install paramiko
    sudo activate-global-python-argcomplete
}

function NetworkSetup {
    printHeader "NetworkSetup"
    if [ "$OS_VERSION" == "xenial" ]; then
        INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}')

        if [ "$INSTALL_TYPE" == "master" ]; then
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/networkInterfacesMaster /etc/network/interfaces
        elif [ "$INSTALL_TYPE" == "slave" ]; then
            cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/networkInterfacesSlave /etc/network/interfaces
        fi

        sed -i "s/eth0/$INTERFACE/g" /etc/network/interfaces

        systemctl restart networking
    elif [ "$OS_VERSION" == "focal" ]; then
        cp -f "$SETUP_COB4_DIR"/setup_cob4/cob-pcs/60-can.network /etc/systemd/network
    fi
}

function SetupEtcHosts {
    printHeader "SetupEtcHosts"
    HOSTNAME=$(cat /etc/hostname)

    sed -i "s/$HOSTNAME.wlrob.net\t//g" /etc/hosts

    ROBOTNAME="${HOSTNAME%-*}"
    ROBOT_NUM="${ROBOTNAME##*-}"

    PC_LS=(
    "10.4.${ROBOT_NUM}.41	h1"
    "10.4.${ROBOT_NUM}.31	s1"
    "10.4.${ROBOT_NUM}.23	t3"
    "10.4.${ROBOT_NUM}.22	t2"
    "10.4.${ROBOT_NUM}.21	t1"
    "10.4.${ROBOT_NUM}.11	b1"
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
    cp "$SETUP_COB4_DIR"/setup_cob4/scripts/socket_buffer.py /usr/local/bin/socket_buffer.py
    chmod +x /usr/local/bin/socket_buffer.py
}

function InstallNetData {
    printHeader "InstallNetData"
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) all --dont-wait
}

function InstallDocker {
    printHeader "InstallDocker"
    # https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io -y
    #     docker run hello-world  # test docker

    # https://docs.docker.com/compose/install/#install-compose-on-linux-systems
    curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version  # test docker-compose

    # libcrypto++6 for navigation license server
    apt-get install libcrypto++6 -y
}

function InstallDebugTools {
    #This is the machine check exception logger
    #useful for debugging machine crashes
    printHeader "InstallDebugTools"
    apt-get install rasdaemon -y
    apt-get install iperf -y
    apt-get install stress stress-ng -y
}

function RemoveModemanager {
    printHeader "RemoveModemanager"
    apt-get purge modemmanager -y
}

function DisableSpacenavDeamon {
    #Disable this because it is spamming the syslog
    #and we do not need it
    printHeader "DisableSpacenavDeamon"
    if [ "$OS_VERSION" == "xenial" ]; then
        systemctl disable spacenavd.service
    fi
}

function DisableUpdatePopup {
    printHeader "DisableUpdatePopup"
    sed -i 's/Prompt\=lts/Prompt\=never/g' /etc/update-manager/release-upgrades
}

function NonInteractiveFSCKFIX {
    printHeader "NonInteractiveFSCKFIX"
    sed -i '/FSCKFIX\=no/c\FSCKFIX\=yes' /lib/init/vars.sh
}

function ConfigureDefaultSoundcard {
    printHeader "ConfigureDefaultSoundcard"
    apt-get install alsa-base alsa-tools -y
    sed -i 's/options snd-usb-audio index=-2/options snd-usb-audio index=0/g' /etc/modprobe.d/alsa-base.conf
}

function ConfigureOtherServices {
    printHeader "ConfigureOtherServices"
    systemctl disable apt-daily.service
    systemctl disable apt-daily.timer

    systemctl disable apt-daily-upgrade.service
    systemctl disable apt-daily-upgrade.timer

    systemctl disable motd-news.service
    systemctl disable motd-news.timer
}

function InstallRealsense {
    printHeader "InstallRealsense"

    apt-key adv --keyserver keys.gnupg.net --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
    add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $OS_VERSION main" -u
    apt-get update
    apt-get install librealsense2-dkms librealsense2-udev-rules librealsense2-utils -y
    modinfo uvcvideo | grep "version:" || echo "librealsense check failed! check output of modinfo uvcvideo | grep \"version:\""
}

function InstallCareOBot {
    printHeader "InstallCareOBot"
    #ToDo: use `--download-only` as long as realsense dependencies try to apply patches to file that do not exist with latest kernel
    apt-get install ros-"$ROS_VERSION"-camera-calibration -y
    apt-get install ros-"$ROS_VERSION"-rqt* -y
    apt-get install ros-"$ROS_VERSION"-cob* -y  # install some cob-dependencies already
    #apt-get install ros-$ROS_VERSION-care-o-bot-robot -y --download-only        # not released into noetic
}

function InstallAptCacher {
    printHeader "InstallAptCacher"
    #disable local forward to 10.0.1.2 cacher
    if grep -q 'Acquire::http { Proxy "http://10.0.1.2:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        rm /etc/apt/apt.conf.d/01proxy
    fi
    if grep -q 'Acquire::http::Proxy "http://10.0.1.2:3142/";' /etc/apt/apt.conf ; then
        sed -i 's!Acquire::http::Proxy "http://10.0.1.2:3142/";!!g' /etc/apt/apt.conf
    fi

    SERVERNAME="b1"
    if [ "$INSTALL_TYPE" == "master" ]; then
        apt-get install apt-cacher-ng -y
        sed -i 's/\# PassThroughPattern: .\*/PassThroughPattern: .\*/g' /etc/apt-cacher-ng/acng.conf
        systemctl restart apt-cacher-ng
    fi

    touch /etc/apt/apt.conf.d/01proxy

    if grep -q 'Acquire::http { Proxy "http://10.0.1.2:3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        rm /etc/apt/apt.conf.d/01proxy
        touch /etc/apt/apt.conf.d/01proxy
    fi
    if grep -q 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' /etc/apt/apt.conf.d/01proxy ; then
        echo "Proxy already in /etc/apt/apt.conf.d/01proxy, skipping InstallAptCacher"
    else
        echo 'Acquire::http { Proxy "http://'$SERVERNAME':3142"; };' >>  /etc/apt/apt.conf.d/01proxy
        echo 'Acquire::https { Proxy "https://"; };' >>  /etc/apt/apt.conf.d/01proxy
    fi
}

function FinishKickstartRobot {
    printHeader "FinalizeKickstartRobot"
    #needed just for testing success of kickstart-robot.sh during PostInstallCob4.sh
}

########################################################################
############################# INITIAL MENU #############################
########################################################################

if [ $# -eq 2 ]; then
    # shellcheck disable=SC2016
    PASSWORD='$1$.8rMo3Kc$hwkXrTTshYmLa9iplJchz.'  # default password
elif [ $# -eq 3 ]; then
    PASSWORD=$3
else
    echo "ERROR: wrong number of arguments, expecting:"
    echo "kickstart-robot.sh OS_VERSION INSTALL_TYPE [PASSWORD]"
    exit 1
fi

if [ "$1" != "xenial" ] && [ "$1" != "focal" ]; then
    echo "ERROR: OS_VERSION '$1' not supported - only: [xenial/focal]"
    exit 1
fi
if [ "$2" != "master" ] && [ "$2" != "slave" ]; then
    echo "ERROR: INSTALL_TYPE '$2' not supported - only: [master/slave]"
    exit 1
fi

OS_VERSION=$1
INSTALL_TYPE=$2

if [ "$OS_VERSION" == "xenial" ]; then
    ROS_VERSION="kinetic"
    SETUP_COB4_DIR="/media/cdrom"
elif [ "$OS_VERSION" == "focal" ]; then
    ROS_VERSION="noetic"
    SETUP_COB4_DIR="/tmp"
fi

if [ "$http_proxy" ]; then
    echo "http_proxy is set from preseed. Unsetting and setup apt cacher"
    unset http_proxy
    SetLocalAptCacher
fi

EnableAptSources
UpgradeAptPackages
NFSSetup
SetupPowerSettings
AddUsers
InstallROS
SetupGrubRecFail
KeyboardLayout
ConfigureSSH
ChronySetup
SetupUdevRules
InstallGitLFS
SetupDefaultBashEnv
InstallCobScripts
NetworkSetup
SetupEtcHosts
InstallCandumpTools
InstallNetData
InstallDocker
InstallDebugTools
RemoveModemanager
DisableSpacenavDeamon
DisableUpdatePopup
NonInteractiveFSCKFIX
ConfigureDefaultSoundcard
InstallRealsense
InstallCareOBot
InstallAptCacher
FinishKickstartRobot
