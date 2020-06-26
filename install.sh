#!/bin/bash

set -e
type=${1:-1000}

echo "Installing GSX-$type"

echo "Installing X11 config"
if [ ! -d /etc/X11/xorg.conf.d ]; then
    sudo mkdir -p /etc/X11/xorg.conf.d
fi
sudo cp usr/share/X11/xorg.conf.d/40-sennheiser-gsx.conf /etc/X11/xorg.conf.d/

echo "Installing udev rule"
if [ ! -d /etc/udev/rules.d ]; then
    sudo mkdir -p /etc/udev/rules.d
fi
sudo cp lib/udev/rules.d/91-pulseaudio-gsx.rules /etc/udev/rules.d/

echo "Installing udev hwdb"
if [ ! -d /etc/udev/hwdb.d/ ]; then
    sudo mkdir -p /etc/udev/hwdb.d
fi
sudo cp etc/udev/hwdb.d/sennheiser-gsx.hwdb /etc/udev/hwdb.d/

echo "Installing pulsaudio profiles"
echo
echo -n "Should we install the channelswap-fix, see https://github.com/evilphish/sennheiser-gsx-1000/issues/9 (y for yes, n [default])? "
read answer
if [ "$answer" == "${answer#[Nn]}" ]; then
    sudo cp -r usr/share/pulseaudio/alsa-mixer/profile-sets/sennheiser-gsx.conf /usr/share/pulseaudio/alsa-mixer/profile-sets/
    echo "- installed normal channel mix"
else
    sudo cp -r usr/share/pulseaudio/alsa-mixer/profile-sets/sennheiser-gsx-channelswap.conf /usr/share/pulseaudio/alsa-mixer/profile-sets/
    echo "- installed channel-swap mix"
fi

echo "Reloading udev rules"
if [ -x "$(command -v systemd-hwdb)" ]; then
    sudo systemd-hwdb update
fi
sudo udevadm control -R
sudo udevadm trigger

echo -n "restart pulseaudio? (y for yes [default]/n for no)"
read answer
if [ "$answer" == "${answer#[Nn]}" ] ;then
    echo "Restarting pulse audio"
    if [ -x "$(command -v systemctl)" ]; then
        systemctl --user restart pulseaudio.service
    else
        # ignore errors if we restart too often / to fast .. we just ensure to nuke it
        pulseaudio -k > /dev/null 2>&1 || true
        pulseaudio -k > /dev/null 2>&1 || true
        pulseaudio -k > /dev/null 2>&1 || true

        echo "Ensure pulseaudio is started"
        sleep 2
        pulseaudio -D
    fi
else
    echo "Skipped pulseaudio restart"
fi

