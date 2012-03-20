var drawCloud = function(id) {
  if (typeof id == "string") {
    var canvas = document.getElementById(id);
    var context = canvas.getContext("2d");
  } else {
    var context = id;
    var canvas = context.canvas;
  }
  var base = 10;
  var scale = 1.3;
  context.save();
  context.translate(5, 50);
  context.rotate(Math.PI / 1);
  context.scale(-1, 1);
  context.beginPath(); // begin custom shape
  var circle1 = base*scale;
  var circle2 = base*scale * 1.4;
  context.arc(circle1, circle1, circle1, 1.5 * Math.PI, 0.5 * Math.PI, true);
  context.arc(circle1*1.6, circle1*2.2, circle1/1.6, 1.1 * Math.PI, 0.2 * Math.PI, true);
  context.arc(circle1*3.4, circle1*2, circle2, 0.8 * Math.PI, 1.95 * Math.PI, true);
  context.arc(circle1*5, circle1*0.9, circle2/1.6, 0.5 * Math.PI, 1.5 * Math.PI, true);
  context.closePath();
  context.lineWidth = 10;
  context.strokeStyle = "#000000";
  context.stroke();
  context.fillStyle = "#fff";
  context.fill();
  context.closePath();
  context.restore();
  return context;
}

var drawRain = function(id) {
  var context = drawCloud(id);
  context.beginPath();
  context.moveTo(35, 40);
  context.lineTo(55, 65);
  context.moveTo(20, 40);
  context.lineTo(40, 65);
  context.moveTo(50, 40);
  context.lineTo(70, 65);
  context.lineWidth = 3;
  context.strokeStyle = "#000000";
  context.stroke();
  context.closePath();
}

var drawSun = function(id) {
  if (typeof id == "string") {
    var canvas = document.getElementById(id);
    var context = canvas.getContext("2d");
  } else {
    var context = id;
    var canvas = context.canvas;
  }
  context.beginPath();
  context.arc(canvas.width/2, canvas.height/2, canvas.width/7, 0 * Math.PI, 2 * Math.PI);
  context.lineWidth = 10;
  context.strokeStyle = "#000000";
  context.stroke();
  context.fillStyle = "#fff";
  context.fill();
  context.translate(canvas.width/2, canvas.height/2);
  context.lineWidth = 5;
  for (i = 0; i < 12; i++) {
    context.rotate(Math.PI * 2 / 12); // Rotate a 12th of 360 degrees
    context.beginPath();
    context.moveTo(30, 0);
    context.lineTo(20, 0);
    context.stroke();
  }
  context.closePath();
  return context;
}

var drawCloudSun = function(id) {
  var canvas = document.getElementById(id);
  var context = canvas.getContext("2d");
  context.save();
  context.scale(0.7, 0.7);
  context.translate(50, -5);
  drawSun(context);
  context.restore();
  drawCloud(context);
}

var drawSunClouds = function(id) {
  var canvas = document.getElementById(id);
  var context = canvas.getContext("2d");
  drawSun(context);
  context.save();
  context.scale(0.5, 0.5);
  context.translate(-20, -12);
  drawCloud(context);
  context.restore();
}

var drawSymbol = function(canvas) {
  var mapping = {
    "cloudy" : drawCloud,
    "clear"  : drawSun,
    "partlycloudy" : drawCloudSun,
    "fog" : drawCloud
  }
  mapping[canvas.className](canvas.id);
}

$(function() {
  $(".weather canvas").each(function(i, e) {
    drawSymbol(e);
  })
});