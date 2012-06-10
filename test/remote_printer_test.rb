require "test_helper"
require "remote_printer"
require "print_processor"

describe RemotePrinter do
  describe "updating" do
    it "stores any printer attributes except IP" do
      DataStore.redis.expects(:hmset).with("printers:123abc", "type", "printer-type", "version", "1.0.1")
      RemotePrinter.find("123abc").update(type: "printer-type", version: "1.0.1", ip: "do-not-store")
    end

    it "stores any other attributes" do
      DataStore.redis.expects(:hmset).with("printers:123abc", "darkness", "123", "flipped", "false")
      RemotePrinter.find("123abc").update(darkness: "123", flipped: "false")
    end

    it "stores the remote IP for a short time" do
      Time.stubs(:now).returns(stub('time', to_i: 1000))
      DataStore.redis.expects(:zadd).with("ip:192.168.1.1", 1000, "printer-id")
      RemotePrinter.find("printer-id").update(ip: "192.168.1.1")
    end

    it "does not overwrite IP if it wasn't present" do
      DataStore.redis.expects(:zadd).never
      RemotePrinter.find("printer-id").update(attribute: "value")
    end
  end

  describe "retrieving" do
    it "returns the type for the stored printer" do
      DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      RemotePrinter.find("123abc").type.must_equal "printer-type"
    end

    it "returns the software version for the stored printer" do
      DataStore.redis.stubs(:hget).with("printers:123abc", "version").returns("printer-version")
      RemotePrinter.find("123abc").version.must_equal "printer-version"
    end

    it "returns the width for the printer according to its type" do
      DataStore.redis.stubs(:hget).with("printers:123abc", "type").returns("printer-type")
      PrintProcessor.stubs(:for).with("printer-type").returns(stub('print_processor', width: 123))
      RemotePrinter.find("123abc").width.must_equal 123
    end
  end

  describe "finding by ip" do
    it "clears out expired printer IDs for that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 2000))
      DataStore.redis.expects(:zremrangebyscore).with("ip:192.168.1.1", 0, 2000-60)
      RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns the printer instances which most recently checked in from that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 3000))
      DataStore.redis.expects(:zrangebyscore).with("ip:192.168.1.1", 3000-60, 3000).returns(["printer-id", "printer-id-2"])
      RemotePrinter.expects(:find).with("printer-id")
      RemotePrinter.expects(:find).with("printer-id-2")
      RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns an empty array if no matching IP was found" do
      DataStore.redis.expects(:zrangebyscore).with("ip:192.168.1.1", anything, anything).returns([])
      RemotePrinter.find_by_ip("192.168.1.1").must_equal []
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

    it "defaults the darkness to 240" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      RemotePrinter.new("printer-id").darkness.must_equal 240
    end

    it "uses darkness from the type if none is stored" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns(nil)
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.145")
      RemotePrinter.new("printer-id").darkness.must_equal 145
    end

    it "returns the stored darkness attribute" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "darkness").returns("120")
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      RemotePrinter.new("printer-id").darkness.must_equal 120
    end

    it "defaults flipped to false" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      RemotePrinter.new("printer-id").flipped.must_equal false
    end

    it "uses flipped from the type if none is stored" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns(nil)
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw.123.flipped")
      RemotePrinter.new("printer-id").flipped.must_equal true
    end

    it "returns the stored flipped attribute" do
      DataStore.redis.stubs(:hget).with("printers:printer-id", "flipped").returns("true")
      DataStore.redis.stubs(:hget).with("printers:printer-id", "type").returns("A2-raw")
      RemotePrinter.new("printer-id").flipped.must_equal true
    end

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
        PrintProcessor.expects(:for).with(subject).returns(processor = stub("processor"))
        processor.expects(:process).with(data).returns("data-for-printer")
        subject.data_to_print.must_equal "data-for-printer"
      end
    end

    describe "getting archived print ids" do
      subject do
        RemotePrinter.new("printer-id")
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
        RemotePrinter.new("printer-id")
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