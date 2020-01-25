#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then 
	echo "Please run as root"
	exit 1
fi

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

if ! sdptool browse local; then 
	echo "sdptool FAILURE! Ain't good"
	exit 1
fi

hciconfig hci0 piscan
