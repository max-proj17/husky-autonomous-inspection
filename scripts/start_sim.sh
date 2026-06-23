#!/bin/bash
# Terminal 1: Launch the Gazebo simulation.

source /opt/ros/jazzy/setup.bash
source /workspaces/husky-autonomous-inspection/install/local_setup.bash 2>/dev/null || true

ros2 launch clearpath_gz simulation.launch.py
