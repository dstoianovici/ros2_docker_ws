# ROS 2 development image for working alongside Isaac Sim.
ARG ROS_DISTRO=jazzy
FROM osrf/ros:${ROS_DISTRO}-desktop-full

ARG ROS_DISTRO
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000
ENV ROS_DISTRO=${ROS_DISTRO} \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-colcon-common-extensions python3-rosdep python3-vcstool python3-pip \
        ros-${ROS_DISTRO}-rmw-fastrtps-cpp ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
        ros-${ROS_DISTRO}-vision-msgs ros-${ROS_DISTRO}-ackermann-msgs \
        ros-${ROS_DISTRO}-navigation2 ros-${ROS_DISTRO}-nav2-bringup \
        ros-${ROS_DISTRO}-teleop-twist-keyboard ros-${ROS_DISTRO}-rviz2 \
        git sudo nano less bash-completion gdb python3-autopep8 \
        ros-${ROS_DISTRO}-ament-lint-auto ros-${ROS_DISTRO}-ament-cmake-uncrustify \
    && rm -rf /var/lib/apt/lists/*

# Non-root user matching host UID/GID (Ubuntu 24.04 images ship an 'ubuntu' user at 1000).
RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
    && (groupadd --gid ${USER_GID} ${USERNAME} 2>/dev/null || true) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${USERNAME}
WORKDIR /ws
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
 && echo "[ -f /ws/install/setup.bash ] && source /ws/install/setup.bash || true" >> ~/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
