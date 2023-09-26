Printer
===========

In a nutshell, Printer is a software system that makes it easy for **YOU** to:

* [build your own small internet-connected printers][getting-a-printer],
* produce [customised content][] for them, and
* [share that content][] with other people who also have small internet-connected printers.

Using a [commonly-available small thermal printer][getting-a-printer], and some basic [Arduino][] hardware, we can send small, designed bits of content from the internet to be printed anywhere in the world.

Find out more about [getting a printer on the wiki][getting-a-printer], or the [server API][api] on the [wiki][].

You can also see some sample applications: [Printer Mail](https://github.com/exciting-io/printer-mail), [Printer Paint](https://github.com/exciting-io/printer-paint) and [Printer Weather](https://github.com/exciting-io/printer-weather).

If you're interested in the background, take a look at the [project page](http://exciting.io/printer) or the [introductory blog post](http://exciting.io/2012/04/12/hello-printer/).

*This is the backend server software*. The rest of this README is about setting up and running a server.


Server Setup
-------------

The server acts as a conduit for turning HTML-based designs into a format suitable for the printer. The printer periodically polls the server, and if some data for printing is available, it downloads it and prints it.

Dependencies:

* Ruby 1.9.2 or greater
* Bundler
* PostgreSQL
* Redis 2.0.0 or greater
* ImageMagick
* PhantomJS (1.6.0 or greater recommended for better webfont-handling)
* Common fonts

Here's the `apt-get` command I ran:

    apt-get install ttf-mscorefonts-installer xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic redis-server imagemagick libmagick++-dev

You may need to add multiverse sources to apt - see http://askubuntu.com/questions/59890/ttf-mscorefonts-installer-is-not-available


### Installing PhantomJS

[PhantomJS][] is used as part of the rasterisation process, which turns HTML content into bitmaps suitable for printing. In order to get the best possible output, you should use a recent version of PhantomJS. I have tested against version 1.5.0.

You can build PhantomJS by following the instructions they provide at  http://code.google.com/p/phantomjs/wiki/BuildInstructions


## Running the server locally

To run the printer server locally, you should simply need to install the bundle

    bundle install

You may need to create the PostgreSQL database

    createdb printer
    createdb printer-test # if you want to run the tests

If your database requires credentials, or you choose a different database name, you can specify this by setting the `DATABASE_URL` environment variable. It will be something like `DATABASE_URL="postgres://username:password@localhost/printer"`

Finally, run all the processes using Foreman

    foreman start

This will start the web application and the queue processors.

**Note** that if you're running the local server, you'll also need to update the Ardunio sketch to point at the right port and IP or hostname for the machine you're running the server on.


## Deployment

Deployment is managed by `recap` (https://github.com/freerange/recap), a small, fast, git-based deployment strategy for capistrano.

Use bundler to install the dependencies

    bundle install

Then you can deploy and set up a server as follows. Firstly, create the application user and group:

    bundle exec cap bootstrap

Next, prepare the server for the application. Follow any guidance about adding your SSH user to groups, etc:

    bundle exec cap deploy:setup

Finally, deploy the application:

    bundle exec cap deploy

The server should start running on port 5678; I suggest you set up Apache or Nginx to reverse proxy a domain to that port.


## Compatible printers

The server contains code to handle the A2 thermal printer [described here][getting-a-printer], but the architecture should make it easy to implement support for other printers.

Each printer [reports its "type"][reporting-type] when it is checking with the server for content, and this corresponds to a [class mapping][type-mapping] in the `PrintProcessor` module. To support a new printer, it should be as simple as adding a new type to this mapping, along with the supporting class to emit the right printer byte sequences.


TODO & CAVEATS
----

The printer itself seems to prefer some types of paper over others, particularly where dark printing or horizontal lines are present. I've experienced paper from Staples jamming. If I find any good sources of paper, I'll update this.

Rasterisation of HTML designs isn't great at the moment; to some extent this is limited by [PhantomJS], which:

* doesn't support web fonts
* doesn't seem to support non-antialiased rendering
* doesn't match the exact font-sizes as seen in the browser, and this doesn't seem to be consistent either.


LICENSE
-------

The Printer project is open source, and made available via an 'MIT License', which basically means you can do whatever you like with it as long as you retain the copyright notice and license description - see [LICENSE.txt] for more information.


[Arduino]: http://ardunio.cc
[PhantomJS]: http://phantomjs.org
[wiki]: https://github.com/exciting-io/printer/wiki
[getting-a-printer]: https://github.com/exciting-io/printer/wiki/Making-your-own-printer
[customised content]: https://github.com/exciting-io/printer/wiki/Building-content-services
[share that content]: https://github.com/exciting-io/printer/wiki/Architecture
[api]: https://github.com/exciting-io/printer/wiki/API
[LICENSE.txt]: https://raw.github.com/exciting-io/printer/master/LICENSE.txt
[reporting-type]: https://github.com/exciting-io/printer/blob/master/printer.ino#L13
[type-mapping]: https://github.com/exciting-io/printer/blob/master/lib/print_processor.rb
