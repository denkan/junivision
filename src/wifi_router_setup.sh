#!/bin/bash

echo "📡 Installing and configuring web server..."

# Install Nginx
sudo apt update && sudo apt install -y nginx

# Create webpage index file
sudo tee /var/www/html/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Live Video Streams</title>
    <script>
        function switchStream(stream) {
            document.getElementById("video-stream").src = stream;
        }
    </script>
</head>
<body>
    <h2>Live Video Stream</h2>
    <video id="video-stream" controls autoplay>
        <source src="udp://192.168.10.1:5000" type="application/x-rtp">
    </video>
    
    <div>
        <button onclick="switchStream('udp://192.168.10.1:5000')">MOKOSE 4K USB Camera</button>
        <button onclick="switchStream('udp://192.168.10.1:5001')">Logitech MX Brio 4K USB Camera</button>
    </div>
    
    <p>🔗 Open this page on your tablet: <strong>http://192.168.10.1/</strong></p>
</body>
</html>
EOL

# Restart Nginx
sudo systemctl restart nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Create systemd service to ensure Nginx auto-restarts
sudo tee /etc/systemd/system/nginx_restart.service <<EOL
[Unit]
Description=Ensure Nginx is always running
After=network.target

[Service]
ExecStart=/bin/systemctl restart nginx
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the Nginx auto-restart service
sudo systemctl daemon-reload
sudo systemctl enable nginx_restart.service
sudo systemctl start nginx_restart.service

echo "✅ Web server configured and auto-restart enabled!"
