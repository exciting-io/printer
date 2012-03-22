require "test_helper"
require "jobs"

describe Jobs::PrepareContent do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "creates an HTML file with the content" do
      Jobs::PrepareContent.stubs(:random_id).returns("id")
      Jobs::PrepareContent.perform("printer-id", "content")
      expected_html = %{<!doctype html><html class="no-js" lang="en">content</html>}
      file_path = File.expand_path("../../../public/temp_content/id.html", __FILE__)
      File.read(file_path).must_equal expected_html
    end

    it "enqueues another job to render the content" do
      Jobs::PrepareContent.stubs(:random_id).returns("other-id")
      Resque.expects(:enqueue).with(Jobs::PreparePage, "printer-id", "http://localhost:5678/temp_content/other-id.html")
      Jobs::PrepareContent.perform("printer-id", "content")
    end
  end
end