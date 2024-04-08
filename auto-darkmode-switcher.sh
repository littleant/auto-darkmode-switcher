#!/bin/bash

# your location (get it from Google Maps-URL, for example):
LATITUDE="48.2092384"
LONGITUDE="16.3619745"

# To see what theme/icon is currently enabled, execute this command:
# gsettings get org.gnome.desktop.interface gtk-theme
# gsettings get org.gnome.desktop.interface icon-theme

# To see available themes and icons:
# ls /usr/share/themes/
# ls /usr/share/icons/
LIGHT_GTK_THEME="Yaru"
DARK_GTK_THEME="Yaru-dark"

LIGHT_ICON_THEME="Yaru"
DARK_ICON_THEME="Yaru-dark"

#
#
# Do not edit below this line.
# (Unless you know what you are doing.)
#
#

echo -n "Checking dependencies... "
for name in hdate
do
  [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name needs to be installed. Use 'sudo apt-get install $name'";deps=1; }
done
[[ $deps -ne 1 ]] && echo "OK" || { echo -en "\nInstall the above and rerun this script\n";exit 1; }

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

    echo "Day theme has been set"

    # execute this script at sunset again
    NEXT_EXECUTION_AT=$(date --date="$SUNSET_TODAY 1 minute" +"%Y-%m-%d %H:%M")
else
    echo "Setting night theme..."

    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK_THEME"
    gsettings set org.gnome.desktop.interface icon-theme "$DARK_ICON_THEME"

    echo "Night theme has been set"

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
