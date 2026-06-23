#!/bin/bash
# Terminal 2: Start SLAM and Foxglove bridge. Run after start_sim.sh is up.

WORKSPACE=/workspaces/husky-autonomous-inspection

source /opt/ros/jazzy/setup.bash
source $WORKSPACE/install/local_setup.bash

echo "Starting Foxglove bridge on ws://localhost:8765 ..."
ros2 run foxglove_bridge foxglove_bridge \
    --ros-args --params-file $WORKSPACE/config/platform/config/foxglove_bridge.yaml &
FOXGLOVE_PID=$!

echo "Starting SLAM Toolbox..."
ros2 launch slam_mapping slam.launch.py &
SLAM_PID=$!

echo ""
echo "Foxglove: open https://app.foxglove.dev → Open connection → ws://localhost:8765"
echo "Add a 3D panel and subscribe to /map and /a200_0000/sensors/lidar2d_0/scan"
echo ""
echo "Press Ctrl+C to stop SLAM and Foxglove."

trap "kill $FOXGLOVE_PID $SLAM_PID 2>/dev/null" INT TERM
wait
