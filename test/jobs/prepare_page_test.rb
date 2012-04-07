require "test_helper"
require "jobs"

describe Jobs::PreparePage do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "uses phantomjs to rasterise the url to a unique file" do
      Jobs::PreparePage.stubs(:output_id).returns("unique_id")
      Jobs::PreparePage.expects(:"`").with("phantomjs rasterise.js url tmp/renders/unique_id.png")
      Jobs::PreparePage.perform("printer_id", "url")
    end

    it "enqueues a job to turn the image into bits" do
      Jobs::PreparePage.stubs(:save_url_to_path)
      Jobs::PreparePage.stubs(:output_id).returns("unique_id")
      Resque.expects(:enqueue).with(Jobs::ImageToBits, "tmp/renders/unique_id.png", anything)
      Jobs::PreparePage.perform("printer_id", "url")
    end
  end

  describe "generating IDs" do
    it "should not return the same ID each time" do
      previous_ids = []
      10.times do
        new_id = Jobs::PreparePage.output_id
        previous_ids.include?(new_id).must_equal false
        previous_ids << new_id
      end
    end
  end
end