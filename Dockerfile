FROM debian:latest

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt update && apt install -y --no-install-recommends \
    hostapd dnsmasq ffmpeg mjpeg-streamer nginx curl sudo \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /root

# Copy setup files into container
COPY ./src/ /root/

# Make setup scripts executable
RUN chmod +x /root/*.sh

# Expose necessary ports
EXPOSE 80 8080

# Run the setup script on container start
CMD ["/bin/bash", "-c", "bash /root/setup.sh && tail -f /dev/null"]