require "printer"
require "data_mapper"
require "printer/id_generator"

class Printer::Print
  include DataMapper::Resource

  property :id, Serial
  property :printer_guid, String
  property :guid, String
  property :created_at, DateTime
  property :width, Integer
  property :height, Integer
  property :pixels, Object
  property :created_at, DateTime

  before(:create) { |p| p.guid ||= Printer::IdGenerator.random_id }

  def to_image
    img = ::Magick::Image.new(width, height)

    magick_pixels = pixels.map do |bit|
      v = ::Magick::QuantumRange * (1-bit)
      ::Magick::Pixel.new(v,v,v,0)
    end

    img.store_pixels(0, 0, width, height, magick_pixels)
    img
  end
end
