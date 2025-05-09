#!/bin/bash

echo -n "Making auto-darkmode-switcher-script executable... "
THEME_SWITCHER_SCRIPT=$(realpath $(dirname $0))/auto-darkmode-switcher.sh
if ! chmod +x "$THEME_SWITCHER_SCRIPT"; then
	echo "FAILED"
	echo "Execute this script with sudo maybe?"
	exit 1
fi
echo "OK"

echo -n "Creating auto-darkmode-switcher.service file... "
SERVICE_FILE_DIR=${HOME}/.local/share/systemd/user
mkdir -p "$SERVICE_FILE_DIR"
SERVICE_FILE=${SERVICE_FILE_DIR}/auto-darkmode-switcher.service
rm -f "$SERVICE_FILE"
cat >"${SERVICE_FILE}" <<EOL
[Unit]
After=gnome-session.target
[Service]
ExecStart="$THEME_SWITCHER_SCRIPT"
[Install]
WantedBy=gnome-session.target
EOL
if systemctl --user enable $(basename "$SERVICE_FILE") >/dev/null 2>&1; then
	echo "OK"
else
	echo "FAIL"
	exit 1
fi

echo "Starting auto-darkmode-switcher..."

# execute script once to kick it off
/bin/bash "$THEME_SWITCHER_SCRIPT"

if [ $? != "0" ]; then
	echo "Installation failed!"
	exit 1
fi

echo "Installation done."
echo "Your themes will now be changed automatically to light and darkmode at GNOME startup and at sunrise and sunset."
