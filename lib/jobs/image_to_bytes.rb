require "RMagick"
require "base64"
require "jobs/print"

class Jobs::ImageToBytes
  class << self
    def queue
      :wee_printer_images
    end

    def perform(image_path, printer_id)
      Resque.enqueue_to(Jobs::Print.queue(printer_id), Jobs::Print, encoded_image(image_path))
    end

    private

    def encoded_image(image_path)
      img = Magick::ImageList.new(image_path)[0]
      width = img.columns
      height = img.rows
      bytes = image_to_bytes(img)
      base64_encoded_bytes(width, height, bytes)
    end

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

    def base64_encoded_bytes(width, height, bytes)
      Base64.encode64(encoded_bytes(width, height, bytes))
    end
  end
end