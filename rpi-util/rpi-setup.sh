#/bin/bash

fail() {
	echo "ERROR!: $1"
}

echo "Enabling SSH"
systemctl enable ssh
systemctl start ssh

echo "Setting locale"
localectl set-locale LANG=en_US.UTF-8

echo "Setting user password"
passwd pi

echo "Updating packages"
apt update
apt upgrade

echo "Changing config files"
echo "dtoverlay=pi3-disable-wifi" >> /boot/config.txt

echo "Installing bluetooth pkgs"
apt install bluez-tools -y

echo "Configuring bluetooth"
cat > /etc/systemd/network/pan0.netdev << EOF
[NetDev]
Name=pan0
Kind=bridge
EOF

cat > /etc/systemd/network/pan0.network << EOF
[Match]
Name=pan0

[Network]
Address=172.20.1.1/24
DHCPServer=yes
EOF

cat > /etc/systemd/system/bt-agent.service << EOF
[Unit]
Description=Bluetooth Auth Agent

[Service]
ExecStart=/usr/bin/bt-agent -c NoInputNoOutput
Type=simple

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/bt-network.service << EOF
[Unit]
Description=Bluetooth NEP PAN
After=pan0.network

[Service]
ExecStart=/usr/bin/bt-network -s nap pan-
Type=simple

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling bluetooth services"
systemctl enable systemd-networkd
systemctl enable bt-agent
systemctl enable bt-network

echo "Starting bluetooth services"
systemctl start systemd-networkd
systemctl start bt-agent
systemctl start bt-network

echo "Changing hostname"
echo "ssss-pi" > /etc/hostname
