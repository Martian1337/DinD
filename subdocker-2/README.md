# Subdocker-2

Subdocker-2 is set up to run an Nginx server using the official Nginx image from Docker Hub. This directory contains the necessary scripts and configuration to pull and run the Nginx container.

## Purpose

This subdocker serves as an example of how to run a pre-built Docker image from Docker Hub. It provides a simple Nginx server that can be accessed through the Traefik reverse proxy set up in the main Docker-in-Docker project.

## Files in this Directory

- **`build-subdocker-2.sh`**: A script that pulls the latest Nginx image from Docker Hub and runs it as a container.
- **`run-commands.sh`**: A script that allows for executing commands inside the running Nginx container.

## Running Subdocker-2

You can run Subdocker-2 by executing the `build-subdocker-2.sh` script from the main directory. This script will handle pulling the Nginx image and starting the container.

To execute a command inside the running Nginx container, use the `run-commands.sh` script. You can specify the command you want to execute as an argument when running this script.

### Example Command Execution

To execute a command inside the Nginx container:

```bash
cd ../subdocker-2  # Navigate to the subdocker-2 directory
./run-commands.sh <your-command>  # Replace <your-command> with the desired command
```

### Accessing Nginx

After running Subdocker-2, you can access the Nginx server through the Traefik reverse proxy at `http://localhost`.

## Health Checks

A health check is managed in the main DinD configuration. Since Subdocker-2 is based on an official Docker Hub image, the health check is optional and can be configured in the main `docker-compose.yml` file if needed.
