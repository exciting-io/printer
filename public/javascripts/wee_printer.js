var WeePrinter = {
  serializePage: function(callback) {
    var isRelative = function(path) {
      return !(path.match(/^http:\/\//) || path.match(/^file:\/\//));
    }

    var makeAbsolute = function(path) {
      return (isRelative(path) ? (window.location.protocol + "//" + window.location.host) : "") + path;
    }

    $("img").each(function(x, image) {
      if (image.src)  { image.src = makeAbsolute(image.src) }
    });
    $("script").each(function(x,script) {
      if (script.src) { script.src = makeAbsolute(script.src) }
    });
    $("link[rel=stylesheet]").each(function(x, stylesheet) {
      var s = $(stylesheet);
      if (s.attr("href")) { s.attr("href", makeAbsolute(s.attr("href"))) }
    });

    var pageContent = $("html").html();
    callback(pageContent);
  },

  backendURL: "http://wee-printer.gofreerange.com",

  previewPage: function() {
    WeePrinter.serializePage(function(page_content) {
      $.post(WeePrinter.backendURL + "/preview",
             {content: page_content},
             function(data) { console.log("HERE"); window.location = data.location },
             'json');
    })
    return false;
  },

  printPage: function(printerId, callback) {
    WeePrinter.serializePage(function(page_content) {
      $.post(WeePrinter.backendURL + "/print/" + printerId,
             {content: page_content},
             callback,
             'json');
    })
    return false;
  }
}