#!/bin/bash

echo -n "Making auto-darkmode-switcher-script executable... "
THEME_SWITCHER_SCRIPT=$(realpath $(dirname $0))/auto-darkmode-switcher.sh
if ! chmod +x "$THEME_SWITCHER_SCRIPT"; then
	echo "FAILED"
	echo "Execute this script with sudo maybe?"
	exit 1
fi
echo "OK"

echo "Creating startup-service..."
# create startup service
SERVICE_FILE=/etc/systemd/user/auto-darkmode-switcher.service
sudo rm -f "$SERVICE_FILE"
echo "[Service]
ExecStart="$THEME_SWITCHER_SCRIPT"
[Install]
WantedBy=default.target" | sudo tee -a "$SERVICE_FILE" > /dev/null
systemctl --user enable $(basename "$SERVICE_FILE")

echo "Starting auto-darkmode-switcher..."

# execute script once to kick it off
/bin/bash "$THEME_SWITCHER_SCRIPT"

if [ $? != "0" ]; then
	echo "Installation failed!"
	exit $?
fi

echo "Installation done."
echo "Your themes will now be changed automatically to light and darkmode at boot and at sunrise and sunset."
