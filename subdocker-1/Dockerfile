# subdocker-1 Dockerfile
FROM debian:latest

# Update package list and install curl
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the command script into the image
COPY run-commands.sh /usr/local/bin/run-commands.sh

# Set the script as the default command
CMD ["bash", "/usr/local/bin/run-commands.sh"]
