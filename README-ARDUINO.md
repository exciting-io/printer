## History

### Release 1.0.5 (2nd Aug 2012)

28,652 bytes (29,906 with debug) compiled using Arduino 1.0.1

* Get rid of remaining compiler warnings
* Disable debugging by default
* Reduce sketch size

### Release 1.0.4 (23rd July 2012)

28,654 bytes (29,922 with debug) compiled using Arduino 1.0.1

* Fail fast if we can't initialize the SD Card (indicated by flashing the red LED twice after boot)
* Indicate a DHCP failure by flashing the red LED 3 times after boot
* Change cache failure to flash the red LED 4 times
* Fix a bug causing crazy large durations to appear in debug output
* Remove some unnecessary debug statements (the red LEDs give us the same info) to reduce the amount of data in SRAM

### Release 1.0.3 (22nd July 2012)

28,646 bytes (30,100 with debug) compiled using Arduino 1.0.1

* Fail fast if we can't clear the cache
* Use the red LED to indicate a terminal error

### Release 1.0.2 (8th June 2012)

28,566 bytes (29,998 with debug) compiled using Arduino 1.0.1

* Fix the problem caused by the introduction of the version header.
* Reduce the size of debug strings, which reduces the amount of data in SRAM

### Release 1.0.1 (31st May 2012)

28,570 bytes (30,106 with debug) compiled using Arduino 1.0.1

* Introduce sketch version and report the version to the server
* Fix the bug where the printer would print error pages when the server failed