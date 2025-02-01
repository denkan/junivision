#!/bin/bash

echo "📡 Setting up Raspberry Pi as a WiFi router..."

# Prompt for WiFi details
echo "Enter SSID for the WiFi network:"
read SSID
echo "Enter WiFi password (minimum 8 characters):"
read -s WPA_PASSPHRASE

# Install necessary packages
sudo apt update && sudo apt install -y hostapd dnsmasq

# Configure hostapd
cat <<EOL | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WPA_PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

# Set hostapd config file path
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure DHCP and DNS
cat <<EOL | sudo tee /etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.100,255.255.255.0,24h
EOL

# Enable IP forwarding
sudo sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sudo sysctl -p

# Configure NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c 'iptables-save > /etc/iptables.ipv4.nat'

# Ensure iptables is loaded on boot
cat <<EOL | sudo tee /etc/rc.local
#!/bin/bash
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOL
sudo chmod +x /etc/rc.local

# Restart services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd\ 
sudo systemctl start hostapd
sudo systemctl restart dnsmasq

# Ensure services restart on boot
sudo systemctl enable hostapd dnsmasq

echo "✅ WiFi router setup complete! Your Raspberry Pi is now a WiFi hotspot with SSID: $SSID"