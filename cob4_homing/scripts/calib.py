#!/usr/bin/env python2

import threading
import rospy
import math

from std_msgs.msg import Float64
from std_srvs.srv import Trigger
from sensor_msgs.msg import JointState

from controller_manager import controller_manager_interface

js_cv = threading.Condition()

WHEEL1 = 'fl_caster_rotation_joint'
WHEEL2 =  'b_caster_rotation_joint'
WHEEL3 = 'fr_caster_rotation_joint'

# old FDMs
#tests = {
#    ('please align wheels 1 and 2',  30000, (WHEEL1, -30000), (WHEEL2, -150000)),
#    ('please align wheels 2 and 3', 150000, (WHEEL2, -30000), (WHEEL3, -150000)),
#    ('please align wheels 3 and 1', -90000, (WHEEL3, -30000), (WHEEL1, -150000)),
#}

# new FDMs
tests = {
    ('please align wheels 1 and 2', -150000, (WHEEL1, -120000), (WHEEL2, 120000)),
    ('please align wheels 2 and 3',  -30000, (WHEEL2, -120000), (WHEEL3, 135000)),
    ('please align wheels 3 and 1',   90000, (WHEEL3, -120000), (WHEEL1, 135000)),
}

joint_states = {}
got_js = False

rospy.init_node('base_calib')

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

spawn('joint_state_controller')
spawn('fl_caster_rotation_joint_position_controller')
spawn( 'b_caster_rotation_joint_position_controller')
spawn('fr_caster_rotation_joint_position_controller')

def norm(val, min, max):
    while val < min: val += (max-min)
    while val >= max: val -= (max-min)
    return val

def handle_js(js):
   global js_cv, got_js, joint_states
   with js_cv:
     for i in range(len(js.name)):
         joint_states[js.name[i]] = math.degrees(js.position[i]*1000.0)
     got_js = True
     js_cv.notify()

rospy.Subscriber("joint_states", JointState, handle_js)


publishers = {
'fl_caster_rotation_joint' : rospy.Publisher('fl_caster_rotation_joint_position_controller/command', Float64, queue_size=1),
 'b_caster_rotation_joint' : rospy.Publisher( 'b_caster_rotation_joint_position_controller/command', Float64, queue_size=1),
'fr_caster_rotation_joint' : rospy.Publisher('fr_caster_rotation_joint_position_controller/command', Float64, queue_size=1),
}

def command(name, value):
  msg = Float64()
  msg.data = math.radians(value)/1000.0;
  publishers[name].publish(msg)


results = {
    WHEEL1: [],
    WHEEL2: [],
    WHEEL3: [],
}

command(WHEEL1, 0)
command(WHEEL2, 0)
command(WHEEL3, 0)

raw_input("ready for start?")

for t in tests:
  text, g, w1, w2 = t
  if not recover_srv().success:
    exit(-1)
  rospy.sleep(0.1)

  command(*w1)
  command(*w2)

  raw_input(text)

  with js_cv:
    got_js = False
    while not got_js and not rospy.is_shutdown():
      js_cv.wait()
    v1 = joint_states[w1[0]]
    v2 = joint_states[w2[0]]

  results[w1[0]].append(norm(v1 - g,0,360000))
  results[w2[0]].append(norm(v2 - g,0,360000))

print results

for k,v in results.iteritems():
    offset = norm(sum(v)/len(v),-180000,180000)
    print k, offset
    rospy.set_param("/calib_driver/nodes/%s/dcf_overlay/607C" % k, str(offset))