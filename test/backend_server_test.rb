require "test_helper"
require "rack/test"
require "printer/backend_server"
require "printer/remote_printer"
require "printer/print_queue"

ENV['RACK_ENV'] = 'test'

describe Printer::BackendServer::App do
  include Rack::Test::Methods

  def app
    Printer::BackendServer::App
  end

  before do
    Resque.stubs(:enqueue)
  end

  describe "print submissions" do
    describe "when requested via GET without content or a URL" do
      it "directs people to the API" do
        get "/print/1"
        last_response.ok?.must_equal true
        last_response.body.must_match /API documentation/
      end

      it "doesn't enqueue any jobs" do
        Resque.expects(:enqueue).never
        get "/print/1"
      end
    end

    it "enqueues the url with the printer id" do
      Resque.expects(:enqueue).with(Printer::Jobs::PreparePage, "submitted-url", anything, "1", "print", anything)
      get "/print/1?url=submitted-url"
    end

    it "enqueues the job for rendering with a default width of 384 pixels" do
      Resque.expects(:enqueue).with(Printer::Jobs::PreparePage, "submitted-url", "384", "1", "print", anything)
      get "/print/1?url=submitted-url"
    end

    it "enqueues the job with a unique ID that is returned as part of the response" do
      Printer::IdGenerator.stubs(:random_id).returns("abc123")
      Resque.expects(:enqueue).with(Printer::Jobs::PreparePage, "submitted-url", anything, "1", "print", "abc123")

      header 'Accept', 'application/json'
      get "/print/1?url=submitted-url"

      MultiJson.decode(last_response.body).must_equal({"response" => "ok", "print_id" => "abc123"})
    end

    it "shows a success page" do
      get "/print/1?url=submitted-url"
      last_response.ok?.must_equal true
    end

    it "also accepts POSTed data" do
      post "/print/1", {url: "http://param-url"}
      last_response.ok?.must_equal true
    end

    describe "with content" do
      before do
        Printer::IdGenerator.stubs(:random_id).returns("abc123")
      end

      it "stores the content in a publicly-accessible file" do
        Printer::ContentStore.expects(:write_html_content).with("<p>Some content</p>", "abc123").returns("/path/to/file.html")
        post "/preview", {content: "<p>Some content</p>"}
      end

      it "enqueues a job to generate a page from the content" do
        Printer::ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
        Resque.expects(:enqueue).with(Printer::Jobs::PreparePage, "http://example.org/path/to/abc123.html", anything, "1", "print", anything)
        post "/print/1", {content: "<p>Some content</p>"}
      end

      it "returns an JSON status if the request accepts JSON" do
        Printer::IdGenerator.stubs(:random_id).returns("unique-id")
        header 'Accept', 'application/json'
        post "/print/1", {content: "<p>Some content</p>"}
        last_response.ok?.must_equal true
        MultiJson.decode(last_response.body).must_equal({"response" => "ok", "print_id" => "unique-id"})
      end

      it "allows the returned JSON data to be loaded regardless of cross-domain" do
        header 'Accept', 'application/json'
        post "/print/1", {content: "<p>Some content</p>"}
        last_response.headers["Access-Control-Allow-Origin"].must_equal "*"
      end

      it "allows the JSON to be returned regardless of the Referer" do
        header 'Accept', 'application/json'
        header 'Referer', 'http://some-external-app.example.com'
        post "/print/1", {content: "<p>Some content</p>"}
        last_response.ok?.must_equal true
      end
    end
  end
end
