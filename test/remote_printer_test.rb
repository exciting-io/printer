require "test_helper"
require "printer/remote_printer"
require "printer/print_processor"

describe Printer::RemotePrinter do
  let(:redis) { Printer::DataStore.redis }

  describe "updating" do
    it "stores printer attributes" do
      redis.expects(:hmset).with("printers:123abc", "type", "printer-type", "version", "1.0.1")
      Printer::RemotePrinter.find("123abc").update(type: "printer-type", version: "1.0.1")
    end

    it "stores any other attributes" do
      redis.expects(:hmset).with("printers:123abc", "darkness", "123", "flipped", "false")
      Printer::RemotePrinter.find("123abc").update(darkness: "123", flipped: "false")
    end
  end

  describe "retrieving" do
    it "returns the type for the stored printer" do
      redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      Printer::RemotePrinter.find("123abc").type.must_equal "printer-type"
    end

    it "returns the software version for the stored printer" do
      redis.stubs(:hget).with("printers:123abc", "version").returns("printer-version")
      Printer::RemotePrinter.find("123abc").version.must_equal "printer-version"
    end

    it "returns the width for the printer according to its type" do
      redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      Printer::PrintProcessor.stubs(:for).with("printer-type").returns(stub('print_processor', width: 123))
      Printer::RemotePrinter.find("123abc").width.must_equal 123
    end
  end

  describe "instance" do
    let(:queue_for_printer) do
      queue = Printer::PrintQueue.new("printer-id")
      Printer::PrintQueue.stubs(:new).with("printer-id").returns(queue)
      queue
    end

    let(:archive_for_printer) do
      archive = Printer::PrintArchive.new("printer-id")
      Printer::PrintArchive.stubs(:new).with("printer-id").returns(archive)
      archive
    end

    let(:data) { {"width" => 8, "height" => 8, "pixels" => []} }

    it "defaults the darkness to 240" do
      redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 240
    end

    it "uses darkness from the type if none is stored" do
      redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.145")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 145
    end

    it "returns the stored darkness attribute" do
      redis.stubs(:hget).with("printers:printer-id", "darkness").returns("120")
      redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 120
    end

    it "defaults flipped to false" do
      redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").flipped.must_equal false
    end

    it "uses flipped from the type if none is stored" do
      redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.123.flipped")
      Printer::RemotePrinter.new("printer-id").flipped.must_equal true
    end

    it "returns the stored flipped attribute" do
      redis.stubs(:hget).with("printers:printer-id", "flipped").returns("true")
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").flipped.must_equal true
    end

    describe "adding a print" do
      subject do
        printer = Printer::RemotePrinter.new("printer-id")
        Printer::RemotePrinter.stubs(:find).with("printer-id").returns(printer)
        printer
      end

      it "adds the print data" do
        archive_for_printer.expects(:store).with(data).returns(stub("print", id: "print-id"))
        subject.add_print(data)
      end

      it "queues the print data" do
        archive_for_printer.stubs(:store).with(data).returns(stub("print", id: "print-id"))
        queue_for_printer.expects(:enqueue).with(print_id: "print-id")
        subject.add_print(data)
      end
    end

    describe "getting next queued print" do
      subject do
        printer = Printer::RemotePrinter.new("printer-id")
        printer.stubs(:type).returns("A2-bitmap")
        printer
      end

      before do
        archive_for_printer.stubs(:find).with("print-id").returns(stub("print", id: "print-id", width: 8, height: 8, pixels: []))
      end

      it "returns the next data for printing from the queue" do
        queue_for_printer.expects(:pop).returns("print_id" => "print-id")
        subject.data_to_print
      end

      it "sends the data through a print processor" do
        queue_for_printer.stubs(:pop).returns("print_id" => "print-id")
        Printer::PrintProcessor.expects(:for).with(subject).returns(processor = stub("processor"))
        processor.expects(:process).with(data).returns("data-for-printer")
        subject.data_to_print.must_equal "data-for-printer"
      end
    end

    describe "getting a single archived print by id" do
      subject do
        Printer::RemotePrinter.new("printer-id")
      end

      before do
        archive_for_printer.stubs(:find).with("abc123").returns(stub("print", id: "print-id", width: 8, height: 8, pixels: []))
      end

      it "returns the print data for the given ID" do
        print = subject.find_print("abc123")
        print.width.must_equal 8
        print.height.must_equal 8
        print.pixels.must_equal []
      end
    end
  end
end
