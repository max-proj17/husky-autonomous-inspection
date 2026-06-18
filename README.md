# husky-autonomous-inspection
ROS 2 Jazzy simulation of a Husky mobile manipulator with SLAM and motion planning in Gazebo Harmonic.

## Launching the simulation

```bash
ros2 launch clearpath_gz simulation.launch.py
```

## Keyboard control

The Gazebo GUI includes a built-in Teleop panel. To use it:
1. Open the Teleop panel in the Gazebo GUI sidebar
2. Set the topic to `/a200_0000/cmd_vel`
3. Use the on-screen buttons or keyboard shortcuts to drive the robot

Alternatively, from a terminal inside the container:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r cmd_vel:=/a200_0000/cmd_vel
```
