cmake_minimum_required(VERSION 2.8.3)
project(cob4_homing)

find_package(catkin REQUIRED COMPONENTS roslaunch)

catkin_package()

catkin_install_python(PROGRAMS scripts/calib.py scripts/patch.py
   DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

install(DIRECTORY launch config
        DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
        )
