# ros2_docker_ws

A Docker-based ROS 2 workspace for Linux, with optional NVIDIA Isaac Sim.

You get:

- **A ROS 2 development container** (`ros2` service) built from [`docker/Dockerfile`](docker/Dockerfile).
  It runs ROS 2 Jazzy by default (Humble also works) and includes colcon, rosdep, vcstool, Nav2, RViz,
  the ament linters and gdb. This repo is mounted at `/ws`.
- **An Isaac Sim container** (`isaac-sim` service) that runs NVIDIA's official image with the ROS 2 bridge turned on.
- **Build flags** in `.env` that choose which services are built and run.
- **A VS Code Dev Container** that uses the same image, plus tasks, debugging and linting.
- **An example package**, [`isaac_bridge_demo`](src/isaac_bridge_demo), that drives a simulated robot over the ROS 2 bridge.

All containers use the host's network and IPC namespace, so ROS 2 nodes in the containers and on the host
find each other automatically.

## Requirements

- Ubuntu 22.04 or 24.04
- An NVIDIA GPU and driver (`nvidia-smi` works). Isaac Sim needs an RTX GPU; see the
  [Isaac Sim requirements](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html).
- An [NGC](https://ngc.nvidia.com) API key, only if you use Isaac Sim

`make setup` installs Docker and the NVIDIA Container Toolkit.

## Quick start

```bash
git clone https://github.com/dstoianovici/ros2_docker_ws.git
cd ros2_docker_ws
make setup   # one time: Docker, NVIDIA Container Toolkit, Isaac Sim cache dirs, UID/GID into .env
```

Log out and back in if `setup` added you to the `docker` group.

```bash
make build   # build/pull every service whose BUILD_* flag is true
make up      # start them
make colcon  # colcon build the workspace inside the ros2 container
make shell   # open a shell in the ros2 container
```

All targets: `make help`.

## Build flags: choosing services

Each service belongs to a Docker Compose profile. Each profile is turned on by a `BUILD_<NAME>` flag in [`.env`](.env):

| Flag | Profile | Service | `make build` does | Default |
|---|---|---|---|---|
| `BUILD_ROS2` | `ros2` | `ros2` | `docker build` of `docker/Dockerfile` | `true` |
| `BUILD_ISAAC_SIM` | `isaac_sim` | `isaac-sim` | `docker pull` of `ISAAC_SIM_IMAGE` | `false` |

`make build` and `make up` use only the services whose flag is `true`. `make shell`, `make logs`, `make ps`
and `make down` work on every service, whatever the flags say.

You can set a flag in `.env` or for a single command:

```bash
make build BUILD_ISAAC_SIM=true                   # also pull Isaac Sim this time
make up BUILD_ROS2=false BUILD_ISAAC_SIM=true     # simulator only
BUILD_ISAAC_SIM=true ./scripts/compose.sh config  # any docker compose command
```

The Makefile calls [`scripts/compose.sh`](scripts/compose.sh), which runs `docker compose` with the matching
`--profile` options. If you run plain `docker compose` instead, the flags are ignored and profiled services don't start.

**Adding a service:** add it to `docker-compose.yml` with `profiles: ["foo"]`, then add `BUILD_FOO=true` to `.env`.

## Configuration (`.env`)

| Variable | Default | Notes |
|---|---|---|
| `BUILD_*` | see above | Service build flags |
| `ROS_DISTRO` | `jazzy` | Also accepts `humble`. Must be a distro the Isaac Sim ROS 2 bridge supports. |
| `ROS_DOMAIN_ID` | `0` | Use the same value on every machine and container that should talk |
| `RMW_IMPLEMENTATION` | `rmw_fastrtps_cpp` | |
| `ISAAC_SIM_IMAGE` | `nvcr.io/nvidia/isaac-sim:5.1.0` | Change the tag to upgrade |
| `ISAAC_SIM_CACHE` | `~/docker/isaac-sim` | Shader and asset caches persist here between runs |
| `USER_UID` / `USER_GID` | `1000` | Set by `scripts/sync_ids.sh` so files in the workspace stay owned by you |
| `PYTHONPATH` | | For VS Code Python analysis only |

Don't put comments on the same line as a value in `.env`.

## Example package: `isaac_bridge_demo`

[`src/isaac_bridge_demo`](src/isaac_bridge_demo) is a small `ament_python` package that shows the round trip between
ROS 2 and Isaac Sim.

**Node `cmd_vel_driver`**

| | Topic | Type | Notes |
|---|---|---|---|
| Publishes | `/cmd_vel` | `geometry_msgs/Twist` | 10 Hz, constant velocity |
| Subscribes | `/clock` | `rosgraph_msgs/Clock` | Logs once when sim time starts arriving |

| Parameter | Default | Meaning |
|---|---|---|
| `linear` | `0.2` | Forward speed (m/s) |
| `angular` | `0.3` | Turn rate (rad/s) |
| `use_sim_time` | `true` (from the launch file) | Use Isaac Sim's `/clock` |

### Run it with Isaac Sim

1. Turn on both services and start them:
   ```bash
   docker login nvcr.io        # user: $oauthtoken   password: <NGC API key>
   make build BUILD_ISAAC_SIM=true
   make up BUILD_ISAAC_SIM=true
   ```
   The first time Isaac Sim starts it compiles shaders, which takes several minutes. `make logs` shows progress.
2. In the Isaac Sim window:
   - Check that **Window → Extensions → `isaacsim.ros2.bridge`** is enabled.
   - Load a wheeled robot, for example a differential-drive robot from **Create → Robots** or the asset browser.
   - Add ROS 2 graphs from **Tools → Robotics → ROS 2 OmniGraphs**: **Clock**, and a **Drive** or
     differential-controller graph that subscribes to `/cmd_vel`.
   - Press **Play**.
3. Build and launch the node:
   ```bash
   make colcon
   make shell
   ros2 launch isaac_bridge_demo demo.launch.py
   ```
   The robot drives in a circle. The node logs `Receiving /clock from Isaac Sim`.
4. Change its speed while it runs:
   ```bash
   ros2 param set /cmd_vel_driver linear 0.5
   ros2 param set /cmd_vel_driver angular 0.0
   ```
   Or set the speed at launch: `ros2 run isaac_bridge_demo cmd_vel_driver --ros-args -p linear:=0.5`.

### Run it without Isaac Sim

```bash
make up && make colcon && make shell
ros2 launch isaac_bridge_demo demo.launch.py use_sim_time:=false
# in a second `make shell`:
ros2 topic echo /cmd_vel
```

### Use it as a starting point

Copy or rename the package, then:

- add your nodes under `isaac_bridge_demo/` and register them in `entry_points` in `setup.py`
- add runtime dependencies to `package.xml`, and install them with `rosdep install --from-paths src --ignore-src -y`
- add launch files under `launch/` and list them in `data_files` in `setup.py`

## Workspace layout

```
.
├── .devcontainer/          VS Code Dev Container (uses docker/Dockerfile)
├── .vscode/                tasks, debug configs, editor settings
├── .github/workflows/      CI: build + test + ament linters
├── config/fastdds.xml      DDS profile used by every container (UDP only)
├── docker/                 ROS 2 image Dockerfile + entrypoint
├── scripts/
│   ├── compose.sh          docker compose wrapper that applies the BUILD_* flags
│   ├── setup_host.sh       one-time host install
│   ├── sync_ids.sh         writes your UID/GID into .env
│   └── xhost.sh            lets containers open windows on your display
├── src/                    ROS 2 packages (colcon builds into build/ install/ log/)
│   ├── ros2.repos          external repos to import with vcstool
│   └── isaac_bridge_demo/
├── docker-compose.yml
├── Makefile
└── .env
```

## Developing in VS Code

1. Install [Docker](https://docs.docker.com/engine/install/), [VS Code](https://code.visualstudio.com/) and the
   [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.
2. Open this folder and choose **Reopen in Container**. VS Code builds `docker/Dockerfile` and mounts the repo at `/ws`.
3. Use **Terminal → Run Task…**:
   - `import from workspace file`: run `vcs import` on the repos listed in `src/ros2.repos`
   - `install dependencies`: run `rosdep install`
   - `build` / `debug` / `test`: run colcon
   - `lint all`, plus single linters: cppcheck, cpplint, uncrustify, flake8, pep257, xmllint, lint_cmake
   - `new ament_cmake package` / `new ament_python package`

Debug configurations for Python and gdb are in [`.vscode/launch.json`](.vscode/launch.json).

The Dev Container and the `ros2` compose service use the same image, so you can use either one, or both at once.

## Continuous integration

[`.github/workflows/ros.yaml`](.github/workflows/ros.yaml) builds `docker/Dockerfile`, imports `src/ros2.repos`,
installs dependencies, then runs `colcon build` and `colcon test`. It also runs each ament linter as its own job.
To skip a linter, remove its name from the `matrix.linter` list.

## Troubleshooting

- **`cannot open display`**: run `./scripts/xhost.sh` and check that `echo $DISPLAY` prints a value on the host.
- **`No services enabled`**: set at least one `BUILD_*=true` in `.env`.
- **The ros2 container can't see Isaac Sim topics**: use the same `ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION` and
  `ROS_DISTRO` everywhere. `config/fastdds.xml` turns off shared memory to avoid permission errors between containers
  running as different users.
- **Files in `build/` or `install/` are owned by root**: run `./scripts/sync_ids.sh`, then `make build`.
- **Headless or remote machine**: in `docker-compose.yml`, change the `isaac-sim` command to `./runheadless.sh` and connect
  with the Isaac Sim WebRTC Streaming Client.

## License

See [LICENSE](LICENSE).
