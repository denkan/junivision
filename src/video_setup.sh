#!/bin/bash

echo "📡 Installing video streaming..."

# Install necessary software
sudo apt update && sudo apt install -y ffmpeg gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

# Create directory for video streams
sudo mkdir -p /var/www/html/streams
sudo chmod -R 777 /var/www/html/streams

# Get the dynamic IP address of the Raspberry Pi
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Detected IP Address: $IP_ADDRESS"

# Create systemd service file for video streaming
sudo tee /etc/systemd/system/video_streaming.service <<EOL
[Unit]
Description=USB Camera Streaming with GStreamer
After=network.target

[Service]
ExecStart=/usr/local/bin/start_video_streams.sh
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOL

# Create script to start video streams
sudo tee /usr/local/bin/start_video_streams.sh <<EOL
#!/bin/bash

echo "🚀 Starting Logitech MX Brio 4K USB camera stream with GStreamer (HLS)..."
gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw, format=YUY2, width=3840, height=2160, framerate=5/1 ! videoconvert ! x264enc tune=zerolatency bitrate=2048 speed-preset=ultrafast key-int-max=15 ! h264parse ! mpegtsmux ! hlssink location=/var/www/html/stream-%05d.ts target-duration=1 max-files=3 playlist-location=/var/www/html/stream.m3u8 playlist-length=3 &

echo "✅ Logitech MX Brio is streaming via HLS at http://$IP_ADDRESS/stream.m3u8!"
EOL

# Make the script executable
sudo chmod +x /usr/local/bin/start_video_streams.sh

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable video_streaming.service
sudo systemctl start video_streaming.service

echo "✅ Video streaming service is now set to start on boot!"
