require "test_helper"
require "printer/remote_printer"
require "printer/print_processor"

describe Printer::RemotePrinter do
  describe "updating" do
    it "stores any printer attributes except IP" do
      Printer::DataStore.redis.expects(:hmset).with("printers:123abc", "type", "printer-type", "version", "1.0.1")
      Printer::RemotePrinter.find("123abc").update(type: "printer-type", version: "1.0.1", ip: "do-not-store")
    end

    it "stores any other attributes" do
      Printer::DataStore.redis.expects(:hmset).with("printers:123abc", "darkness", "123", "flipped", "false")
      Printer::RemotePrinter.find("123abc").update(darkness: "123", flipped: "false")
    end

    it "stores the remote IP for a short time" do
      Time.stubs(:now).returns(stub('time', to_i: 1000))
      Printer::DataStore.redis.expects(:zadd).with("ip:192.168.1.1", 1000, "printer-id")
      Printer::RemotePrinter.find("printer-id").update(ip: "192.168.1.1")
    end

    it "does not overwrite IP if it wasn't present" do
      Printer::DataStore.redis.expects(:zadd).never
      Printer::RemotePrinter.find("printer-id").update(attribute: "value")
    end
  end

  describe "retrieving" do
    it "returns the type for the stored printer" do
      Printer::DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      Printer::RemotePrinter.find("123abc").type.must_equal "printer-type"
    end

    it "returns the software version for the stored printer" do
      Printer::DataStore.redis.stubs(:hget).with("printers:123abc", "version").returns("printer-version")
      Printer::RemotePrinter.find("123abc").version.must_equal "printer-version"
    end

    it "returns the width for the printer according to its type" do
      Printer::DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      Printer::PrintProcessor.stubs(:for).with("printer-type").returns(stub('print_processor', width: 123))
      Printer::RemotePrinter.find("123abc").width.must_equal 123
    end
  end

  describe "finding by ip" do
    it "clears out expired printer IDs for that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 2000))
      Printer::DataStore.redis.expects(:zremrangebyscore).with("ip:192.168.1.1", 0, 2000-60)
      Printer::RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns the printer instances which most recently checked in from that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 3000))
      Printer::DataStore.redis.expects(:zrangebyscore).with("ip:192.168.1.1", 3000-60, 3000).returns(["printer-id", "printer-id-2"])
      Printer::RemotePrinter.expects(:find).with("printer-id")
      Printer::RemotePrinter.expects(:find).with("printer-id-2")
      Printer::RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns an empty array if no matching IP was found" do
      Printer::DataStore.redis.expects(:zrangebyscore).with("ip:192.168.1.1", anything, anything).returns([])
      Printer::RemotePrinter.find_by_ip("192.168.1.1").must_equal []
    end

    it "returns an empty array if no printers have ever connected" do
      Printer::DataStore.redis.stubs(:zrangebyscore).returns(nil)
      Printer::RemotePrinter.find_by_ip("192.168.1.1").must_equal []
    end

    describe "on the local network" do
      it "searches for printers connected from a local subnet IP" do
        Printer::DataStore.redis.expects(:keys).with("ip:192.168.*").returns(["printer:ip:192.168.2.123"])
        Printer::RemotePrinter.find_by_ip("127.0.0.1")
      end

      it "returns nil if no printers have ever connected" do
        Printer::DataStore.redis.stubs(:keys).with("ip:192.168.*").returns([])
        Printer::RemotePrinter.find_by_ip("127.0.0.1").must_equal []
      end
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
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 240
    end

    it "uses darkness from the type if none is stored" do
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.145")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 145
    end

    it "returns the stored darkness attribute" do
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns("120")
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").darkness.must_equal 120
    end

    it "defaults flipped to false" do
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      Printer::RemotePrinter.new("printer-id").flipped.must_equal false
    end

    it "uses flipped from the type if none is stored" do
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.123.flipped")
      Printer::RemotePrinter.new("printer-id").flipped.must_equal true
    end

    it "returns the stored flipped attribute" do
      Printer::DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns("true")
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

    describe "getting archived print ids" do
      subject do
        Printer::RemotePrinter.new("printer-id")
      end

      before do
        archive_for_printer.stubs(:ids).returns(["abc123", "def456"])
      end

      it "returns the set of all archived print IDs" do
        subject.archive_ids.must_equal ["abc123", "def456"]
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
