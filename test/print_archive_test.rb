require "test_helper"
require "printer/print_archive"

describe Printer::PrintArchive do
  subject do
    Printer::PrintArchive.new("printer-id")
  end

  let(:data) do
    {width: 8, height: 8, pixels: []}
  end

  describe "storing a print" do
    before do
      Printer::IdGenerator.stubs(:random_id).returns("random-print-id")
    end

    it "stores the print data" do
      now = Time.now
      Time.stubs(:now).returns(now)
      Printer::Print.expects(:create).with(data.merge(printer_guid: "printer-id"))
      subject.store(width: 8, height: 8, pixels: [])
    end

    it "returns a Print instance for that data" do
      print = subject.store("width" => 8, "height" => 8, "pixels" => [])
      print.width.must_equal 8
      print.height.must_equal 8
      print.pixels.must_equal []
      print.guid.must_equal "random-print-id"
    end
  end

  describe "retrieving a print" do
    it "returns a Print" do
      print = stub('print')
      scope = stub('scope')
      Printer::Print.stubs(:all).with(printer_guid: "printer-id").returns(scope)
      scope.expects(:first).with(guid: "random-print-id").returns(print)
      subject.find("random-print-id").must_equal print
    end

    it "returns nil if the print didn't exist" do
      scope = stub('scope')
      Printer::Print.stubs(:all).with(printer_guid: "printer-id").returns(scope)
      scope.expects(:first).with(guid: "random-print-id").returns(nil)
      subject.find("random-print-id").must_be_nil
    end
  end

  describe "retrieving all prints" do
    it "returns all Prints" do
      prints = stub('prints')
      Printer::Print.stubs(:all).with(printer_guid: "printer-id").returns(prints)
      subject.prints.must_equal prints
    end
  end
end
