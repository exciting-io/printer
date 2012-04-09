Printer
===========

Tools for exploring the possibilities of "internet of things" printing.

Using a commonly-available small thermal printer, and some basic [Arduino][] hardware, we can send small, designed bits of content from the internet to be printed anywhere in the world.

Find out more about [getting a printer on the wiki][getting-a-printer] on the [wiki][].


Server Setup
-------------

The server acts as a conduit for turning HTML-based designs into a format suitable for the printer. The printer periodically polls the server, and if some data for printing is available, it downloads it and prints it.

Requires Ruby 1.9.

(You may need to add multiverse sources to apt - see http://askubuntu.com/questions/59890/ttf-mscorefonts-installer-is-not-available)

apt-get install ttf-mscorefonts-installer xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic redis-server imagemagick libmagick++-dev

Build [PhantomJS][] by following http://code.google.com/p/phantomjs/wiki/BuildInstructions

(TODO - configuring and designing)


TODO & CAVEATS
----

The printer itself seems to prefer some types of paper over others, particularly where dark printing or horizontal lines are present. I've experienced paper from Staples jamming. If I find any good sources of paper, I'll update this.

Rasterisation of HTML designs isn't great at the moment; to some extent this is limited by [PhantomJS], which:

* doesn't support web fonts
* doesn't seem to support non-antialiased rendering
* doesn't match the exact font-sizes as seen in the browser, and this doesn't seem to be consistent either.


LICENSE
-------

The Printer project is open source, and made available via an 'MIT License', which basically means you can do whatever you like with it as long as you retain the copyright notice and license description - see LICENSE.txt for more information.

[timmy]: http://gofreerange.com/timmy
[Arduino]: http://ardunio.cc
[PhantomJS]: http://phantomjs.org
[wiki]: https://github.com/freerange/printer/wiki
[getting-a-printer]: https://github.com/freerange/printer/wiki/Making-your-own-printer
