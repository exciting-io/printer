var Printer = {
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

  backendURL: "http://printer.gofreerange.com",

  previewPage: function() {
    Printer.serializePage(function(page_content, width) {
      if (width == undefined) {
        width = $(".content").width();
      }
      console.log("posting width", width);
      $.post(Printer.backendURL + "/preview",
             {content: page_content, width: width},
             function(data) { window.location = data.location },
             'json');
    })
    return false;
  },

  printPage: function(printerUrl, callback) {
    Printer.serializePage(function(page_content) {
      $.post(printerUrl,
             {content: page_content},
             callback,
             'json');
    })
    return false;
  }
}