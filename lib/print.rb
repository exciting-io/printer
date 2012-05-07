class Print
  attr_reader :id, :width, :height, :pixels, :created_at

  def initialize(attributes)
    @id = attributes["id"]
    @width = attributes["width"]
    @height = attributes["height"]
    @pixels = attributes["pixels"]
    @created_at = attributes["created_at"]
  end

  def to_image
    require "RMagick" unless Object.const_defined?(:Magick)

    img = Magick::Image.new(width, height)

    magick_pixels = pixels.map do |bit|
      v = Magick::QuantumRange * (1-bit)
      Magick::Pixel.new(v,v,v,0)
    end

    img.store_pixels(0, 0, width, height, magick_pixels)
    img
  end
end