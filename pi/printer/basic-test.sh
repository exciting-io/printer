#!/bin/sh

set -eux pipefail

# exit if we are not root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

# check if the result of `raspi-config nonint get_serial_hw` is 0, then the serial port is enabled
if [ "$(raspi-config nonint get_serial_hw)" = "0" ]; then
  echo "Serial port is enabled"
  echo "Sending test print data"
  stty -F /dev/serial0 19200
  echo "Testing basic serial output of\nprinter\n\n" > /dev/serial0
  echo "You should see a test print come out of the printer"
else
  echo "Serial port is disabled"
  echo "Enabling serial port"
  raspi-config nonint do_serial 2
  echo "Please reboot and try again"
  exit 1
fi
