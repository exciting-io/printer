require "printer/configuration"
require "printer/remote_printer"

class Printer::Jobs::ImageToBits
  class << self
    def queue
      :printer_images
    end

    def perform(image_path, printer_id)
      Printer::RemotePrinter.find(printer_id).add_print(image_data(image_path))
    end

    def image_data(image_path)
      img = Magick::ImageList.new(image_path)[0]
      width = img.columns
      height = img.rows
      pixels = image_to_bits(img)
      {width: width, height: height, pixels: pixels}
    end

    private

    def image_to_bits(img)
      bits = []
      white = (2**16)-1
      limit = white / 2
      img.each_pixel { |pixel, _, _| bits << ((pixel.intensity < limit) ? 1 : 0) }
      bits
    end
  end
end
