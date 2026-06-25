#!/bin/bash
# Terminal 2: Start SLAM and Foxglove bridge. Run after start_sim.sh is up.

WORKSPACE=/workspaces/husky-autonomous-inspection
SLAM_PARAMS=$WORKSPACE/config/slam_params.yaml

source /opt/ros/jazzy/setup.bash

echo "Starting Foxglove bridge on ws://localhost:8765 ..."
ros2 run foxglove_bridge foxglove_bridge \
    --ros-args --params-file $WORKSPACE/config/platform/config/foxglove_bridge.yaml &
FOXGLOVE_PID=$!

echo "Starting pointcloud_to_laserscan..."
ros2 run pointcloud_to_laserscan pointcloud_to_laserscan_node \
    --ros-args \
    -p use_sim_time:=true \
    -p target_frame:=base_link \
    -p min_height:=-0.1 \
    -p max_height:=0.5 \
    -p range_min:=0.1 \
    -p range_max:=20.0 \
    -r cloud_in:=/a200_0000/sensors/lidar3d_0/points \
    -r scan:=/a200_0000/sensors/lidar3d_0/scan \
    -r /tf:=/a200_0000/tf \
    -r /tf_static:=/a200_0000/tf_static &
PC2LS_PID=$!

echo "Starting SLAM Toolbox..."
ros2 run slam_toolbox async_slam_toolbox_node \
    --ros-args \
    --params-file $SLAM_PARAMS \
    -p use_sim_time:=true \
    -r /tf:=/a200_0000/tf \
    -r /tf_static:=/a200_0000/tf_static &
SLAM_PID=$!

echo "Waiting for SLAM Toolbox lifecycle node to be ready..."
sleep 3
ros2 lifecycle set /slam_toolbox configure && sleep 1 && ros2 lifecycle set /slam_toolbox activate

echo ""
echo "Foxglove: open https://app.foxglove.dev → Open connection → ws://localhost:8765"
echo "Add a 3D panel and subscribe to /map and /a200_0000/sensors/lidar3d_0/scan"
echo ""
echo "Press Ctrl+C to stop all processes."

trap "kill $FOXGLOVE_PID $PC2LS_PID $SLAM_PID 2>/dev/null" INT TERM
wait
