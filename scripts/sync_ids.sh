#!/usr/bin/env bash
# Write the host user's UID/GID into .env so workspace files stay owned by you.
cd "$(dirname "$0")/.."
sed -i "s/^USER_UID=.*/USER_UID=$(id -u)/; s/^USER_GID=.*/USER_GID=$(id -g)/" .env
echo "USER_UID=$(id -u) USER_GID=$(id -g) written to .env"
