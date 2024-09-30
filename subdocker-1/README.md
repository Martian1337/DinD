# Subdocker-1

This folder contains the necessary files to build and run the `subdocker-1` container in a Docker-in-Docker (DinD) environment.

## Overview

The `subdocker-1` container is based on a Debian image and is designed to run a simple command using `curl`. The container is built using the Dockerfile provided in this directory.

## Directory Structure

- **Dockerfile**: Defines the Docker image for `subdocker-1`, including the installation of `curl` and the command script to execute.
- **build-subdocker-1.sh**: Script for building and running the `subdocker-1` container.
- **run-commands.sh**: A script that will be executed when the container starts. It allows you to run commands inside the container.

## Building the Container

To build and run the `subdocker-1` container, use the following command:

```bash
./build-subdocker-1.sh
```

This will:
1. Build the Docker image from the Dockerfile.
2. Run the container in detached mode.

## Usage

Once the `subdocker-1` container is running, you can interact with it in the following ways:

### Execute Commands

You can execute commands inside the container. When prompted, enter the command you want to run.

### Interactive Shell

To enter an interactive shell in the `subdocker-1` container, use the following command:

```bash
docker exec -it subdocker-1-container bash
```

- `-it` enables interactive mode.
- `subdocker-1-container` is the name of the running container.

## Example Commands

Here are some example commands you can run in the `subdocker-1` container:

- **Check the installed version of curl**:
  ```bash
  curl --version
  ```

- **Make a request to an external website**:
  ```bash
  curl http://example.com
  ```

## Important Notes

- Ensure that the Docker daemon is running before building or running the containers.
- If you make any changes to the Dockerfile, remember to rebuild the image for the changes to take effect.

## Security Considerations

Be cautious when running commands inside the container, especially those that require elevated permissions or sensitive information. Always follow best practices for security in a Docker environment.
