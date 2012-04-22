require "test_helper"
require "remote_printer"
require "print_processor"

describe RemotePrinter do
  describe "updating" do
    it "stores the printer data" do
      DataStore.redis.expects(:hset).with("printers:123abc", "type", "printer-type")
      RemotePrinter.find("123abc").update(type: "printer-type")
    end

    it "stores the remote IP for a short time" do
      DataStore.redis.expects(:set).with("ip:192.168.1.1", "printer-id")
      DataStore.redis.expects(:expire).with("ip:192.168.1.1", 60)
      RemotePrinter.find("printer-id").update(ip: "192.168.1.1")
    end
  end

  describe "retrieving" do
    it "returns the type for the stored printer" do
      DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      RemotePrinter.find("123abc").type.must_equal "printer-type"
    end

    it "returns the width for the printer according to its type" do
      DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      PrintProcessor.stubs(:for).with("printer-type").returns(stub('print_processor', width: 123))
      RemotePrinter.find("123abc").width.must_equal 123
    end
  end

  describe "finding by ip" do
    it "returns the printer instance which most recently checked in from that IP" do
      DataStore.redis.expects(:get).with("ip:192.168.1.1").returns("printer-id")
      RemotePrinter.expects(:find).with("printer-id")
      RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns nil if no matching IP was found" do
      DataStore.redis.expects(:get).with("ip:192.168.1.1").returns(nil)
      RemotePrinter.find_by_ip("192.168.1.1").must_equal nil
    end
  end

  describe "instance" do
    let(:queue_for_printer) do
      queue = PrintQueue.new("printer-id")
      PrintQueue.stubs(:new).with("printer-id").returns(queue)
      queue
    end

    let(:archive_for_printer) do
      archive = PrintArchive.new("printer-id")
      PrintArchive.stubs(:new).with("printer-id").returns(archive)
      archive
    end

    let(:data) { {"width" => 8, "height" => 8, "pixels" => []} }

    describe "adding a print" do
      subject do
        printer = RemotePrinter.new("printer-id")
        RemotePrinter.stubs(:find).with("printer-id").returns(printer)
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
        printer = RemotePrinter.new("printer-id")
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
        PrintProcessor.expects(:for).with("A2-bitmap").returns(processor = stub("processor"))
        processor.expects(:process).with(data).returns("data-for-printer")
        subject.data_to_print.must_equal "data-for-printer"
      end
    end
  end
end