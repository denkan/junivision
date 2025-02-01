#!/bin/bash

echo "🚀 Starting full installation..."

# Run WiFi router setup
echo -n "Do you want to set up WiFi Router? (y/n): "
read setup_wifi
if [[ "$setup_wifi" == "y" ]]; then
    echo "🔧 Setting up WiFi Router..."
    bash wifi_router_setup.sh
    echo "✅ WiFi Router setup complete!"
else
    echo "⏭️ Skipping WiFi Router setup."
fi

# Run video streaming setup
echo -n "Do you want to set up Video Streaming? (y/n): "
read setup_video
if [[ "$setup_video" == "y" ]]; then
    echo "🎥 Setting up Video Streaming..."
    bash video_setup.sh
    echo "✅ Video Streaming setup complete!"
else
    echo "⏭️ Skipping Video Streaming setup."
fi

# Run web server setup
echo -n "Do you want to set up Web Server? (y/n): "
read setup_web
if [[ "$setup_web" == "y" ]]; then
    echo "🌐 Setting up Web Server..."
    bash web_setup.sh
    echo "✅ Web Server setup complete!"
else
    echo "⏭️ Skipping Web Server setup."
fi

echo "🎉 All selected services are now running!"

echo -n "Do you want to reboot now? (y/n): "
read reboot_choice
if [[ "$reboot_choice" == "y" ]]; then
    echo "🔄 Rebooting system to apply all changes..."
    sleep 5
    sudo reboot
else
    echo "🚀 Setup complete! Reboot manually if needed."
fi
