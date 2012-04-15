require "test_helper"
require "rack/test"
require "backend_server"
require "remote_printer"

ENV['RACK_ENV'] = 'test'

describe BackendServer::Settings do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/my-printer") { run BackendServer::Settings }
    end
  end

  describe "with no nearby printers" do
    before do
      RemotePrinter.stubs(:find_by_ip).returns([])
      get "/my-printer", {}, {"REMOTE_ADDR" => "192.168.1.1"}
    end

    it "should indicate that no nearby printers were found" do
      last_response.body.must_match "no_printers"
    end
  end

  describe "with a single nearby printer" do
    before do
      printer = stub("remote_printer", id: "printer-id", type: "printer-type")
      RemotePrinter.stubs(:find_by_ip).with("192.168.1.1").returns([printer])
      get "/my-printer", {}, {"REMOTE_ADDR" => "192.168.1.1"}
    end

    it "should show that printer" do
      last_response.body.must_match "ID: printer-id"
    end

    it "should link to a test page print url" do
      last_response.body.must_match url_regexp("/my-printer/printer-id/test-page")
    end
  end

  describe "with multiple nearby printers" do
    before do
      printer = stub("remote_printer", id: "printer-id", type: "printer-type")
      printer2 = stub("remote_printer", id: "printer-id-2", type: "printer-type")
      RemotePrinter.stubs(:find_by_ip).with("192.168.1.1").returns([printer, printer2])
      get "/my-printer", {}, {"REMOTE_ADDR" => "192.168.1.1"}
    end

    it "should show all printers" do
      last_response.body.must_match "ID: printer-id"
      last_response.body.must_match "ID: printer-id-2"
    end

    it "should link to a test page print url for each printer" do
      last_response.body.must_match url_regexp("/my-printer/printer-id/test-page")
      last_response.body.must_match url_regexp("/my-printer/printer-id-2/test-page")
    end
  end
end