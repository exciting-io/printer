require "test_helper"
require "rack/test"
require "backend_server"
require "remote_printer"

ENV['RACK_ENV'] = 'test'

describe BackendServer::Preview do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/preview") { run BackendServer::Preview }
    end
  end

  before do
    IdGenerator.stubs(:random_id).returns("abc123")
  end

  describe "when requested via GET without content or a URL" do
    it "directs people to the API" do
      Resque.stubs(:enqueue)
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
    Resque.expects(:enqueue).with(Jobs::PreparePage, "submitted-url", "123", "abc123", "preview")
    get "/preview?url=submitted-url&width=123"
  end

  it "enqueues using a default width of 384" do
    Resque.expects(:enqueue).with(Jobs::PreparePage, anything, "384", anything, anything)
    get "/preview?url=submitted-url"
  end

  it "redirects to a holding page after requesting" do
    Resque.stubs(:enqueue)
    get "/preview?url=submitted-url"
    last_response.redirect?.must_equal true
    last_response.location.must_equal "http://example.org/preview/pending/abc123"
  end

  it "redirects to the preview page once the preview data exists" do
    Resque.stubs(:enqueue)
    Preview.stubs(:find).with("abc123def456abcd").returns("data")
    get "/preview/pending/abc123def456abcd"
    last_response.redirect?.must_equal true
    last_response.location.must_equal "http://example.org/preview/show/abc123def456abcd"
  end

  it "allows posting of a URL for preview" do
    Resque.stubs(:enqueue)
    post "/preview", {url: "submitted-url"}
    last_response.redirect?.must_equal true
    last_response.location.must_equal "http://example.org/preview/pending/abc123"
  end

  describe "showing the preview" do
    before do
      Preview.stubs(:find).with("abc123").returns(Preview.new({"image_path" => "/path/to/image", "original_url" => "http://source.url"}))
      get "/preview/show/abc123"
    end

    it "displays the preview image" do
      last_response.body.must_match /img src="\/path\/to\/image"/
    end

    it "displays a link to the original url" do
      last_response.body.must_match /a href="http:\/\/source\.url"/
    end

    describe "when there was an error previewing" do
      before do
        Preview.stubs(:find).with("abc123").returns(Preview.new({"error" => "some error", "original_url" => "http://source.url"}))
        get "/preview/show/abc123"
      end

      it "shows the error message" do
        last_response.body.must_match /some error/
      end
    end
  end

  describe "with content" do
    before do
      IdGenerator.stubs(:random_id).returns("abc123")
    end

    it "stores the content in a publicly-accessible file" do
      Resque.stubs(:enqueue)
      ContentStore.expects(:write_html_content).with("<p>Some content</p>", "abc123").returns("/path/to/file.html")
      post "/preview", {content: "<p>Some content</p>"}
    end

    it "enqueues a job to generate a preview from the content" do
      ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
      Resque.expects(:enqueue).with(Jobs::PreparePage, "http://example.org/path/to/abc123.html", "123", "abc123", "preview")
      post "/preview", {content: "<p>Some content</p>", width: "123"}
    end

    it "uses a default width of 384" do
      ContentStore.stubs(:write_html_content).returns("/path/to/abc123.html")
      Resque.expects(:enqueue).with(Jobs::PreparePage, anything, "384", anything, anything)
      post "/preview", {content: "<p>Some content</p>"}
    end

    it "redirects to the holding page" do
      Resque.stubs(:enqueue)
      post "/preview", {content: "<p>Some content</p>"}
      last_response.redirect?.must_equal true
      last_response.location.must_equal "http://example.org/preview/pending/abc123"
    end

    it "returns a JSON object pointing at the holding page if the request accepts JSON" do
      Resque.stubs(:enqueue)
      header 'Accept', 'application/json'
      post "/preview", {content: "<p>Some content</p>"}
      last_response.ok?.must_equal true
      MultiJson.decode(last_response.body)['location'].must_equal "http://example.org/preview/pending/abc123"
    end

    it "allows the returned JSON data to be loaded regardless of cross-domain" do
      Resque.stubs(:enqueue)
      header 'Accept', 'application/json'
      post "/preview", {content: "<p>Some content</p>"}
      last_response.headers["Access-Control-Allow-Origin"].must_equal "*"
    end

    it "allows the JSON to be returned regardless of the Referer" do
      Resque.stubs(:enqueue)
      header 'Accept', 'application/json'
      header 'Referer', 'http://some-external-app.example.com'
      post "/preview", {content: "<p>Some content</p>"}
      last_response.ok?.must_equal true
    end
  end
end