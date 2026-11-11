#!/usr/bin/env bash
# One-time host setup for Ubuntu 22.04 / 24.04:
# Docker Engine + Compose plugin + NVIDIA Container Toolkit + Isaac Sim cache dirs.
# Prerequisite: NVIDIA driver installed (check with `nvidia-smi`).
set -euo pipefail

if ! command -v nvidia-smi >/dev/null; then
  echo "nvidia-smi not found. Install the NVIDIA driver first (e.g. 'sudo ubuntu-drivers install')." >&2
  exit 1
fi

if ! command -v docker >/dev/null; then
  echo ">> Installing Docker Engine"
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo ">> Added $USER to 'docker' group. Log out/in for it to take effect."
fi

if ! dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
  echo ">> Installing NVIDIA Container Toolkit"
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi

# Isaac Sim cache dirs (Isaac Sim container runs as uid 1234)
CACHE="${ISAAC_SIM_CACHE:-$HOME/docker/isaac-sim}"
mkdir -p "$CACHE"/{cache/main,cache/computecache,logs,config,data,pkg,documents}
sudo chown -R 1234:1234 "$CACHE"

echo ">> Verifying GPU access in Docker"
sudo docker run --rm --gpus all ubuntu nvidia-smi

echo ">> Done. Log in to NGC to pull Isaac Sim: docker login nvcr.io  (user: \$oauthtoken, password: <NGC API key>)"
