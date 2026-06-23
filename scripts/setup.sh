#!/bin/bash
# Run once after opening the devcontainer to set up the development environment.

set -e

WORKSPACE=/workspaces/husky-autonomous-inspection

echo "=== Husky Autonomous Inspection — One-Time Setup ==="

# 1. Robot config symlinks required by clearpath_gz
echo "[1/3] Linking robot.yaml..."
mkdir -p /root/clearpath /etc/clearpath
ln -sf $WORKSPACE/config/robot.yaml /root/clearpath/robot.yaml
ln -sf $WORKSPACE/config/robot.yaml /etc/clearpath/robot.yaml

# 2. Build local ROS packages
echo "[2/3] Building ROS packages..."
source /opt/ros/jazzy/setup.bash
cd $WORKSPACE
colcon build --symlink-install --packages-select slam_mapping

# 3. Add workspace to .bashrc so all future terminals are ready
echo "[3/3] Configuring .bashrc..."
SETUP_LINE="source $WORKSPACE/install/setup.bash 2>/dev/null || true"
if ! grep -qF "$SETUP_LINE" ~/.bashrc; then
    echo "$SETUP_LINE" >> ~/.bashrc
fi

echo ""
echo "Setup complete. Source your shell or open a new terminal, then run:"
echo "  ./scripts/start_sim.sh     — Terminal 1: Gazebo simulation"
echo "  ./scripts/start_mapping.sh — Terminal 2: SLAM + Foxglove (after sim is up)"
echo "  ./scripts/teleop.sh        — Terminal 3: Keyboard control"
echo "  ./scripts/save_map.sh      — Any terminal: Save finished map"
