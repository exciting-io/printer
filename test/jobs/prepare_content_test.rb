require "test_helper"
require "jobs"

describe Jobs::PrepareContent do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "creates an HTML file with the content" do
      ContentStore.expects(:write_html_content).with("content")
      Jobs::PrepareContent.perform("printer-id", "content")
    end

    it "enqueues another job to render the content" do
      IdGenerator.stubs(:random_id).returns("other-id")
      Resque.expects(:enqueue).with(Jobs::PreparePage, "printer-id", "http://localhost:5678/temp_content/other-id.html")
      Jobs::PrepareContent.perform("printer-id", "content")
    end
  end
end