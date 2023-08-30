#!/bin/sh

set -o errexit
set -o xtrace

# exit if we are not root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

echo "Enabling serial port"
raspi-config nonint do_serial 2

echo "Installing dependencies"
apt-get update
apt-get install ruby ruby-dev libssl-dev -y

echo "Installing gem dependencies"
gem install serialport pi_piper

echo "Installing printer service"
cp ./init.d-script /etc/init.d/printer
chmod +x /etc/init.d/printer
update-rc.d printer defaults
/etc/init.d/printer start

echo "Installation complete. Reboot now? (y/n)"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  echo "Rebooting..."
  reboot
fi
