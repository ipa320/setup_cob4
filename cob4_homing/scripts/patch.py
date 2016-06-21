#!/usr/bin/env python2

import rospy

from std_srvs.srv import Trigger
from geometry_msgs.msg import Twist, Vector3

from controller_manager import controller_manager_interface

WHEEL1 = 'fl_caster_rotation_joint'
WHEEL2 =  'b_caster_rotation_joint'
WHEEL3 = 'fr_caster_rotation_joint'


rospy.init_node('base_test')

init_srv = rospy.ServiceProxy('/driver/init', Trigger)
recover_srv = rospy.ServiceProxy('/driver/recover', Trigger)
init_srv.wait_for_service(10.0)
if not init_srv().success:
    exit(-1)

def spawn(c):
    controller_manager_interface.load_controller(c)
    controller_manager_interface.stop_controller(c)
    if not controller_manager_interface.start_controller(c):
        rospy.logerr("could not start " + c)
        exit(-2)

raw_input("ready?")

spawn('twist_controller')

raw_input("run?")

msgs = [ Twist(linear = Vector3(x=0.1)), Twist(linear = Vector3(y=0.1)), Twist(linear = Vector3(x=-0.1)), Twist(linear = Vector3(y=-0.1)) ]

pub = rospy.Publisher('/twist_controller/command', Twist, queue_size=1)

rate = rospy.Rate(10)

while True:
    for i in range(4):
        for j in range(50):
            pub.publish(msgs[i])
            rate.sleep()