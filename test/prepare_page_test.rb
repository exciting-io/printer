require "test_helper"

describe Jobs::PreparePage do
  describe "performing" do
    it "uses phantomjs to rasterise the url" do
      Jobs::PreparePage.expects(:"`").with("phantomjs rasterise.js url tmp/test.png")
      Jobs::PreparePage.perform("printer_id", "url")
    end

    it "enqueues a job to turn the image into bytes" do
      Jobs::PreparePage.stubs(:save_url_to_path)
      Resque.expects(:enqueue).with(Jobs::ImageToBytes, "tmp/test.png", "printer_id")
      Jobs::PreparePage.perform("printer_id", "url")
    end
  end
end