# husky-autonomous-inspection

ROS 2 Jazzy simulation of a Clearpath Husky A200 with a SICK LMS1xx 2D LiDAR performing SLAM-based map building in Gazebo Harmonic.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- A host display available at `$DISPLAY` (Linux X11 or XWayland)

## Getting Started

### 1. Open in Dev Container

Clone the repo and open it in VS Code. When prompted, click **Reopen in Container**. VS Code will build the Docker image and run the one-time setup automatically (`postCreateCommand`).

If you need to re-run setup manually (e.g., after pulling new changes):

```bash
./scripts/setup.sh
```

This links `config/robot.yaml` to the locations Clearpath expects, builds the `slam_mapping` ROS package, and sources the workspace in `.bashrc`.

---

## Running the Full Stack

Open **three terminals** inside the container and run the scripts in order.

### Terminal 1 — Simulation

```bash
./scripts/start_sim.sh
```

Launches Gazebo Harmonic with the Husky A200. Wait until the robot appears in the scene before proceeding.

### Terminal 2 — SLAM + Foxglove

```bash
./scripts/start_mapping.sh
```

Starts two processes:
- **SLAM Toolbox** (`async_slam_toolbox_node`) — builds a `/map` from the LiDAR scan at `/a200_0000/sensors/lidar2d_0/scan`
- **Foxglove bridge** — streams ROS topics over WebSocket at `ws://localhost:8765`

Run this **after** the simulation is fully loaded.

### Terminal 3 — Teleoperation

```bash
./scripts/teleop.sh
```

Drive the robot to explore the environment and build the map. **Keep this terminal focused** — keypresses go to whichever window has focus.

Hold a key to move; release it to stop. `W+A` / `W+D` combinations work simultaneously.

| Key | Action |
|-----|--------|
| `W` | Forward |
| `S` | Backward |
| `A` | Turn left |
| `D` | Turn right |
| `Q` | Quit |

---

## Visualizing in Foxglove

1. Open [https://app.foxglove.dev](https://app.foxglove.dev) in your browser
2. Click **Open connection** → WebSocket → `ws://localhost:8765`
3. Add a **3D panel** and subscribe to:
   - `/map` — occupancy grid (updates as you drive)
   - `/a200_0000/sensors/lidar3d_0/points` — live VLP-16 point cloud (360°)
   - `/a200_0000/sensors/lidar3d_0/scan` — 2D laser scan fed into SLAM

---

## Saving the Map

Once the map looks complete, run from any terminal:

```bash
./scripts/save_map.sh
```

Saves two files to `maps/`:
- `maps/map.yaml` — map metadata
- `maps/map.pgm` — occupancy grid image

---

## Script Reference

| Script | When to run | What it does |
|--------|-------------|--------------|
| `scripts/setup.sh` | Once, after container creation | Symlinks robot config, builds ROS packages |
| `scripts/start_sim.sh` | Terminal 1 | Launches Gazebo simulation |
| `scripts/start_mapping.sh` | Terminal 2, after sim loads | Starts SLAM Toolbox + Foxglove bridge |
| `scripts/teleop.sh` | Terminal 3 | Keyboard teleoperation |
| `scripts/save_map.sh` | Any terminal, when done mapping | Saves map to `maps/` |

## Architecture

```
Gazebo Harmonic
  └── Husky A200 (namespace: a200_0000)
        ├── /a200_0000/cmd_vel                    ← teleop input
        └── /a200_0000/sensors/lidar3d_0/points   ← Velodyne VLP-16 (360°)
                └── pointcloud_to_laserscan
                      └── /scan_3d
                            └── SLAM Toolbox
                                  └── /map        → Foxglove Studio
```

Robot config lives in `config/robot.yaml` (Clearpath standard format). SLAM parameters are in `src/slam_mapping/config/slam_params.yaml`.
