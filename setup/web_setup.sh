#!/bin/bash

echo "📡 Setting up Node.js Express server..."

# Install Node.js and npm if not installed
sudo apt update && sudo apt install -y nodejs npm

# Install dependencies inside the web directory
npm i --prefix ../web

# Create systemd service file for Node.js server
sudo tee /etc/systemd/system/node_web_server.service <<EOL
[Unit]
Description=JuniVision Web Server
After=network.target

[Service]
ExecStart=/usr/bin/node /home/junivision/junivision/web/server.js
Restart=always
User=junivision
WorkingDirectory=/home/junivision/junivision/web

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the Node.js web server
sudo systemctl daemon-reload
sudo systemctl enable node_web_server.service
sudo systemctl start node_web_server.service

echo "✅ Node.js Express server is now running and will start on boot!"
