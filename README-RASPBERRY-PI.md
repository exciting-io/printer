# Connecting a Rasperry Pi to Printer

Connecting a printer to a Raspberry Pi and the Printer platform is very simple.

1. Download Minbian
3. Install required packages
4. Install required gems
2. Configure the serial port
5. Connect the printer and option LEDs
6. Install the client
7. Install the optional boot script


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
