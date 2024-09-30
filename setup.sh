#!/bin/bash

# This script sets up the Docker-in-Docker environment with Traefik and the sub-dockers.

# Function to build and run a sub-docker
build_and_run_subdocker() {
    local subdocker_name=$1
    echo "Building and running $subdocker_name..."
    if ! ./subdocker-scripts/build-"$subdocker_name".sh; then
        echo "Failed to build and run $subdocker_name"
        exit 1
    fi
}

# Start Docker-in-Docker
echo "Starting Docker-in-Docker..."
docker run --privileged --name dind -d docker:dind

# Start Traefik
echo "Starting Traefik..."
docker-compose up -d traefik

# Build and run subdockers
build_and_run_subdocker "subdocker-1"
build_and_run_subdocker "subdocker-2"

echo "All sub-dockers are up and running!"
