require "test_helper"
require "remote_printer"

describe RemotePrinter do
  describe "updating" do
    it "stores the printer data" do
      Resque.redis.expects(:hset).with("printer/1", "type", "printer-type")
      RemotePrinter.update(id: "1", type: "printer-type")
    end

    it "stores the remote IP for a short time" do
      Resque.redis.expects(:set).with("printer/ip/192.168.1.1", "printer-id")
      Resque.redis.expects(:expire).with("printer/ip/192.168.1.1", 60)
      RemotePrinter.update(id: "printer-id", ip: "192.168.1.1")
    end
  end

  describe "retrieving" do
    it "returns the data for the stored printer" do
      Resque.redis.stubs(:hget).with("printer/1", "type").returns("printer-type")
      RemotePrinter.find("1").type.must_equal "printer-type"
    end
  end

  describe "finding by ip" do
    it "returns the printer instance which most recently checked in from that IP" do
      Resque.redis.expects(:get).with("printer/ip/192.168.1.1").returns("printer-id")
      RemotePrinter.expects(:find).with("printer-id")
      RemotePrinter.find_by_ip("192.168.1.1")
    end

    it "returns nil if no matching IP was found" do
      Resque.redis.expects(:get).with("printer/ip/192.168.1.1").returns(nil)
      RemotePrinter.find_by_ip("192.168.1.1").must_equal nil
    end
  end
end