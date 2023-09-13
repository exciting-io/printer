# Raspberry Pi printer installation

One your computer:

1. Write a new Raspbian filesystem to your SD card
2. Copy this folder (containing `pi-printer.rb`, `install.sh` etc) onto the SD card in your computer
3. If you didn't set up Wifi when installing Raspbian, run the `setup-wifi.rb` script on your computer in a terminal application
4. Eject the SD card, put it into your Raspberry Pi and turn it on.

Now, wait for the Raspberry Pi to boot for the first time. This can take a while.

Once it's ready, SSH onto the Pi and then

1. Go into the printer software directory: `cd /boot/printer`
2. Install dependencies: `./install.sh` (this can take a little while too)

This will set up the hardware and install the service to run the printer client software

At this point, you should be able to view the printer at https://printer.exciting.io/my-printer



## Raspberry Pi 4 notes

I've had a couple of issues on the Raspberry Pi 4:

### ffi problems

    apt-get install libffi-dev
    gem install ffi -- --enable-system-libffi

### Segmentation fault via pi_piper gem

Fix via https://raspberrypi.stackexchange.com/questions/135336/ruby-gem-pi-piper-crashing-with-bcm2835-init-gpio-mmap-failed-cannot-allocate

    wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.71.tar.gz
    tar zxvf bcm2835-1.71.tar.gz && cd bcm2835-1.71
    ./configure && make
    sudo make check
    sudo make install
    cd src && cc -shared bcm2835.o -o libbcm2835.so

You then need to copy the compiled library into wherever the pi_piper gem is installed. Run `gem which pi_piper` and then copy the `libbcm2835.so` file into that directory.
