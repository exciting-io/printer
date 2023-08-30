#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname pi-printer-3
else
   echo pi-printer-3 >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tpi-printer-3/g" /etc/hosts
fi
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'printer' '$5$ICtX5l14B/$mYD6idwxxTIglND6oC1hzt6jJyChxaZmP7fI.XofXI7'
else
   echo "$FIRSTUSER:"'$5$ICtX5l14B/$mYD6idwxxTIglND6oC1hzt6jJyChxaZmP7fI.XofXI7' | chpasswd -e
   if [ "$FIRSTUSER" != "printer" ]; then
      usermod -l "printer" "$FIRSTUSER"
      usermod -m -d "/home/printer" "printer"
      groupmod -n "printer" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=printer/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/printer/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /printer /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan 'Fonthouse' 'f211ca8f20d3d2759152b27bec221179815a859a7b0641a279d8b4ee292d4733' 'GB'
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="Fonthouse"
	psk=f211ca8f20d3d2759152b27bec221179815a859a7b0641a279d8b4ee292d4733
}
network={
	ssid="Space4"
	psk=c62facf7529aff149c412dd7a10b921e5443eb0d9af98f1a3d8d23d39afb9c3c
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi

# Install the printer script dependencies
apt-get update
apt-get install ruby rubygems libssl-dev ruby-dev

# Install the printer gem dependencies
gem install serialport pi_piper

# Install the printer script and make it executable
cp /boot/printer/pi-printer.rb /root/pi-printer.rb
chmod 755 /root/pi-printer.rb
cp /boot/printer/pi-led-test.rb /root/pi-led-test.rb
chmod 755 /root/pi-led-test.rb

# Install the printer service
cp /boot/printer/sample-init.d-script /etc/init.d/printer
chmod 755 /etc/init.d/printer
update-rc.d printer defaults
/etc/init.d/printer start

# Set the correct serial port speed for the printer
sed -i 's|115200|19200|' /boot/cmdline.txt

rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0
