require "test_helper"
require "rack/test"
require "printer/backend_server"
require "printer/remote_printer"

ENV['RACK_ENV'] = 'test'

describe Printer::BackendServer::Polling do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/printer") { run Printer::BackendServer::Polling }
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
      printer = Printer::RemotePrinter.new("1")
      Printer::RemotePrinter.stubs(:find).with("1").returns(printer)
      printer.stubs(:data_to_print).returns("print_id" => "abc", "data" => "data")
      get "/printer/1"
      last_response.body.must_equal "data"
    end

    it "responds with a print ID in the headers" do
      printer = Printer::RemotePrinter.new("1")
      Printer::RemotePrinter.stubs(:find).with("1").returns(printer)
      printer.stubs(:data_to_print).returns("print_id" => "abc", "data" => "data")
      get "/printer/1"
      last_response.headers["X-Print-ID"].must_equal "abc"
    end

    it "responds with a content type that matches the printer type" do
      printer = Printer::RemotePrinter.new("1")
      Printer::RemotePrinter.stubs(:find).with("1").returns(printer)
      printer.stubs(:data_to_print).returns("print_id" => "abc", "data" => "data")
      get "/printer/1", {}, {"HTTP_ACCEPT" => "application/vnd.exciting.printer.printer-type"}
      last_response.headers["Content-Type"].must_equal "application/vnd.exciting.printer.printer-type"
    end
  end

  describe "updating printer information" do
    let(:printer) { Printer::RemotePrinter.new("1") }

    let(:cgi_env) do
      {"HTTP_ACCEPT" => "application/vnd.exciting.printer.A2-bitmap",
       "REMOTE_ADDR" => "192.168.1.1",
       "HTTP_X_PRINTER_VERSION" => "1.0.1"}
    end

    before do
      Printer::RemotePrinter.stubs(:find).with("1").returns(printer)
    end

    it "parses the type from the HTTP_ACCEPT header" do
      printer.expects(:update).with(has_entry(type: "A2-bitmap"))
      get "/printer/1", {}, cgi_env
    end

    it "handles the old vendor prefix in the HTTP_ACCEPT header" do
      printer.expects(:update).with(has_entry(type: "A2-bitmap"))
      get "/printer/1", {}, cgi_env.merge("HTTP_ACCEPT" => "application/vnd.freerange.printer.A2-bitmap")
    end

    it "extracts the remote IP" do
      Printer::PrinterIPLookup.expects(:update).with(printer, "192.168.1.1")
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
