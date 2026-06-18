FROM osrf/ros:jazzy-desktop

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install our system dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-vcstool \
    python3-colcon-common-extensions \
    python3-rosdep \
    git \
    wget \
    curl \
    vim \
    ros-jazzy-gz-ros2-control \
    ros-jazzy-slam-toolbox \
    ros-jazzy-navigation2 \
    ros-jazzy-nav2-bringup \
    ros-jazzy-moveit \
    ros-jazzy-moveit-ros-planning-interface \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    ros-jazzy-clearpath-gz \
    ros-jazzy-clearpath-manipulators \
    ros-jazzy-clearpath-nav2-demos \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep update

# Create workspace and clearpath config directory
RUN mkdir -p /ros2_ws/src && mkdir -p /etc/clearpath

WORKDIR /ros2_ws

# Source ROS 2 on every shell
RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc
RUN echo "source /ros2_ws/install/setup.bash 2>/dev/null || true" >> /root/.bashrc
RUN echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> /root/.bashrc

# Allow Gazebo GUI via display forwarding
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1

CMD ["/bin/bash"]