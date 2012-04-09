$(function() {
  if ($(".paper.scrollprinter")[0]) {
    $(".paper.scrollprinter").after('<div class="printerfront"><div class="drawing"><canvas></canvas></div></div>');

    var back = $(".printerfront canvas")[0]
    var ctx = back.getContext("2d");

    ctx.fillStyle = "rgb(40,40,40)";
    ctx.fillRect (0, 20, 300, 200);
    ctx.beginPath();
    ctx.moveTo(0, 20);
    ctx.lineTo(10, 10);
    ctx.lineTo(290, 10);
    ctx.lineTo(300, 20);
    ctx.closePath();
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(10, 10);
    ctx.lineTo(0, 20);
    ctx.lineTo(300, 20);
    ctx.lineTo(290, 10);
    ctx.lineWidth = 2;
    ctx.strokeStyle = "#333";
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(35,10);
    ctx.lineTo(265,10);
    ctx.lineWidth = 3;
    ctx.strokeStyle = "#000000";
    ctx.stroke();

    ctx.save();
    ctx.scale(2, 1);
    ctx.beginPath();
    ctx.arc(12, 4, 2, 0, 2 * Math.PI, false);
    ctx.restore();
    ctx.fillStyle = "#00ff00";
    ctx.fill();
    ctx.lineWidth = 1;
    ctx.strokeStyle = "black";
    ctx.stroke();

    $(".paper.scrollprinter").after('<div class="printerback"><div class="drawing"><canvas></canvas></div></div>');
    var back = $(".printerback canvas")[0]
    var ctx = back.getContext("2d");

    ctx.fillStyle = "rgb(40,40,40)";
    ctx.fillRect (10, 10, 280, 200);
    ctx.beginPath();
    ctx.moveTo(10, 10);
    ctx.lineTo(20, 0);
    ctx.lineTo(280, 0);
    ctx.lineTo(290, 10);
    ctx.closePath();
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(10, 10);
    ctx.lineTo(20, 0);
    ctx.lineTo(280, 0);
    ctx.lineTo(290, 10);
    ctx.lineWidth = 2;
    ctx.strokeStyle = "#333";
    ctx.stroke();
  }
})