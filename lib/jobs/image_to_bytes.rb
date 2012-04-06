require "print_queue"

class Jobs::ImageToBytes
  class << self
    def queue
      :printer_images
    end

    def perform(image_path, printer_id)
      PrintQueue.new(printer_id).add_print_data(encoded_image(image_path))
    end

    def encoded_image(image_path)
      require "RMagick" unless Object.const_defined?(:Magick)
      img = Magick::ImageList.new(image_path)[0]
      img.rotate!(180) # print the bottom first
      width = img.columns
      height = img.rows
      bytes = image_to_bytes(img)
      encoded_bytes(width, height, bytes)
    end

    private

    def image_to_bytes(img)
      bits = []
      white = (2**16)-1
      limit = white / 2
      img.each_pixel { |pixel, _, _| bits << ((pixel.intensity < limit) ? 1 : 0) }
      bytes = []
      bits.each_slice(8) { |s| bytes << ("0" + s.join).to_i(2) }
      bytes
    end

    def encoded_bytes(width, height, bytes)
      data = [width,height].pack("SS")
      data += bytes.pack("C*")
      data
    end
  end
end