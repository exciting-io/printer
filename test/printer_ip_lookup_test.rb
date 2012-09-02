require "test_helper"
require "printer/printer_ip_lookup"

describe Printer::PrinterIPLookup do
  subject { Printer::PrinterIPLookup }
  let(:redis) { Printer::DataStore.redis }

  describe "updating" do
    it "stores the remote IP for a short time" do
      printer = Printer::RemotePrinter.new("printer-id")

      Time.stubs(:now).returns(stub('time', to_i: 1000))
      redis.expects(:zadd).with("ip:192.168.1.1", 1000, "printer-id")

      subject.update(printer, "192.168.1.1")
    end
  end

  describe "finding by ip" do
    it "clears out expired printer IDs for that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 2000))
      redis.expects(:zremrangebyscore).with("ip:192.168.1.1", 0, 2000-60)
      subject.find_printer("192.168.1.1")
    end

    it "returns the printer instances which most recently checked in from that IP" do
      Time.stubs(:now).returns(stub('time', to_i: 3000))
      redis.expects(:zrangebyscore).with("ip:192.168.1.1", 3000-60, 3000).returns(["printer-id", "printer-id-2"])
      Printer::RemotePrinter.expects(:find).with("printer-id")
      Printer::RemotePrinter.expects(:find).with("printer-id-2")
      subject.find_printer("192.168.1.1")
    end

    it "returns an empty array if no matching IP was found" do
      redis.expects(:zrangebyscore).with("ip:192.168.1.1", anything, anything).returns([])
      subject.find_printer("192.168.1.1").must_equal []
    end

    it "returns an empty array if no printers have ever connected" do
      redis.stubs(:zrangebyscore).returns(nil)
      subject.find_printer("192.168.1.1").must_equal []
    end

    describe "on the local network" do
      it "searches for printers connected from a local subnet IP" do
        redis.expects(:keys).with("ip:192.168.*").returns(["printer:ip:192.168.2.123"])
        redis.expects(:keys).with("ip:10.*").returns([])
        subject.find_printer("127.0.0.1")
      end

      it "returns nil if no printers have ever connected" do
        redis.stubs(:keys).with("ip:192.168.*").returns([])
        redis.stubs(:keys).with("ip:10.*").returns([])
        subject.find_printer("127.0.0.1").must_equal []
      end
    end
  end
end
