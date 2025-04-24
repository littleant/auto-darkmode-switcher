#!/bin/bash

# your location (get it from Google Maps-URL, for example):
LATITUDE="48.2092384"
LONGITUDE="16.3619745"

# To see what gtk-theme/icon-theme is currently enabled, execute this command:
# gsettings get org.gnome.desktop.interface gtk-theme
# gsettings get org.gnome.desktop.interface icon-theme

# To see available themes and icons:
# ls /usr/share/themes/
# ls /usr/share/icons/
LIGHT_GTK_THEME="Yaru"
DARK_GTK_THEME="Yaru-dark"

LIGHT_ICON_THEME="Yaru"
DARK_ICON_THEME="Yaru-dark"

# All GTK-themes that have a subfolder named 'gnome-shell' should work, e.g. /usr/share/themes/Yaru/gnome-shell for the 'Yaru'-theme.
LIGHT_SHELL_THEME="Yaru"
DARK_SHELL_THEME="Yaru-dark"

# Where to save your day and night GNOME Terminal profiles at.
# To modify a profile later on do the following:
# 1. Open a GNOME Terminal (press [Alt]+[Shift]+[T]), and do all the modifications you want to save.
# 2. Execute `dconf dump /org/gnome/terminal/legacy/profiles:/ > ${CONFIG_DIR}/day-terminal-profile.dconf` to save the changes as the day-profile.
#    Replace ${CONFIG_DIR} with the config-dir you specified below, and change "day" to "night", if you want to change the night-profile instead.
# If you just delete the directory or files, then they will be recreated on the next theme-switch, saving the currently active changes.
# You can execute the install.sh-script, if you don't want to wait that long.
CONFIG_DIR="${HOME}/.config/auto-darkmode-switcher"

# Cinnamon desktop only:
LIGHT_CURSOR_THEME="Bibata-Modern-Ice"
DARK_CURSOR_THEME="Bibata-Modern-Classic"

#
#
# Do not edit below this line.
# (Unless you know what you are doing.)
#
#

export DISPLAY=:0

echo -n "Checking dependencies... "

missing_deps=0
for name in hdate; do
	[[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name needs to be installed. Use 'sudo apt install $name' to install it.";missing_deps=$((missing_deps+1)); }
done

if ! which gnome-extensions >/dev/null 2>&1; then
	# The gnome-shell-extensions package contains the gnome-extensions command.
	name=gnome-shell-extensions
	echo -en "\nThe gnome-extensions command needs to be installed. Use 'sudo apt install $name' to install it.\nIf you still see this message after installing it, try pressing [Alt]+[F2] and type 'r' into the prompt to reload the gnome-shell."
	missing_deps=$((missing_deps+1))
elif ! gnome-extensions list | grep -q 'user-theme@gnome-shell-extensions.gcampax.github.com'; then
	# The gnome-shell-extensions package contains the user-theme shell-extension.
	name=gnome-shell-extensions
	echo -en "\nThe user-theme shell-extension needs to be installed. Use 'sudo apt install $name' to install it.\nIf you still see this message after installing it, try pressing [Alt]+[F2] and type 'r' into the prompt to reload the gnome-shell."
	missing_deps=$((missing_deps+1))
fi

if (( $missing_deps == 0 )); then
	echo "OK"
else
	echo -en "\nInstall the above and rerun this script.\n"
	exit 1
fi

echo -n "Enabling gnome-shell-extension 'user-theme'... "
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null
if ! gnome-extensions info user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null | grep -q 'Status: ACTIVE'; then
	echo "FAILED"
	echo "Please try the following:"
	echo "1. Press [Alt]+[F2] and type 'r' into the prompt to reload the gnome-shell."
	echo "2. Execute 'gnome-extensions-app' and enable the top slider labeled 'Extensions'."
	echo "3. Execute this script again."
	exit 1 
fi
echo "OK"

TIMEZONE_OFFSET=$(date +'%z' | sed -r 's/(.{3})/\1:/' | sed -r 's/([+-])(0)?(.*)/\1\3/')
HDATE_TODAY=$(hdate -s --not-sunset-aware -l "$LATITUDE" -L "$LONGITUDE" -z$TIMEZONE_OFFSET)
SUNRISE_TODAY=$(echo "$HDATE_TODAY" | grep "sunrise: " | grep -o '[0-2][0-9]:[0-6][0-9]')
SUNSET_TODAY=$(echo "$HDATE_TODAY" | grep "sunset: " | grep -oE '[0-2][0-9]:[0-6][0-9]')

echo "Todays sunrise: $SUNRISE_TODAY"
echo "Todays sunset:  $SUNSET_TODAY"

NOW=$(date +"%Y-%m-%d %H:%M:%S")

echo "Current date and time: $NOW"

COMPARABLE_NOW=$(date --date="$NOW" +%Y%m%d%H%M)
COMPARABLE_SUNRISE_TODAY=$(date --date="$SUNRISE_TODAY" +%Y%m%d%H%M)
COMPARABLE_SUNSET_TODAY=$(date --date="$SUNSET_TODAY" +%Y%m%d%H%M)

if [ $COMPARABLE_NOW -gt $COMPARABLE_SUNRISE_TODAY ] && [ $COMPARABLE_NOW -lt $COMPARABLE_SUNSET_TODAY ]; then
	echo "Setting day theme..."

	gsettings set org.gnome.desktop.interface color-scheme prefer-light
	gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK_THEME"
	gsettings set org.gnome.desktop.interface icon-theme "$LIGHT_ICON_THEME"
	gsettings set org.gnome.shell.extensions.user-theme name "$LIGHT_SHELL_THEME"

	# Handle the GNOME terminal profile:
	# If we don't find the day-profile, assume that the current profile should be used as the day-profile.
	# If we find the day-profile, don't overwrite it.
	mkdir -p $CONFIG_DIR
	if [ ! -f ${CONFIG_DIR}/day-terminal-profile.dconf ]; then
		echo -n "Couldn't find the GNOME Terminal day-profile. Saving current profile as day-profile... "
		if dconf dump /org/gnome/terminal/legacy/profiles:/ > ${CONFIG_DIR}/day-terminal-profile.dconf; then
			echo "OK"
		else
			echo "FAILED"
			echo "Will try again next execution!"
		fi
	else
		# Loading the GNOME Terminal day-profile
		TERMINAL_PROFILE=${CONFIG_DIR}/day-terminal-profile.dconf
		echo -n "Loading GNOME Terminal profile from ${TERMINAL_PROFILE}... "
		if dconf load /org/gnome/terminal/legacy/profiles:/ < $TERMINAL_PROFILE; then
			echo "OK"
		else
			echo "FAILED"
		fi
	fi

	# Does the user have the Cinnamon desktop installed?
	if gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null; then
		# Cinnamon desktop supports cursor themes, so switch it
		gsettings set org.cinnamon.desktop.interface cursor-theme "$LIGHT_CURSOR_THEME"
	fi

	# execute this script at sunset again
	NEXT_EXECUTION_AT=$(date --date="$SUNSET_TODAY 1 minute" +"%Y-%m-%d %H:%M")
else
	echo "Setting night theme..."

	gsettings set org.gnome.desktop.interface color-scheme prefer-dark
	gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
	gsettings set org.gnome.desktop.interface icon-theme "$DARK_ICON_THEME"
	gsettings set org.gnome.shell.extensions.user-theme name "$DARK_SHELL_THEME"

	# Handle the GNOME terminal profile:
	# If we don't find the night-profile, assume that the current profile should be used as the night-profile.
	# If we find the night-profile, don't overwrite it.
	mkdir -p $CONFIG_DIR
	if [ ! -f ${CONFIG_DIR}/night-terminal-profile.dconf ]; then
		echo -n "Couldn't find the GNOME Terminal night-profile. Saving current profile as night-profile... "
		if dconf dump /org/gnome/terminal/legacy/profiles:/ > ${CONFIG_DIR}/night-terminal-profile.dconf; then
			echo "OK"
		else
			echo "FAILED"
			echo "Will try again next execution!"
		fi
	else
		# Loading the GNOME Terminal night-profile
		TERMINAL_PROFILE=${CONFIG_DIR}/night-terminal-profile.dconf
		echo -n "Loading GNOME Terminal profile from ${TERMINAL_PROFILE}... "
		if dconf load /org/gnome/terminal/legacy/profiles:/ < $TERMINAL_PROFILE; then
			echo "OK"
		else
			echo "FAILED"
		fi
	fi

	# Does the user have the Cinnamon desktop installed?
	if gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null; then
		# Cinnamon desktop supports cursor themes, so switch it
		gsettings set org.cinnamon.desktop.interface cursor-theme "$DARK_CURSOR_THEME"
	fi

	if [ $COMPARABLE_NOW -gt $COMPARABLE_SUNSET_TODAY ]; then
		# execute this script tomorrow at sunrise again
		TOMORROW=$(date -d 'now +1 day' +'%Y-%m-%d %H:%M:%S')
		TOMORROW_YEAR=$(date -d "$TOMORROW" +'%Y')
		TOMORROW_MONTH=$(date -d "$TOMORROW" +'%m')
		TOMORROW_DAY=$(date -d "$TOMORROW" +'%d')

		HDATE_TOMORROW=$(hdate -s --not-sunset-aware -l "$LATITUDE" -L "$LONGITUDE" -z$TIMEZONE_OFFSET $TOMORROW_DAY $TOMORROW_MONTH $TOMORROW_YEAR)
		SUNRISE_TOMORROW=$(echo "$HDATE_TOMORROW" | grep "sunrise: " | grep -o '[0-2][0-9]:[0-6][0-9]')

		echo "Sunrise tomorrow: $SUNRISE_TOMORROW"

		NEXT_EXECUTION_AT=$(date --date="$SUNRISE_TOMORROW 1 day 1 minute" +"%Y-%m-%d %H:%M")
	else
		# execute this script today at sunrise again
		NEXT_EXECUTION_AT=$(date --date="$SUNRISE_TODAY 1 minute" +"%Y-%m-%d %H:%M")
	fi
fi

# set next execution-time of this script
echo "Next execution of the auto-darkmode-switcher-script: $NEXT_EXECUTION_AT"

# remove an already existing timer, if one exists
systemctl --user stop auto-darkmode-switcher.timer 2> /dev/null

# specifying a fixed "unit" avoids adding the timer again, if it exists already.
systemd-run --user --no-ask-password --on-calendar "$NEXT_EXECUTION_AT" --unit="auto-darkmode-switcher" --collect
