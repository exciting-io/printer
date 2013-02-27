var page = new WebPage(),
    address, output, size;

if (phantom.args.length < 2 || phantom.args.length > 3) {
  console.log('Usage: rasterize.js URL width filename');
  phantom.exit();
} else {
  address = phantom.args[0];
  width = phantom.args[1];
  output = phantom.args[2];
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
