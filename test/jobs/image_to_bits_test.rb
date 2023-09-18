require "test_helper"
require "printer/jobs"

describe Printer::Jobs::ImageToBits do
  let(:job) { Printer::Jobs::ImageToBits }

  describe "converting to bits" do
    subject do
      job.image_data(fixture_path("8x8.png"))
    end

    it "includes the dimensions of the image" do
      subject[:width].must_equal 8
      subject[:height].must_equal 8
    end

    it "includes the pixel data for the image" do
      subject[:pixels].must_equal [1,0,0,0,0,0,0,0,
                                   0,1,0,0,0,0,0,0,
                                   0,0,1,0,0,0,0,0,
                                   0,0,0,1,0,0,0,0,
                                   0,0,0,0,1,0,0,0,
                                   0,0,0,0,0,1,0,0,
                                   0,0,0,0,0,0,1,0,
                                   0,0,0,0,0,0,0,1]
    end

    it "doesn't print transparent pixels" do
      data = job.image_data(fixture_path("8x8-transparent.png"))
      data[:pixels].must_equal [1,0,0,0,0,0,0,1] + [0]*(8*7)
    end
  end

  describe "performing" do
    let(:data) { {width: 8, height: 8, pixels: []} }

    before do
      job.stubs(:image_data).with("file_path").returns(data)
    end

    it "sends the data for printing" do
      printer = Printer::RemotePrinter.new("printer-id")
      Printer::RemotePrinter.stubs(:find).with("printer-id").returns(printer)
      printer.expects(:add_print).with(data, "unique-id")
      job.perform("file_path", "printer-id", "unique-id")
    end
  end
end
