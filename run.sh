#!/bin/bash
# Allow Docker to access the host display
xhost +local:docker

# Build and run the simulation container
docker compose up --build
