require "test_helper"
require "jobs"

describe Jobs::PreviewContent do
  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "creates an HTML file with the content" do
      ContentStore.expects(:write_html_content).with("content", "preview-id")
      Jobs::PreviewContent.perform("preview-id", "content")
    end

    it "enqueues another job to render the preview content" do
      Resque.expects(:enqueue).with(Jobs::Preview, "preview-id", "http://localhost:#{ENV["PORT"]}/temp_content/preview-id.html")
      Jobs::PreviewContent.perform("preview-id", "content")
    end
  end
end