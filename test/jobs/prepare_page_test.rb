require "test_helper"
require "printer/jobs"

describe Printer::Jobs::PreparePage do
  let(:job) { Printer::Jobs::PreparePage }

  describe "performing" do
    before do
      Resque.stubs(:enqueue)
    end

    it "uses phantomjs to rasterise the url to a unique file" do
      job.stubs(:output_id).returns("unique_id")
      expected_command = <<~EOC
        curl -X POST
        http://localhost/screenshot
        -H 'Cache-Control: no-cache'
        -H 'Content-Type: application/json'
        -d '{"url":"url","options":{"type":"png"},"viewport":{"width":"384","height":10},"waitFor":"function() { document.body.classList.remove(\\\"preview\\\") }"}'
        -o 'tmp/renders/unique_id.png'
      EOC
      job.expects(:run).with(expected_command.strip.gsub("\n", ' ')).returns({status: 0})
      job.perform("url", "384", "printer_id")
    end

    it "passes the specified width to renderer" do
      job.stubs(:output_id).returns("unique_id")
      expected_command = <<~EOC
        curl -X POST
        http://localhost/screenshot
        -H 'Cache-Control: no-cache'
        -H 'Content-Type: application/json'
        -d '{"url":"url","options":{"type":"png"},"viewport":{"width":"1000","height":10},"waitFor":"function() { document.body.classList.remove(\\\"preview\\\") }"}'
        -o 'tmp/renders/unique_id.png'
      EOC
      job.expects(:run).with(expected_command.strip.gsub("\n", ' ')).returns({status: 0})
      job.perform("url", "1000", "printer_id")
    end

    describe "for print data" do
      it "enqueues a job to turn the image into bits" do
        job.stubs(:save_url_to_path).returns({status: 0})
        job.stubs(:output_id).returns("unique_id")
        Resque.expects(:enqueue).with(Printer::Jobs::ImageToBits, "tmp/renders/unique_id.png", anything)
        job.perform("printer_id", "url", "384", "print")
      end
    end

    describe "for preview data" do
      it "stores an error message if running the job fails" do
        job.stubs(:run).returns({status: 1, error: "Couldn't load that page"})
        Printer::Preview.expects(:store).with("id", "url", {error: "Couldn't load that page"})
        job.perform("url", "123", "id", "preview")
      end

      it "stores the original url and preview data" do
        job.stubs(:run).returns({status: 0})
        Printer::Preview.expects(:store).with("id", "url", {image_path: "public/previews/id.png"})
        job.perform("url", "123", "id", "preview")
      end
    end
  end

  describe "running a command" do
    it "returns the status of the command" do
      job.run("sh -c 'exit 1'")[:status].must_equal 1
      job.run("sh -c 'exit 0'")[:status].must_equal 0
    end

    it "returns the output of the command if there was any" do
      job.run("echo 'hello'")[:error].must_equal "hello"
    end
  end

  describe "generating IDs" do
    it "should not return the same ID each time" do
      previous_ids = []
      10.times do
        new_id = Printer::Jobs::PreparePage.output_id
        previous_ids.include?(new_id).must_equal false
        previous_ids << new_id
      end
    end
  end
end
