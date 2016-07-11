#!/usr/bin/env python2

import roslaunch

run_id = roslaunch.core.generate_run_id()
parent = roslaunch.parent.ROSLaunchParent( run_id, [], is_core=True)
parent.start()

launch = roslaunch.scriptapi.ROSLaunch()
launch.start()

raw_input("quit?")
parent.shutdown()