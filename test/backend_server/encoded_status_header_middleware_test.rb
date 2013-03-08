require "test_helper"
require "rack/test"
require "printer/backend_server"

ENV['RACK_ENV'] = 'test'

describe Printer::BackendServer::EncodedStatusHeaderMiddleware do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      use Printer::BackendServer::EncodedStatusHeaderMiddleware
      use Rack::ContentLength
      run lambda { |env|
        headers = env["PATH_INFO"] == "/print-now" ? {"X-Printer-PrintImmediately" => true} : {}
        [200, headers, ["Response body"]]
      }
    end
  end

  describe "making a request" do
    before do
      get "anything"
    end

    it "includes the encoded header" do
      assert last_response.headers.keys.include?("X-Printer-Encoded-Status")
    end

    it "encodes the status in the header" do
      last_response.headers["X-Printer-Encoded-Status"].split("|")[0].must_equal "200"
    end

    it "encodes the content length in the header" do
      last_response.headers["X-Printer-Encoded-Status"].split("|")[1].must_equal "Response body".length.to_s
    end
  end

  describe "making a request where the X-Printer-PrintImmediately header is present" do
    it "encodes the print immediately value into the header" do
      get "/print-now"
      last_response.headers["X-Printer-Encoded-Status"].split("|")[2].must_equal "1"
    end
  end
end
