# Service selection comes from BUILD_<NAME> flags in .env.
# Override per call, e.g.:  make build BUILD_ISAAC_SIM=true
COMPOSE     := ./scripts/compose.sh
COMPOSE_ALL := ./scripts/compose.sh --all

.PHONY: help setup build up shell colcon test logs ps down clean

help:           ## List targets
	@grep -E '^[a-z]+:.*##' Makefile | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

setup:          ## One-time host setup (Docker, NVIDIA toolkit, cache dirs, UID/GID)
	./scripts/setup_host.sh
	./scripts/sync_ids.sh

build:          ## Build enabled services (ros2: docker build, isaac_sim: docker pull)
	$(COMPOSE) build
	$(COMPOSE) pull --ignore-buildable

up:             ## Start enabled services
	./scripts/xhost.sh
	$(COMPOSE) up -d

shell:          ## Open a shell in the ROS 2 container
	$(COMPOSE_ALL) exec ros2 bash

colcon:         ## colcon build the workspace inside the ROS 2 container
	$(COMPOSE_ALL) exec ros2 bash -ic "cd /ws && colcon build --merge-install --symlink-install"

test:           ## colcon test inside the ROS 2 container
	$(COMPOSE_ALL) exec ros2 bash -ic "cd /ws && colcon test --merge-install && colcon test-result --verbose"

logs:           ## Follow logs of running services
	$(COMPOSE_ALL) logs -f

ps:             ## Show running services
	$(COMPOSE_ALL) ps

down:           ## Stop all services (regardless of flags)
	$(COMPOSE_ALL) down

clean:          ## Remove colcon build artifacts
	rm -rf build install log
