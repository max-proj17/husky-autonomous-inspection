#!/bin/bash
# Terminal 3: Hold-to-move keyboard teleop for the Husky.
# Movement is active only while the key is held — release to stop.
# Keep this terminal focused while driving.

source /opt/ros/jazzy/setup.bash
source /workspaces/husky-autonomous-inspection/install/local_setup.bash 2>/dev/null || true

python3 /workspaces/husky-autonomous-inspection/scripts/hold_teleop.py
