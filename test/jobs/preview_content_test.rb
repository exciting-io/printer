require "test_helper"
require "jobs"

describe Jobs::PreviewContent do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "creates an HTML file with the content" do
      Jobs::PreviewContent.perform("id", "content")
      expected_html = %{<!doctype html><html class="no-js" lang="en">content</html>}
      file_path = File.expand_path("../../../public/temp_content/id.html", __FILE__)
      File.read(file_path).must_equal expected_html
    end

    it "enqueues another job to render the preview content" do
      Resque.expects(:enqueue).with(Jobs::Preview, "id", "http://localhost:5678/temp_content/id.html")
      Jobs::PreviewContent.perform("id", "content")
    end
  end
end