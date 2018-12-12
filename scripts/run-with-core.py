#!/usr/bin/env python

import rospy
import sys
import subprocess

p = None

if __name__ == "__main__":
    while True:
        try:
            rospy.get_master().getPid()
            if p is None:
                print("roscore is running")
                print("starting: %s"%str(sys.argv[1:]))
                p = subprocess.Popen(sys.argv[1:])
        except Exception as e:
            #no roscore is running
            print("no roscore is running")
            print("%s"%e)
            if p is not None:
                print("terminate process: %d"%p.pid)
                p.terminate()
                p = None
        rospy.sleep(2)
