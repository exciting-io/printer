require "test_helper"
require "rack/test"
require "backend_server"
require "remote_printer"

ENV['RACK_ENV'] = 'test'

describe BackendServer::Settings do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/archive") { run BackendServer::Archive }
    end
  end

  describe "showing the archive" do
    before do
      printer = RemotePrinter.new("printer-id")
      RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      printer.stubs(:find_print).with(anything).returns(Print.new({"width" => 8, "height" => 8, "pixels" => [0]*64}))
      printer.stubs(:archive_ids).returns(["a1", "b2", "c3"])

      get "/archive/printer-id"
    end

    it "should present a list of images" do
      last_response.ok?.must_equal true
      ["a1", "b2", "c3"].each do |id|
        img_tag = %{<img src="/archive/printer-id/image/#{id}.png"}
        regexp = /#{Regexp.escape(img_tag)}/
        last_response.body.must_match regexp
      end
    end
  end

  describe "serving the image" do
    before do
      printer = RemotePrinter.new("printer-id")
      RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      printer.stubs(:find_print).with("abc123").returns(Print.new({"width" => 8, "height" => 8, "pixels" => [0]*64}))

      get "/archive/printer-id/image/abc123"
    end

    it "should serve the image as a PNG" do
      last_response.ok?.must_equal true
      last_response.content_type.must_equal "image/png"
      last_response.body.must_equal File.binread(fixture_path("8x8-blank.png"))
    end
  end
end