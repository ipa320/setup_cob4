#!/bin/bash
export ROSLAUNCH_SSH_UNKNOWN=1
/u/msh/git/care-o-bot/devel/env.sh roscore&
PID=$!
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "              Starting rocore                  "
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
#log info "robot.launch: Started roslaunch as background process, PID $PID"
echo "$PID" > /tmp/roscore.pid
wait "$PID"
