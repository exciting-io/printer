require "test_helper"
require "rack/test"
require "backend_server"

ENV['RACK_ENV'] = 'test'

describe WeePrinterBackendServer do
  include Rack::Test::Methods

  def app
    WeePrinterBackendServer
  end

  describe "polling printers" do
    describe "with no data" do
      it "returns an empty response" do
        get "/printer/1"
        last_response.body.must_be_empty
      end
    end

    describe "where data exists" do
      it "returns the data as the message body" do
        Printer.stubs(:new).with("1").returns(printer = stub("printer"))
        printer.stubs(:archive_and_return_print_data).returns("data")
        get "/printer/1"
        last_response.body.must_be :==, "data"
      end
    end
  end

  describe "print submissions" do
    it "enqueues the url with the printer id" do
      Resque.expects(:enqueue).with(Jobs::PreparePage, "1", "submitted-url")
      get "/print_from_page/1?url=submitted-url"
    end

    it "determines the URL from the HTTP_REFERER if no url parameter exists" do
      Resque.expects(:enqueue).with(Jobs::PreparePage, "1", "referer-url")
      get "/print_from_page/1", {}, {"HTTP_REFERER" => "referer-url"}
    end

    it "prefers the url parameter to the HTTP_REFERER" do
      Resque.expects(:enqueue).with(Jobs::PreparePage, "1", "param-url")
      get "/print_from_page/1?url=param-url", {}, {"HTTP_REFERER" => "referer-url"}
    end

    it "redirects back to the HTTP_REFERER" do
      get "/print_from_page/1", {}, {"HTTP_REFERER" => "http://referer-url"}
      last_response.redirect?.must_be :==, true
      last_response.location.must_be :==, "http://referer-url"
    end
  end
end