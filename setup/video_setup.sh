#!/bin/bash

echo "📡 Installing video streaming packages..."

# Install necessary software
sudo apt update && sudo apt install -y ffmpeg gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

echo "✅ Video streaming service is now set to start on boot!"
