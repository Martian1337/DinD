# Docker-in-Docker Project with Traefik

This project demonstrates how to set up a Docker-in-Docker (DinD) environment with Traefik as a reverse proxy. The main DinD container automatically builds and runs sub-dockers. Sub-dockers can be built from local Dockerfiles or pulled directly from Docker Hub. Additionally, you can execute commands on the sub-dockers after they are running or enter an interactive shell.

## Getting Started

### Prerequisites

Ensure you have Docker and Docker Compose installed on your machine.

### Usage

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/docker-in-docker-project.git
   cd docker-in-docker-project
   ```

2. **Make all scripts executable**:
   ```bash
   chmod +x *.sh
   chmod +x subdocker-*/build-subdocker-*.sh
   ```

3. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

4. **Optional: If you have multiple subdockers and want to build them, you can run after you are done building**:
   ```bash
   for dir in subdocker-*; do
       chmod +x "$dir"/build-subdocker-*.sh
       ./"$dir"/build-subdocker-*.sh
   done
   ```

This allows the user to easily handle multiple subdocker names without needing to specify each one individually. The loop will ensure that all `build-subdocker-*.sh` scripts in the subdocker directories are executed.

   This script will build the necessary Docker images and start the containers for DinD and Traefik.

3. **Execute Commands**: After the setup, you can choose to execute a specific command in `subdocker-1`. When prompted, enter the command you want to run.

4. **Interactive Shell**: You can also choose to enter an interactive shell in `subdocker-1` after the setup.
   ```bash
   docker exec -it subdocker-1-container bash
   ```
- `docker exec` This command is used to run a new command in a running container.
- `-it` These options enable interactive mode.
- `-i` keeps the standard input (STDIN) open.
- `-t` allocates a pseudo-TTY, which is necessary for interactive terminal applications.
- `subdocker-1-container`: This is the name of the container you want to access.
- `bash`: This specifies the command you want to run inside the container, which in this case is the Bash shell.


## Security Considerations

When using Docker-in-Docker, security is a major concern due to the sharing of the Docker socket. Here are a few security practices:

- **User Permissions**: It is recommended to create a non-root user within the DinD container to run applications with limited permissions. Modify your Dockerfile as follows:

    ```dockerfile
    # Example: Adding a non-root user
    RUN useradd -ms /bin/bash dinduser
    USER dinduser
    ```

- **Environment Variables**: Use environment variables for sensitive information, such as API keys or secrets, to avoid hardcoding them in your scripts.

## Persistent Storage

Managing persistent storage is crucial, especially for applications like databases or services that need to retain data between restarts. Here's how to define volumes in your `docker-compose.yml` for persistent data.

### Example Persistent Storage Configuration in `docker-compose.yml`

```yaml
version: '3.8'

services:
  subdocker-1:
    build:
      context: ./subdocker-1
    networks:
      my_custom_network:
        ipv4_address: 192.168.1.10
    volumes:
      - subdocker-1-data:/data  # Volume for persistent storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]  # Change the URL to match your service
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  subdocker-1-data:  # Named volume definition
```

In this example, a named volume `subdocker-1-data` is created and mounted to the `/data` directory inside `subdocker-1`. Any data written to `/data` will be retained in the volume, even if the container is removed.

To verify that the data is indeed persistent, you can run the following commands:

1. **Start the containers**:
   ```bash
   docker-compose up -d
   ```

2. **Access the subdocker and create a file**:
   ```bash
   docker exec -it subdocker-1-container bash
   echo "Hello, Persistent World!" > /data/hello.txt
   exit
   ```

3. **Stop and remove the containers**:
   ```bash
   docker-compose down
   ```

4. **Start the containers again**:
   ```bash
   docker-compose up -d
   ```

5. **Check if the file still exists**:
   ```bash
   docker exec -it subdocker-1-container bash
   cat /data/hello.txt  # Should output: Hello, Persistent World!
   ```


## Health Checks

You can add health checks to monitor the status of your services. Below is an example health check configuration for `subdocker-1`, which will periodically make an HTTP request to the service to verify it is up and running.

### Example Health Check Configuration in `docker-compose.yml`

```yaml
  subdocker-1:
    build:
      context: ./subdocker-1
    networks:
      my_custom_network:
        ipv4_address: 192.168.1.10
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]  # Change the URL to match your service
      interval: 30s  # Check every 30 seconds
      timeout: 10s   # Timeout after 10 seconds
      retries: 3     # Retry up to 3 times before marking as unhealthy
```

## Error Handling

To improve error handling in your build and run scripts, you can check the exit status of commands. Here’s an example of how to implement error handling in the `build-subdocker-1.sh` script:

```bash
#!/bin/bash

echo "Building subdocker-1 from local Dockerfile..."
if ! docker build -t subdocker-1 .; then
    echo "Failed to build subdocker-1"
    exit 1
fi

echo "Running subdocker-1..."
if ! docker run --name subdocker-1-container -d subdocker-1; then
    echo "Failed to run subdocker-1"
    exit 1
fi
```

## Traefik Configuration

This project uses Traefik to manage routing to sub-dockers. The Traefik configuration is defined in the `docker-compose.yml` file.

1. **Traefik Service**: The following configuration sets up Traefik to handle incoming requests:

```yaml
  traefik:
    image: traefik:v2.5
    command:
      - "--api.insecure=true"  # Enable the Traefik dashboard (not for production)
      - "--providers.docker=true"  # Enable Docker provider
      - "--entrypoints.web.address=:80"  # Listen on port 80
    ports:
      - "80:80"  # Expose port 80
      - "8080:8080"  # Expose the Traefik dashboard
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"  # Access Docker socket
```

## Sub-Docker Builds

This project demonstrates two methods for running sub-dockers within the DinD environment:

### 1. Build a Sub-Docker from a Local Dockerfile

The script `build-subdocker-1.sh` is responsible for building and running `subdocker-1` using a local Dockerfile.

The local Dockerfile for `subdocker-1` installs a basic tool (in this case, `curl`):

```dockerfile
# subdocker-1 Dockerfile
FROM debian:latest

# Update package list and install curl
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the command script into the image
COPY run-commands.sh /usr/local/bin/run-commands.sh

# Set the script as the default command
CMD ["bash", "/usr/local/bin/run-commands.sh"]
```

### 2. Pull and Run a Pre-Built Sub-Docker from Docker Hub

The script `build-subdocker-2.sh` pulls a pre-built image from Docker Hub and runs it as a container.

## Port and IP Assignments

For better network management, this project uses custom IP addresses and port assignments in the Docker network configuration. The `docker-compose.yml` file specifies the network settings, allowing you to define static IPs for each service.

### Example IP Assignment in `docker-compose.yml`

```yaml
  subdocker-1:
    build:
      context: ./subdocker-1
    networks:
      my_custom_network:
        ipv4_address: 192.168.1.10

  subdocker-2:
    image: nginx:latest
    networks:
      my_custom_network:
        ipv4_address: 192.168.1.20
