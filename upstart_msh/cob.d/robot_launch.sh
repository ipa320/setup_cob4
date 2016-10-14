#!/bin/bash
export ROSLAUNCH_SSH_UNKNOWN=1
LAUNCH_FILENAME=/tmp/robot.launch.launch
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "              Starting bringup                  "
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"

/u/msh/git/care-o-bot/devel/env.sh roslaunch $LAUNCH_FILENAME > /tmp/robot.log&
PID=$!

#log info "robot.launch: Started roslaunch as background process, PID $PID"
echo "$PID" > /tmp/robot.launch.pid
wait "$PID"
