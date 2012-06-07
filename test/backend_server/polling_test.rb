require "test_helper"
require "rack/test"
require "backend_server"
require "remote_printer"

ENV['RACK_ENV'] = 'test'

describe BackendServer::Polling do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/printer") { run BackendServer::Polling }
    end
  end

  describe "with no data" do
    it "returns an empty response" do
      get "/printer/1"
      last_response.body.must_be_empty
    end
  end

  describe "where data exists" do
    it "returns the data as the message body" do
      printer = RemotePrinter.new("1")
      RemotePrinter.stubs(:find).with("1").returns(printer)
      printer.stubs(:data_to_print).returns("data")
      get "/printer/1"
      last_response.body.must_equal "data"
    end
  end

  describe "updating printer information" do
    let(:printer) { RemotePrinter.new("1") }

    let(:cgi_env) do
      {"HTTP_ACCEPT" => "application/vnd.freerange.printer.A2-bitmap",
       "REMOTE_ADDR" => "192.168.1.1",
       "HTTP_X_PRINTER_VERSION" => "1.0.1"}
    end

    before do
      RemotePrinter.stubs(:find).with("1").returns(printer)
    end

    it "parses the type from the HTTP_ACCEPT header" do
      printer.expects(:update).with(has_entry(type: "A2-bitmap"))
      get "/printer/1", {}, cgi_env
    end

    it "extracts the remote IP" do
      printer.expects(:update).with(has_entry(ip: "192.168.1.1"))
      get "/printer/1", {}, cgi_env
    end

    it "extracts the version from the HTTP_X_PRINTER_VERSION header" do
      printer.expects(:update).with(has_entry(version: "1.0.1"))
      get "/printer/1", {}, cgi_env
    end

    it "uses a version of 'Unknown' if the X-Printer-Version header is missing" do
      printer.expects(:update).with(has_entry(version: "Unknown"))
      get "/printer/1", {}, cgi_env.select { |k,_| ["HTTP_ACCEPT", "REMOTE_ADDR"].include?(k) }
    end
  end
end