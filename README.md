Printer
===========

A grandson to [Timmy Printface][timmy], and a cousin to [Little Printer][berg].


Getting Started
---------------

You will need:

* An [Arduino][] (tested against the Uno R3)
* An [ethernet + SD card shield][ethernet-shield]
* An SD card to put in the shield.
* A printer (available from [adafruit][] and [sparkfun][])
* Wires to plug them all together, power and program them.

You should also download and install

* The [Thermal Printer Library][arduino-library] which supports printing "rich" graphics
* The [Bounce][arduino-bounce] arduino library, which makes the button more reliable
* [PhantomJS][], which plays a part in converting HTML-based designs into data that the printer can understand

Hardware Setup
--------------

* Plug the Arduino and Ethernet Shield together
* Plug the printer into the Arduino (follow directions in [the sketch][])
* Plug the printer into power
  - The printer can potentially draw quite a high current, so I power it separately from the Arduino, although that might be paranoid.
* Format the SD card as MS-DOS (FAT16), and put it in the shield
* Connect an ethernet cable to the shield, and make sure the other end connects to the network in some way.
* Program the Arduino with [the sketch][]
  - You will need to change the IP to that of your server
* Turn everything on

(TODO - make this a bit more detailed)


Software Setup
-------------

The server acts as a conduit for turning HTML-based designs into a format suitable for the printer. The printer periodically polls the server, and if some data for printing is available, it downloads it and prints it.

Ruby 1.9

(You may need to add multiverse sources to apt - see http://askubuntu.com/questions/59890/ttf-mscorefonts-installer-is-not-available)

apt-get install ttf-mscorefonts-installer xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic redis-server imagemagick libmagick++-dev

Build PhantomJS by following http://code.google.com/p/phantomjs/wiki/BuildInstructions

(TODO - configuring and designing)


TODO & CAVEATS
----

Lots. This isn't generally usable yet.

The Arduino sketch seems quite prone to crashing at the moment, particularly with larger printouts.

The printer itself seems to prefer some types of paper over others, particularly where dark printing or horizontal lines are present. I've experienced paper from Staples jamming. If I find any good sources of paper, I'll update this.

Rasterisation of HTML designs isn't great at the moment; to some extent this is limited by [PhantomJS], which:

* doesn't support web fonts
* doesn't seem to support non-antialiased rendering
* doesn't match the exact font-sizes as seen in the browser, and this doesn't seem to be consistent either.

[timmy]: http://gofreerange.com/timmy
[berg]: http://bergcloud.com/littleprinter
[Arduino]: http://ardunio.cc
[ethernet-shield]: http://arduino.cc/en/Main/ArduinoEthernetShield
[adafruit]: https://www.adafruit.com/products/600
[sparkfun]: http://www.sparkfun.com/products/10438
[arduino-library]: https://github.com/lazyatom/Thermal-Printer-Library
[arduino-bounce]: http://www.arduino.cc/playground/Code/Bounce
[the sketch]: https://github.com/freerange/printer/blob/master/printer.ino
[PhantomJS]: http://phantomjs.org
