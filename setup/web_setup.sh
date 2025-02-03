#!/bin/bash

echo "📡 Setting up Node.js Express server..."

# Install Node.js and npm if not installed
sudo apt update && sudo apt install -y nodejs npm

# Install dependencies inside the web directory
npm i --prefix /home/junivision/junivision/web/

# Create systemd service file for Node.js server
sudo tee /etc/systemd/system/junivision_web.service <<EOL
[Unit]
Description=JuniVision Web Server
After=network.target

[Service]
ExecStart=/usr/bin/node /home/junivision/junivision/web/server.js
Restart=always
User=root
WorkingDirectory=/home/junivision/junivision/web
Environment=NODE_ENV=production
Environment=PORT=80


[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the Node.js web server
sudo systemctl daemon-reload
sudo systemctl enable junivision_web.service
sudo systemctl start junivision_web.service

echo "✅ JuniVision web server is now running and will start on boot!"
