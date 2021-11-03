
########################################################################

# cob specific aliases
alias b1='ssh -XC b1'
alias t1='ssh -XC t1'
alias t2='ssh -XC t2'
alias t3='ssh -XC t3'
alias s1='ssh -XC s1'
alias h1='ssh -XC h1'

# use global color settings
source /etc/cob.bash.bashrc

# turn off terminal keyboard shortcuts CTRL+S/CTRL+Q
stty -ixon

# ROS specific settings
export MY_CATKIN_WORKSPACE=~/git/care-o-bot

export ROBOT=myrobot
export ROBOT_ENV=empty
export ROSLAUNCH_SSH_UNKNOWN=1
export ROS_MASTER_URI=http://mymasterip:11311
export ROS_IP=`hostname -I | awk '{print $1}'`
export ROSCONSOLE_FORMAT='[${severity}] [${time}]: ${node}(${function}): ${message}'

# DONT TOUCH ANYTHING BELOW THIS LINE !!!
unset CMAKE_PREFIX_PATH
if [ -e $MY_CATKIN_WORKSPACE/devel/setup.bash ]; then
    source $MY_CATKIN_WORKSPACE/devel/setup.bash
elif [ -e /u/robot/git/care-o-bot/devel/setup.bash ]; then
    source /u/robot/git/care-o-bot/devel/setup.bash
else
    source /opt/ros/mydistro/setup.bash
fi

echo -e "Your CMAKE_PREFIX_PATH:\n$CMAKE_PREFIX_PATH\n"

# ROSJAVA settings
#export ROSJAVA_WORKSPACE=~/git/rosjava_ws
#export ROS_MAVEN_DEPLOYMENT_REPOSITORY=$ROSJAVA_WORKSPACE/devel/share/maven
