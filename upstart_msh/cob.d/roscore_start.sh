#!/bin/bash
export ROSLAUNCH_SSH_UNKNOWN=1
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "              Starting rocore                  "
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"

/u/msh/git/care-o-bot/devel/env.sh roscore&
PID=$!

#log info "robot.launch: Started roslaunch as background process, PID $PID"
echo "$PID" > /tmp/roscore.pid
wait "$PID"

fg
