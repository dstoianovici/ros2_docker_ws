#!/usr/bin/env bash
# Allow local containers to open GUI windows on the host X server.
xhost +local:docker >/dev/null && echo "X11 access granted to local docker containers"
