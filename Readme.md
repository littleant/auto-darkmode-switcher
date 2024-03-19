# What does this script do?

It sets the light-theme at sunrise and automatically switches to the dark-theme at sunset.
It also sets the prefer-light/prefer-dark value to indicate to programs and websites which version you prefer.

# Installation

1. Open the script and add your Latitude, Longitude and preferred themes.
2. Execute the install script once: `sh /install.sh`.
3. If it complains about dependencies, install them and execute it again.

# Troubleshooting

Execute `systemctl --user list-timers`. If all went well, there should be a "auto-darkmode-switcher.time"-unit in the list. Exit by pressing "q".

# How to stop the script

Execute `systemctl --user stop auto-darkmode-switcher.timer`.

Follow the install-instructions if you want to start it again.
