#!/usr/bin/env bash
# docker compose wrapper: enables one compose profile per BUILD_<NAME>=true flag.
#   Flags are read from .env and can be overridden from the environment:
#     BUILD_ISAAC_SIM=true ./scripts/compose.sh up -d
#   --all  enables every profile regardless of flags (used for down/exec/logs).
set -euo pipefail
cd "$(dirname "$0")/.."

all=false
if [[ "${1:-}" == "--all" ]]; then all=true; shift; fi

args=()
enabled=()
while IFS='=' read -r key val; do
  val="${!key:-$val}"                       # environment overrides .env
  val="$(echo "$val" | tr -d '"'"'"' ' | tr '[:upper:]' '[:lower:]')"
  profile="$(echo "${key#BUILD_}" | tr '[:upper:]' '[:lower:]')"
  if $all || [[ "$val" =~ ^(true|1|yes|on)$ ]]; then
    args+=(--profile "$profile")
    enabled+=("$profile")
  fi
done < <(grep -E '^BUILD_[A-Za-z0-9_]+=' .env)

if [[ ${#enabled[@]} -eq 0 ]]; then
  echo "No services enabled. Set BUILD_<NAME>=true in .env (e.g. BUILD_ROS2=true)." >&2
  exit 1
fi

echo ">> profiles: ${enabled[*]}" >&2
exec docker compose "${args[@]}" "$@"
