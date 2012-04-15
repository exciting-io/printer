require "test_helper"
require "rack/test"
require "backend_server"

ENV['RACK_ENV'] = 'test'

describe PrinterBackendServer do
  include Rack::Test::Methods

  def app
    PrinterBackendServer
  end

  before do
    Resque.stubs(:enqueue)
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
        PrintQueue.stubs(:new).with("1").returns(printer = stub("printer"))
        printer.stubs(:archive_and_return_print_data).returns("data")
        get "/printer/1"
        last_response.body.must_equal "data"
      end
    end

    it "updates our record of the remote printer" do
      RemotePrinter.expects(:update).with(has_entries(id: "1", type: "A2-bitmap", ip: "192.168.1.1"))
      get "/printer/1", {}, {"HTTP_ACCEPT" => "application/vnd.freerange.printer.A2-bitmap",
                             "REMOTE_ADDR" => "192.168.1.1"}
    end
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
      Resque.expects(:enqueue).with(Jobs::PreparePage, "1", "submitted-url")
      get "/print/1?url=submitted-url"
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
        IdGenerator.stubs(:random_id).returns("abc123")
      end

      it "stores the content in a publicly-accessible file" do
        ContentStore.expects(:write_html_content).with("<p>Some content</p>", "abc123")
        post "/preview", {content: "<p>Some content</p>"}
      end

      it "enqueues a job to generate a page from the content" do
        ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
        Resque.expects(:enqueue).with(Jobs::PreparePage, "1", "http://example.org/path/to/abc123.html")
        post "/print/1", {content: "<p>Some content</p>"}
      end

      it "returns an JSON status if the request accepts JSON" do
        header 'Accept', 'application/json'
        post "/print/1", {content: "<p>Some content</p>"}
        last_response.ok?.must_equal true
        MultiJson.decode(last_response.body).must_equal({"response" => "ok"})
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

  describe "previewing" do
    before do
      IdGenerator.stubs(:random_id).returns("abc123")
    end

    describe "when requested via GET without content or a URL" do
      it "directs people to the API" do
        get "/preview"
        last_response.ok?.must_equal true
        last_response.body.must_match /API documentation/
      end

      it "doesn't enqueue any jobs" do
        Resque.expects(:enqueue).never
        get "/preview"
      end
    end

    it "enqueues a job to generate a preview" do
      Resque.expects(:enqueue).with(Jobs::Preview, "abc123", "submitted-url", "123")
      get "/preview?url=submitted-url&width=123"
    end

    it "enqueues using a default width of 384" do
      Resque.expects(:enqueue).with(Jobs::Preview, "abc123", "submitted-url", "384")
      get "/preview?url=submitted-url"
    end

    it "redirects to a holding page after requesting" do
      get "/preview?url=submitted-url"
      last_response.redirect?.must_equal true
      last_response.location.must_equal "http://example.org/preview/pending/abc123"
    end

    it "redirects to the preview page once the preview data exists" do
      Preview.stubs(:find).with("abc123def456abcd").returns("data")
      get "/preview/pending/abc123def456abcd"
      last_response.redirect?.must_equal true
      last_response.location.must_equal "http://example.org/preview/show/abc123def456abcd"
    end

    it "allows posting of a URL for preview" do
      post "/preview", {url: "submitted-url"}
      last_response.redirect?.must_equal true
      last_response.location.must_equal "http://example.org/preview/pending/abc123"
    end

    describe "with content" do
      before do
        IdGenerator.stubs(:random_id).returns("abc123")
      end

      it "stores the content in a publicly-accessible file" do
        ContentStore.expects(:write_html_content).with("<p>Some content</p>", "abc123")
        post "/preview", {content: "<p>Some content</p>"}
      end

      it "enqueues a job to generate a preview from the content" do
        ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
        Resque.expects(:enqueue).with(Jobs::Preview, "abc123", "http://example.org/path/to/abc123.html", "123")
        post "/preview", {content: "<p>Some content</p>", width: "123"}
      end

      it "uses a default width of 384" do
        ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
        Resque.expects(:enqueue).with(Jobs::Preview, anything, anything, "384")
        post "/preview", {content: "<p>Some content</p>"}
      end

      it "redirects to the holding page" do
        post "/preview", {content: "<p>Some content</p>"}
        last_response.redirect?.must_equal true
        last_response.location.must_equal "http://example.org/preview/pending/abc123"
      end

      it "returns a JSON object pointing at the holding page if the request accepts JSON" do
        header 'Accept', 'application/json'
        post "/preview", {content: "<p>Some content</p>"}
        last_response.ok?.must_equal true
        MultiJson.decode(last_response.body)['location'].must_equal "http://example.org/preview/pending/abc123"
      end

      it "allows the returned JSON data to be loaded regardless of cross-domain" do
        header 'Accept', 'application/json'
        post "/preview", {content: "<p>Some content</p>"}
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

  describe "viewing printers" do
    it "should show printers polling from the same remote IP" do
      printer = stub("remote_printer", id: "printer-id", type: "printer-type")
      RemotePrinter.stubs(:find_by_ip).with("192.168.1.1").returns(printer)
      get "/my-printer", {}, {"REMOTE_ADDR" => "192.168.1.1"}
      last_response.ok?.must_equal true
    end
  end

  describe "generating a test print" do
    before do
      printer = stub("remote_printer", id: "printer-id", type: "printer-type")
      RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      get "/test-page/printer-id"
    end

    it "should render a page" do
      last_response.ok?.must_equal true
    end

    it "should show the printer ID" do
      last_response.body.must_match /ID: printer\-id/
    end

    it "should show the printer type" do
      last_response.body.must_match /Type: printer\-type/
    end

    it "should show the printer URL" do
      last_response.body.must_match Regexp.new(Regexp.escape("http://#{last_request.host}/print/printer-id"))
    end
  end
end