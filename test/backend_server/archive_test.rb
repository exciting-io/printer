require "test_helper"
require "rack/test"
require "printer/backend_server"
require "printer/remote_printer"

ENV['RACK_ENV'] = 'test'

describe Printer::BackendServer::Settings do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/archive") { run Printer::BackendServer::Archive }
    end
  end

  describe "showing the archive" do
    before do
      printer = Printer::RemotePrinter.new("printer-id")
      Printer::RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      printer.stubs(:all_prints).returns([
        Printer::Print.new({"guid" => "a1", "width" => 8, "height" => 8, "pixels" => [0]*64}),
        Printer::Print.new({"guid" => "b2", "width" => 8, "height" => 8, "pixels" => [0]*64}),
        Printer::Print.new({"guid" => "c3", "width" => 8, "height" => 8, "pixels" => [0]*64}),
      ])

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
      printer = Printer::RemotePrinter.new("printer-id")
      Printer::RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      printer.stubs(:find_print).with("abc123").returns(Printer::Print.new({"guid" => "abc123", "width" => 8, "height" => 8, "pixels" => [0]*64}))

      get "/archive/printer-id/image/abc123.png"
    end

    it "should serve the image as a PNG" do
      last_response.ok?.must_equal true
      last_response.content_type.must_equal "image/png"
      last_response.body.must_equal png_image(8, 8, [0]*(8*8)).to_blob
    end
  end
end
