#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then 
	echo "Please run as root"
	exit 1
fi


echo -n "Overwriting /lib/systemd/system/bluetooth.service..."
cat > /lib/systemd/system/bluetooth.service << EOF
[Unit]
Description=Bluetooth service
Documentation=man:bluetoothd(8)
ConditionPathIsDirectory=/sys/class/bluetooth

[Service]
Type=dbus
BusName=org.bluez
ExecStart=/usr/lib/bluetooth/bluetoothd --compat
NotifyAccess=main
#WatchdogSec=10
#Restart=on-failure
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
LimitNPROC=1
ProtectHome=true
ProtectSystem=full

[Install]
WantedBy=bluetooth.target
Alias=dbus-org.bluez.service
EOF
echo "OK"

echo -n "Testing with sdptool..."
if ! sdptool browse local &> /dev/null; then 
	echo "sdptool FAILURE! Ain't good"
	exit 1
fi
echo "OK"

echo -n "Configuring hci0..."
hciconfig hci0 piscan
echo "OK"
