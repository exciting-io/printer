require "test_helper"
require "jobs"

describe Jobs::Preview do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "uses phantomjs to rasterise the url into a unique file" do
      Jobs::Preview.expects(:"`").with("phantomjs rasterise.js url 384 public/previews/id.png")
      Jobs::Preview.perform("id", "url")
    end

    it "stores the original url and preview data" do
      Jobs::Preview.stubs(:save_url_to_path)
      Preview.expects(:store).with("id", "url", "public/previews/id.png")
      Jobs::Preview.perform("id", "url")
    end
  end
end