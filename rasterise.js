"use strict";
var page = require('webpage').create(),
    system = require('system'),
    address, output, width;

if (system.args.length < 3 || system.args.length > 4) {
  console.log('Usage: rasterize.js URL width filename');
  phantom.exit();
} else {
  address = system.args[1];
  width = system.args[2];
  output = system.args[3];
  page.viewportSize = { width: width, height: 10 };
  page.open(address, function (status) {
    if (status !== 'success') {
      console.log('Unable to load the address "' + address + '"');
      phantom.exit(1);
    } else {
      page.evaluate(function() {
        document.getElementsByTagName("body")[0].className = ""
        document.body.bgColor = 'white';
      });
      window.setTimeout(function () {
        page.render(output);
        phantom.exit();
      }, 200);
    }
  });
}
