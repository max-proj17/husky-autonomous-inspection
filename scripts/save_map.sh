#!/bin/bash
# Save the current SLAM map as map.yaml + map.pgm in the maps/ directory.

WORKSPACE=/workspaces/husky-autonomous-inspection
MAP_DIR=$WORKSPACE/maps

source /opt/ros/jazzy/setup.bash
source $WORKSPACE/install/local_setup.bash 2>/dev/null || true

mkdir -p $MAP_DIR

echo "Saving map to $MAP_DIR/map ..."
ros2 run nav2_map_server map_saver_cli -f $MAP_DIR/map

echo ""
echo "Saved: $MAP_DIR/map.yaml"
echo "       $MAP_DIR/map.pgm"
