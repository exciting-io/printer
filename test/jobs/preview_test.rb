require "test_helper"
require "jobs"

describe Jobs::Preview do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "uses phantomjs to rasterise the url into a unique file" do
      Jobs::Preview.expects(:run).with("phantomjs rasterise.js url 123 public/previews/id.png").returns({status: 0})
      Jobs::Preview.perform("id", "url", "123")
    end

    it "stores an error message if running the job fails" do
      Jobs::Preview.stubs(:run).returns({status: 1, error: "Couldn't load that page"})
      Preview.expects(:store).with("id", "url", {error: "Couldn't load that page"})
      Jobs::Preview.perform("id", "url", "123")
    end

    it "stores the original url and preview data" do
      Jobs::Preview.stubs(:run).returns({status: 0})
      Preview.expects(:store).with("id", "url", {image_path: "public/previews/id.png"})
      Jobs::Preview.perform("id", "url", "123")
    end
  end
end