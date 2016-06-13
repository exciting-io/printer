# Connecting a Rasperry Pi to Printer

Connecting a printer to a Raspberry Pi and the Printer platform is very simple.

1. Download Minbian
3. Install required packages
4. Install required gems
2. Configure the serial port
5. Connect the printer and option LEDs
6. Install the client
7. Install the optional boot script
8. FAQ


## Download Minbian

Minbian is a minimal linux system for the Raspberry Pi: https://minibianpi.wordpress.com

Download and copy the Minbian image onto your SD card (at least 1GB).

Once your Pi is booted using this image, you can SSH into it using the username
`root` and the password `raspberry`.

Optionally, you may wish to expand the partition to be able to use the full
capacity of your SD card. Read about that here: https://minibianpi.wordpress.com/how-to/resize-sd/


## Install the required packages

Printer requires a few packages from APT to run:

    apt-get update
    apt-get install ruby rubygems libssl-dev ruby-dev


## Install the required gems

    gem install serialport pi_piper


## Configure the serial port

By default, the Pi uses a serial baud rate that's too fast for the printer, so
we need to change it. Once SSH'd into the Pi, edit the `/boot/cmdline.txt` file
changing all instances of `115200` to `19200`, so that it looks something like
this:

    dwc_otg.lpm_enable=0 kgdboc=ttyAMA0,19200 console=tty1 elevator=deadline root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait

If you're not sure how to edit this file, I suggest installing the `nano` editor
using `apt-get install nano`, then editing the file with `nano /boot/cmdline.txt`. Once you've made the changes, you can save the file by
pressing `ctrl-X` and answering `Y` to the prompt to write the file.


## Connect the printer and optional LEDS

The printer should be connected to the power, ground and serial transmission
pins from the Raspberry Pi. Assuming your power supply can deliver enough
current for the printer to work (I'd recommend at least 2 amps), you can connect
the printer's power to the 5V Vin and ground pins.

For the printer's data cable, you only really need to connect the ground and
receive lines (black and yellow respectively) to the Pi's ground and transmission pins (pins 6 & 8, or ground and BCM 14, respectively).

If you want to see status information using LEDs, connect a red, yellow and
green LED to BCM pins 22, 23 and 24 respectively. You don't _need_ to do this
with the Raspberry Pi because it's quite possible to SSH into the Pi itself and
view the logging output; we only *need* the LEDs on the Arduino, since it's much
harder to figure out what's going on without them on that more limited device.


## Install the client

To "install" the printer client software, you just need to copy `pi-printer.rb`
from this repository onto the device. One simple way to do this is by SSHing
onto the Pi and then running:

    wget https://raw.githubusercontent.com/exciting-io/printer/master/pi-printer.rb
    chmod +x pi-printer.rb

This will download the latest version of the printer client for the Raspberry Pi
onto your device.

To run this client, run

    ./pi-printer.rb

At the command line. If all is well, you should see debug output like the follow
a few seconds after it starts:

    2016-06-13 11:14:07 +0100: Starting printer
    2016-06-13 11:14:08 +0100: Printer ID: 094f210d99a1bc84
    2016-06-13 11:14:08 +0100: Checking for download
    2016-06-13 11:14:18 +0100: Checking for download
    2016-06-13 11:14:28 +0100: Checking for download

This indicates that the printer is now running, and polling the server every
10 seconds as normal.

Once you see this, you can visit http://printer.exciting.io and click the "Got
a printer?" link to see that your printer is connected, print a test page and
so on.


## Install the optional boot script

Chances are that you'll want the printer client to run as soon as the Raspberry
Pi starts, rather than having to connect via SSH and run it manually. To do this
you can use the sample "init.d" script provided. Having SSH'd onto the Pi,
download the script:

    wget https://raw.githubusercontent.com/exciting-io/printer/master/sample-init.d-script -O /etc/init.d/printer

Next, make it executable and configure the system to load it on startup:

    chmod +x /etc/init.d/printer
    update-rc.d printer defaults

Now, any time you boot the Pi, once the network is ready, the printer client
will start. If you want to stop or restart the client, you can use the init.d
script to do so:

    /etc/init.d/printer stop     # stop the printer client
    /etc/init.d/printer start    # start the printer client
    /etc/init.d/printer restart  # restart the printer client


## History

### Release 1.0.0

This is the initial release of the "official" Raspberry Pi client software.
