require "a2_printer"
require "print_processor/base"

class PrintProcessor::A2Raw < PrintProcessor::Base
  attr_reader :heat_time, :flipped

  def initialize(heat_time=240, flipped=false)
    @heat_time = heat_time
    @flipped = flipped
  end

  def width
    384
  end

  def process(data)
    bytes = []
    pixels = if flipped
      data["pixels"]
    else
      rotate_180(data["pixels"])
    end
    pixels.each_slice(8) { |s| bytes << ("0" + s.join).to_i(2) }
    
    printer_commands = StringIO.new
    printer = A2Printer.new(printer_commands)
    printer.begin(heat_time)
    printer.print_bitmap(data["width"], data["height"], bytes)
    printer.feed(3)
    printer_commands.rewind
    printer_commands.read
  end

  private

  def rotate_180(pixels)
    pixels.reverse
  end
end