require "printer/print_processor/base"

class Printer::PrintProcessor::A2Bitmap < Printer::PrintProcessor::Base
  def width
    384
  end

  def process(data)
    bytes = []
    rotate_180(data["pixels"]).each_slice(8) { |s| bytes << ("0" + s.join).to_i(2) }

    data = [data["width"], data["height"]].pack("SS")
    data += bytes.pack("C*")
    data
  end

  private

  def rotate_180(pixels)
    pixels.reverse
  end
end
