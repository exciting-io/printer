Bundler.require(:default, :test)
require "minitest/autorun"
require "mocha/minitest"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

ENV["DATABASE_URL"] ||= "postgres://localhost/printer-test"
require "printer/configuration"
require "printer/jobs"

def fixture_path(filename)
  File.expand_path("../fixtures/#{filename}", __FILE__)
end

def url_regexp(path)
  Regexp.new(Regexp.escape("http://#{last_request.host}#{path}"))
end

def png_image(width, height, pixels)
  img = ::Magick::Image.new(width, height)

  magick_pixels = pixels.map do |bit|
    v = ::Magick::QuantumRange * (1-bit)
    ::Magick::Pixel.new(v,v,v,0)
  end

  img.store_pixels(0, 0, width, height, magick_pixels)
  img.format = "PNG"
  img
end

Printer::ContentStore.content_directory = File.expand_path("../../tmp", __FILE__)

Mocha::Configuration.prevent :stubbing_non_existent_method
