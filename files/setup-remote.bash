#!/bin/bash

source /etc/ros/setup.bash
export ROS_MASTER_URI=http://ROBOT_HOSTNAME:11311

exec $@
