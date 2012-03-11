require "rubygems"
require "bundler/setup"
require "base64"
require "RMagick"
require "resque"
require 'rvg/rvg'
include Magick

require "image"

W = 384.0
H = 384.0

def full_width_image(&block)
  RVG::dpi = 100
  RVG.new((W/RVG::dpi).in, (H/RVG::dpi).in).viewbox(0,0,W,H, &block)
end

def rvg
  x = full_width_image do |c|
    c.background_fill = 'white'

    numbers = [[5,nil,nil,4,6,9,nil,nil,1], [1,4,nil,nil,nil,nil,nil,nil,3], [7,nil,nil,nil,nil,nil,nil,4,nil],
               [nil,5,nil,6,2,nil,nil,1,nil], [7,2,1,9,nil,5,3,6,4], [nil,8,nil,nil,1,7,nil,5,nil],
               [nil,4,nil,nil,nil,nil,nil,nil,2], [8,nil,nil,nil,nil,nil,nil,3,6], [1,nil,nil,4,9,2,nil,nil,5]]
    c.g.use(sudoku(numbers))

    # c.g.translate(0, 3).use(gfr_logo)
    # c.g.translate(10,250).scale(0.4).use(gfr_logo)
    # c.g.translate(250,270).scale(0.3).use(gfr_logo)
  end
  flip(x)
end

def flip(img)
  img.rotate(180).translate(-W, -H)
end

def test
  RVG::Group.new do |c|
    c.text(0, 80) do |title|
      title.tspan("BEHOLD").styles(font_family: "futura", font_size: 96)
    end
    c.rect(384, 3, 0, 86)
  end
end

def sudoku(numbers)
  RVG::Group.new do |c|
    # c.text(W/2, 40) do |title|
      # title.tspan("daily sudoku").styles(font_family: "futura", font_size: 36, text_anchor: 'middle')
    # end
    c.g.translate(3, 3).scale(0.98, 0.98) do |g|
      [0, W/3, 2*(W/3)].each.with_index do |x, row|
        [0, W/3, 2*(W/3)].each.with_index do |y, col|
          g.g.translate(y, x).scale(0.333, 0.333) { |inner| inner.use(grid(numbers[(row*3)+col])) }
        end
      end
    end
  end
end

def grid(numbers=[])
  RVG::Group.new do |grid|
    grid.rect(W, H, 0, 0).styles(stroke_width: 10, fill: 'white', stroke: 'black')
    grid.line(0, W/3, W, W/3).styles(stroke_width: 6, stroke: 'black')
    grid.line(0, 2*(W/3), W, 2*(W/3)).styles(stroke_width: 6, stroke: 'black')
    grid.line(W/3, 0, W/3, W).styles(stroke_width: 6, stroke: 'black')
    grid.line(2*(W/3), 0, 2*(W/3), W).styles(stroke_width: 6, stroke: 'black')
    [0, W/3, 2*(W/3)].each.with_index do |x, row|
      [0, W/3, 2*(W/3)].each.with_index do |y, col|
        number = numbers[(row*3)+col]
        if number
          grid.text(y + W/6, x + W/3.8) { |t| t.tspan(number).styles(font_family: 'futura', font_size: 96, text_anchor: 'middle') }
        end
      end
    end
  end
end

def gfr_logo
  RVG::Group.new do |c|
    c.g.translate(215, 142) do |body|
      body.ellipse(140, 140).styles(fill: 'white', stroke: 'black', stroke_width: 6)
      body.text(10, 30) do |title|
        title.tspan("free").styles(font_size: 120, text_anchor: 'middle',
                                   font_family: 'foco', font_style: 'italic', fill: 'black')
      end
      body.text(50, 65) do |title|
        title.tspan("RANGE").styles(font_size: 40, text_anchor: 'middle',
                                    font_family: 'foco', font_style: 'italic', fill: 'black')
      end
    end

    c.g.translate(57, 120) do |body|
      body.ellipse(55, 55).styles(fill: 'white', stroke: 'black', stroke_width: 6)
      body.text(0, 18) do |title|
        title.tspan("Go").styles(font_size: 52, text_anchor: 'middle',
                                 font_family: 'foco', font_style: 'italic', fill: 'black')
      end
    end
  end
end

def base64_image
  img = rvg.draw
  img.write("tmp.png")
  bits = []
  width = img.columns
  height = img.rows
  img.each_pixel { |pixel, _, _| bits << (pixel.red > 0 ? 0 : 1) }
  bytes = []; bits.each_slice(8) { |s| bytes << ("0" + s.join).to_i(2) }
  str = [width,height].pack("SS")
  str += bytes.pack("C*")
  File.open("tmp", "w") { |f| f.write str }
  Base64.encode64(str)
end

base64_image

Resque.enqueue(Image, base64_image)